;;; ob-search.el --- Web search as an Org Babel language -*- lexical-binding: t; -*-

;; Author: Egor Lukin
;; Keywords: outlines, tools, hypermedia
;; Package-Requires: ((emacs "27.1"))

;;; Commentary:

;; Executes a web search from an Org source block and inserts the results
;; as an Org table of links and short descriptions.
;;
;;     #+begin_src search :engine duckduckgo :count 5
;;     golang concurrency
;;     #+end_src
;;
;;     #+RESULTS:
;;     | Title                          | Description               |
;;     |--------------------------------+---------------------------|
;;     | [[https://go.dev/blog/pipelines][Go Concurrency Patterns]] | Go's primitives make ...  |
;;
;; The block body is the query; blank lines and indentation are ignored and
;; multiple lines are joined, so a long query can be wrapped.
;;
;; Header arguments:
;;
;;   :engine  backend to query, a key of `ob-search-backends'
;;            (default `ob-search-default-engine')
;;   :count   how many results to ask for, one request per block
;;            (default `ob-search-default-count')
;;   :async   run in a child Emacs and fill in the results when they
;;            arrive -- requires the `ob-async' package
;;
;; Backends are pluggable.  `ob-search-backends' maps an engine name to a
;; function of (QUERY COUNT) that returns a list of plists, each with
;; :title, :url and :description.  Nothing else in this file knows how a
;; backend talks to the network, so adding one is a defun plus an entry.
;;
;; The bundled `duckduckgo' backend shells out to the ddgr command line
;; client (https://github.com/jarun/ddgr) and reads its --json output.

;;; Code:

(require 'ob)
(require 'json)
(require 'subr-x)

(defgroup ob-search nil
  "Web search as an Org Babel language."
  :group 'org-babel
  :prefix "ob-search-")

(defcustom ob-search-ddgr-executable "ddgr"
  "Name of or path to the ddgr command line DuckDuckGo client."
  :type 'string
  :group 'ob-search)

(defcustom ob-search-default-count 10
  "How many results to request when a block gives no :count."
  :type 'integer
  :group 'ob-search)

(defcustom ob-search-description-max-length 160
  "Truncate result descriptions to this many characters.
Keeps the results table narrow enough to read."
  :type 'integer
  :group 'ob-search)

(defcustom ob-search-backends
  '((duckduckgo . ob-search--fetch-ddgr))
  "Alist mapping an engine name to the function that queries it.

The key is a symbol, usable as the :engine header argument.  The value
is called with (QUERY COUNT) and must return a list of plists, each
with :title, :url and :description.  It should signal a `user-error'
when the search cannot be performed."
  :type '(alist :key-type symbol :value-type function)
  :group 'ob-search)

(defcustom ob-search-default-engine 'duckduckgo
  "Engine to query when a block gives no :engine."
  :type 'symbol
  :group 'ob-search)

(defvar org-babel-default-header-args:search
  '((:results . "table replace"))
  "Default header arguments for search blocks.")

;;;; Input

(defun ob-search--query (body)
  "Return the search query in BODY: its lines trimmed and joined."
  (let ((query (string-join
                (seq-remove #'string-empty-p
                            (mapcar #'string-trim (split-string body "\n")))
                " ")))
    (when (string-empty-p query)
      (user-error "ob-search: the block body is empty, nothing to search for"))
    query))

(defun ob-search--count (value)
  "Return VALUE, a number or a numeric string, as a positive integer."
  (let ((count (if (stringp value) (string-to-number value) value)))
    (unless (and (integerp count) (> count 0))
      (user-error "ob-search: :count must be a positive integer, got %S" value))
    count))

(defun ob-search--backend (engine)
  "Return the fetch function for ENGINE, a symbol or string."
  (let ((engine (if (stringp engine) (intern engine) engine)))
    (or (alist-get engine ob-search-backends)
        (user-error "ob-search: unknown :engine `%s' (known engines: %s)"
                    engine
                    (string-join (mapcar (lambda (b) (symbol-name (car b)))
                                         ob-search-backends)
                                 ", ")))))

;;;; Output

(defun ob-search--cell (text)
  "Return TEXT as a single safe Org table cell.

Collapses whitespace, escapes the | that would end the cell early, and
neutralizes square brackets: Org swallows a link description ending in
\"]\", and result titles do contain brackets."
  (replace-regexp-in-string
   "[][|]"
   (lambda (m) (cond ((equal m "[") "{") ((equal m "]") "}") (t "\\\\vert{}")))
   (string-join (split-string (or text "") nil t) " ")))

(defun ob-search--truncate (text)
  "Truncate TEXT to `ob-search-description-max-length' characters."
  (if (> (length text) ob-search-description-max-length)
      (concat (substring text 0 ob-search-description-max-length) "…")
    text))

(defun ob-search--to-table (results)
  "Format RESULTS, a list of result plists, as an Org table.
Returns nil when RESULTS is empty, so that a fruitless search leaves no
results block behind."
  (when results
    (append
     '(("Title" "Description") hline)
     (mapcar
      (lambda (result)
        (list (format "[[%s][%s]]"
                      (plist-get result :url)
                      (ob-search--cell (plist-get result :title)))
              (ob-search--cell
               (ob-search--truncate
                (string-join (split-string (or (plist-get result :description) "")
                                           nil t)
                             " ")))))
      results))))

;;;; DuckDuckGo backend (ddgr)

(defun ob-search--ddgr-args (query count)
  "Return the ddgr argument list for QUERY and COUNT results."
  (list "--json" "--noprompt" "--num" (number-to-string count) query))

(defun ob-search--parse-ddgr (output)
  "Parse ddgr --json OUTPUT into a list of result plists."
  (mapcar
   (lambda (entry)
     (list :title (alist-get 'title entry)
           :url (alist-get 'url entry)
           :description (or (alist-get 'abstract entry) "")))
   (json-parse-string output :object-type 'alist :array-type 'list)))

(defun ob-search--fetch-ddgr (query count)
  "Search DuckDuckGo for QUERY via ddgr, returning at most COUNT results."
  (unless (executable-find ob-search-ddgr-executable)
    (user-error "ob-search: cannot find `%s' in `exec-path'; install ddgr or set `ob-search-ddgr-executable'"
                ob-search-ddgr-executable))
  (with-temp-buffer
    (let ((status (apply #'call-process ob-search-ddgr-executable nil t nil
                         (ob-search--ddgr-args query count))))
      (unless (eq status 0)
        (user-error "ob-search: %s exited with %S: %s"
                    ob-search-ddgr-executable status
                    (string-trim (buffer-string))))
      (ob-search--parse-ddgr (buffer-string)))))

;;;; Babel entry point

(defun org-babel-execute:search (body params)
  "Execute the search in BODY with PARAMS.  Called by Org Babel."
  (let ((fetch (ob-search--backend
                (or (cdr (assq :engine params)) ob-search-default-engine)))
        (count (ob-search--count
                (or (cdr (assq :count params)) ob-search-default-count)))
        (query (ob-search--query body)))
    (ob-search--to-table (funcall fetch query count))))

(defun org-babel-prep-session:search (_session _params)
  "Signal that search blocks have no sessions."
  (user-error "ob-search: search blocks do not support sessions"))

;; Editing a search block with C-c ' needs some major mode; the body is
;; plain text.
(add-to-list 'org-src-lang-modes '("search" . fundamental))

;; A child Emacs started by ob-async for an :async block inherits neither
;; this file nor the directory it lives in.
(defconst ob-search--directory
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory this file was loaded from.")

(defun ob-search--async-setup-function ()
  "Return the function that makes this file loadable in an ob-async child.

ob-async prints the hook and runs it in a bare child Emacs that has never
loaded this file, so the directory is inlined as a literal rather than
captured as a free variable -- a closure over it dies there with
`void-variable'."
  `(lambda ()
     (add-to-list 'load-path ,ob-search--directory)
     (require 'ob-search)))

(with-eval-after-load 'ob-async
  (add-hook 'ob-async-pre-execute-src-block-hook
            (ob-search--async-setup-function)))

(provide 'ob-search)

;;; ob-search.el ends here
