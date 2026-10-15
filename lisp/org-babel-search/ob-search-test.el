;; -*- lexical-binding: t; -*-
;;; Tests for ob-search.el.  Run with:
;;;   emacs -Q -batch -L . -l ob-search-test.el -f ert-run-tests-batch-and-exit
;;; Tests tagged :live shell out to the real ddgr and are excluded above.

(require 'ert)
(require 'org)
(require 'org-element)
(require 'ob-search)

;;;; Query extraction

(ert-deftest ob-search-test-query-trims-body ()
  (should (equal "golang concurrency"
                 (ob-search--query "\n  golang concurrency  \n"))))

(ert-deftest ob-search-test-query-joins-multiple-lines ()
  (should (equal "golang concurrency patterns"
                 (ob-search--query "golang concurrency\npatterns"))))

(ert-deftest ob-search-test-query-rejects-blank-body ()
  (should-error (ob-search--query "  \n  ") :type 'user-error))

;;;; ddgr JSON parsing

(defconst ob-search-test--ddgr-json "
[
  {
    \"abstract\": \"Go's concurrency primitives make it easy to construct pipelines.\",
    \"title\": \"Go Concurrency Patterns: Pipelines and cancellation\",
    \"url\": \"https://go.dev/blog/pipelines\"
  },
  {
    \"abstract\": \"This page links to resources for learning about concurrency in Go.\",
    \"title\": \"Go Wiki: LearnConcurrency\",
    \"url\": \"https://go.dev/wiki/LearnConcurrency\"
  }
]"
  "Verbatim shape of `ddgr --json' output, captured from ddgr 2.2.")

(ert-deftest ob-search-test-parses-ddgr-json-into-plists ()
  (should (equal '((:title "Go Concurrency Patterns: Pipelines and cancellation"
                    :url "https://go.dev/blog/pipelines"
                    :description "Go's concurrency primitives make it easy to construct pipelines.")
                   (:title "Go Wiki: LearnConcurrency"
                    :url "https://go.dev/wiki/LearnConcurrency"
                    :description "This page links to resources for learning about concurrency in Go."))
                 (ob-search--parse-ddgr ob-search-test--ddgr-json))))

(ert-deftest ob-search-test-parses-empty-ddgr-result ()
  (should (null (ob-search--parse-ddgr "[]"))))

(ert-deftest ob-search-test-parses-ddgr-entry-missing-abstract ()
  (should (equal '((:title "T" :url "https://e.com" :description ""))
                 (ob-search--parse-ddgr "[{\"title\":\"T\",\"url\":\"https://e.com\"}]"))))

;;;; Table formatting

(ert-deftest ob-search-test-formats-results-as-table-with-header ()
  (should (equal '(("Title" "Description")
                   hline
                   ("[[https://go.dev/blog/pipelines][Go Concurrency Patterns]]" "Primitives."))
                 (ob-search--to-table
                  '((:title "Go Concurrency Patterns"
                     :url "https://go.dev/blog/pipelines"
                     :description "Primitives."))))))

(ert-deftest ob-search-test-returns-nil-table-for-no-results ()
  (should (null (ob-search--to-table nil))))

(ert-deftest ob-search-test-truncates-long-descriptions ()
  (let ((ob-search-description-max-length 10))
    (should (equal "abcdefghij…"
                   (nth 1 (nth 2 (ob-search--to-table
                                  '((:title "T" :url "u"
                                     :description "abcdefghijklmnop")))))))))

(ert-deftest ob-search-test-leaves-short-descriptions-intact ()
  (let ((ob-search-description-max-length 10))
    (should (equal "abc"
                   (nth 1 (nth 2 (ob-search--to-table
                                  '((:title "T" :url "u" :description "abc")))))))))

(ert-deftest ob-search-test-escapes-pipes-in-cells ()
  ;; A bare | would break out of the org table cell.
  (should (equal '(("Title" "Description")
                   hline
                   ("[[u][a \\vert{} b]]" "c \\vert{} d"))
                 (ob-search--to-table
                  '((:title "a | b" :url "u" :description "c | d"))))))

(ert-deftest ob-search-test-collapses-newlines-in-cells ()
  (should (equal "one two"
                 (nth 1 (nth 2 (ob-search--to-table
                                '((:title "T" :url "u" :description "one\ntwo"))))))))

;;;; Backend dispatch

(ert-deftest ob-search-test-unknown-engine-errors-and-lists-known-ones ()
  (let ((ob-search-backends '((duckduckgo . ignore))))
    (let ((err (should-error (ob-search--backend "altavista") :type 'user-error)))
      (should (string-match-p "altavista" (cadr err)))
      (should (string-match-p "duckduckgo" (cadr err))))))

(ert-deftest ob-search-test-backend-accepts-symbol-or-string ()
  (let ((ob-search-backends '((duckduckgo . ignore))))
    (should (eq 'ignore (ob-search--backend "duckduckgo")))
    (should (eq 'ignore (ob-search--backend 'duckduckgo)))))

;;;; Count coercion

(ert-deftest ob-search-test-count-accepts-number-and-string ()
  (should (= 5 (ob-search--count 5)))
  (should (= 5 (ob-search--count "5"))))

(ert-deftest ob-search-test-count-rejects-non-positive ()
  (should-error (ob-search--count 0) :type 'user-error)
  (should-error (ob-search--count "nope") :type 'user-error))

;;;; Babel executor (backend stubbed -- no network)

(defvar ob-search-test--calls nil)

(defmacro ob-search-test--with-stub-backend (results &rest body)
  "Run BODY with the `test' engine returning RESULTS, recording its args."
  (declare (indent 1))
  `(let* ((ob-search-test--calls nil)
          (ob-search-backends
           (cons (cons 'test (lambda (query count)
                               (push (list query count) ob-search-test--calls)
                               ,results))
                 ob-search-backends)))
     ,@body))

(ert-deftest ob-search-test-executor-returns-table ()
  (ob-search-test--with-stub-backend
      '((:title "T" :url "https://e.com" :description "D"))
    (should (equal '(("Title" "Description")
                     hline
                     ("[[https://e.com][T]]" "D"))
                   (org-babel-execute:search
                    "a query" '((:engine . "test") (:count . 3)))))))

(ert-deftest ob-search-test-executor-passes-query-and-count-to-backend ()
  (ob-search-test--with-stub-backend nil
    (org-babel-execute:search "golang concurrency"
                              '((:engine . "test") (:count . 7)))
    (should (equal '(("golang concurrency" 7)) ob-search-test--calls))))

(ert-deftest ob-search-test-executor-defaults-engine-and-count ()
  (ob-search-test--with-stub-backend nil
    (let ((ob-search-default-engine 'test)
          (ob-search-default-count 4))
      (org-babel-execute:search "q" nil)
      (should (equal '(("q" 4)) ob-search-test--calls)))))

(ert-deftest ob-search-test-executor-returns-nil-when-no-results ()
  (ob-search-test--with-stub-backend nil
    (should (null (org-babel-execute:search "q" '((:engine . "test")))))))

;;;; ddgr invocation

(ert-deftest ob-search-test-ddgr-command-passes-count-and-query ()
  (should (equal '("--json" "--noprompt" "--num" "3" "golang concurrency")
                 (ob-search--ddgr-args "golang concurrency" 3))))

(ert-deftest ob-search-test-ddgr-missing-executable-errors ()
  (let ((ob-search-ddgr-executable "ddgr-does-not-exist"))
    (should-error (ob-search--fetch-ddgr "q" 1) :type 'user-error)))

(ert-deftest ob-search-test-ddgr-nonzero-exit-reports-output ()
  ;; `false' exits 1 and prints nothing; the error must still name the failure.
  (let ((ob-search-ddgr-executable "false"))
    (let ((err (should-error (ob-search--fetch-ddgr "q" 1) :type 'user-error)))
      (should (string-match-p "exited" (cadr err))))))

(ert-deftest ob-search-test-live-ddgr-returns-results ()
  :tags '(:live)
  (let ((results (ob-search--fetch-ddgr "golang concurrency" 3)))
    (should (= 3 (length results)))
    (should (string-prefix-p "http" (plist-get (car results) :url)))
    (should (plist-get (car results) :title))))

(provide 'ob-search-test)

;;;; Regression: bracket handling in link descriptions

;; Org parses balanced brackets inside a link description, but a
;; description ENDING in "]" is swallowed: [[u][Guide [v2]]] parses with
;; the description "Guide [v2".  Search result titles do contain brackets,
;; so cells neutralize them rather than relying on where they fall.

(ert-deftest ob-search-test-neutralizes-brackets-in-cells ()
  (should (equal "Guide {v2}" (ob-search--cell "Guide [v2]"))))

(ert-deftest ob-search-test-bracketed-title-round-trips-through-org ()
  (let ((cell (car (nth 2 (ob-search--to-table
                           '((:title "Guide [v2]" :url "https://e.com"
                              :description "d")))))))
    (with-temp-buffer
      (let ((org-inhibit-startup t))
        (org-mode))
      (insert cell)
      (goto-char (point-min))
      (let ((link (org-element-context)))
        (should (eq 'link (org-element-type link)))
        (should (equal "https://e.com" (org-element-property :raw-link link)))
        ;; The whole description survives -- nothing swallowed by a bracket.
        (should (equal "Guide {v2}"
                       (buffer-substring-no-properties
                        (org-element-property :contents-begin link)
                        (org-element-property :contents-end link))))))))

;;;; End-to-end through a real Org buffer

(ert-deftest ob-search-test-src-block-inserts-results-table ()
  (with-temp-buffer
    (let ((org-inhibit-startup t)
          (org-confirm-babel-evaluate nil))
      (org-mode)
      (insert "#+begin_src search :engine test :count 2\n"
              "golang concurrency\n"
              "#+end_src\n")
      (goto-char (point-min))
      (ob-search-test--with-stub-backend
          '((:title "Go Concurrency Patterns" :url "https://go.dev/blog/pipelines"
             :description "Pipelines."))
        (org-babel-execute-src-block)
        ;; Asserted inside the macro: it let-binds `ob-search-test--calls'.
        (should (equal '(("golang concurrency" 2)) ob-search-test--calls))
        (let ((text (buffer-string)))
        (should (string-match-p "^#\\+RESULTS:" text))
        (should (string-match-p "^| Title +| Description +|$" text))
        (should (string-match-p "|-" text))
        (should (string-match-p
                 "\\[\\[https://go\\.dev/blog/pipelines\\]\\[Go Concurrency Patterns\\]\\]"
                 text)))))))

(ert-deftest ob-search-test-live-src-block-searches-duckduckgo ()
  :tags '(:live)
  (with-temp-buffer
    (let ((org-inhibit-startup t)
          (org-confirm-babel-evaluate nil))
      (org-mode)
      (insert "#+begin_src search :count 3\norg mode babel\n#+end_src\n")
      (goto-char (point-min))
      (org-babel-execute-src-block)
      (let ((text (buffer-string)))
        (should (string-match-p "^| Title" text))
        (should (string-match-p "\\[\\[http" text))))))

;;;; ob-async child setup

;; ob-async serializes the hook function and runs it in a bare child Emacs
;; that has never loaded this file.  A closure over `ob-search--directory'
;; therefore dies there with a void-variable error; the path must be
;; inlined as a literal.

(ert-deftest ob-search-test-async-hook-inlines-directory-literally ()
  (let ((printed (prin1-to-string (ob-search--async-setup-function))))
    (should (string-match-p (regexp-quote ob-search--directory) printed))
    (should-not (string-match-p "ob-search--directory" printed))))

(ert-deftest ob-search-test-async-hook-survives-print-read-round-trip ()
  ;; Round-trip through print/read the way `async' does, then run it with
  ;; `load-path' reset, as the child has it.  This cannot unload ob-search
  ;; from the running Emacs, so it proves the hook is serializable and puts
  ;; the directory on `load-path'; that the child can then load the file is
  ;; what the :async path itself exercises.
  (let* ((fn (car (read-from-string
                   (prin1-to-string (ob-search--async-setup-function)))))
         (load-path (list)))
    (funcall fn)
    (should (member ob-search--directory load-path))))
