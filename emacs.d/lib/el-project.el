;; -*- lexical-binding: t; -*-
;;; el-project.el --- Implementation/test navigation on top of project.el

;;; Commentary:
;; Замена projectile-toggle-between-implementation-and-test.  Логика
;; сопоставления путей чистая и покрыта тестами; команда поверх неё
;; обращается к project.el.

;;; Code:

(require 'subr-x)

(defconst el-project-test-rules
  '(("el"  :suffix "-test" :impl-dirs ("lib") :test-dirs ("tests"))
    ("rb"  :suffix "_spec" :impl-dirs ("lib" "app") :test-dirs ("spec"))
    ("py"  :prefix "test_" :impl-dirs ("src") :test-dirs ("tests"))
    ("ts"  :suffix ".test")
    ("tsx" :suffix ".test")
    ("js"  :suffix ".test")
    ("jsx" :suffix ".test"))
  "Rules mapping implementation files to their test counterparts.
Each entry is (EXTENSION . PLIST) where PLIST may contain:
  :suffix     appended to the basename of the test file
  :prefix     prepended to the basename of the test file
  :impl-dirs  leading path segments used by implementation files
  :test-dirs  leading path segments used by test files")

(defun el-project--swap-leading-dir (path from-dirs to-dirs)
  "Return PATH with a leading segment from FROM-DIRS replaced by TO-DIRS' first.
PATH is returned unchanged when either list is empty or no segment matches."
  (if (and from-dirs to-dirs)
      (let* ((segments (split-string path "/"))
             (head (car segments)))
        (if (member head from-dirs)
            (string-join (cons (car to-dirs) (cdr segments)) "/")
          path))
    path))

(defun el-project--test-name-p (base rule)
  "Return non-nil when BASE already looks like a test name under RULE."
  (let ((suffix (plist-get rule :suffix))
        (prefix (plist-get rule :prefix)))
    (or (and suffix (string-suffix-p suffix base))
        (and prefix (string-prefix-p prefix base)))))

(defun el-project-counterparts (path)
  "Return candidate counterpart paths for PATH, relative to a project root.
When PATH looks like a test the candidates are implementation files, and
vice versa.  Candidates are ordered by preference and are not checked for
existence.  Return nil when no rule covers PATH's extension."
  (let* ((ext (file-name-extension path))
         (rule (cdr (assoc ext el-project-test-rules))))
    (when rule
      (let* ((dir (or (file-name-directory path) ""))
             (base (file-name-base path))
             (suffix (plist-get rule :suffix))
             (prefix (plist-get rule :prefix))
             (impl-dirs (plist-get rule :impl-dirs))
             (test-dirs (plist-get rule :test-dirs))
             (testp (el-project--test-name-p base rule))
             (new-base
              (if testp
                  (cond (suffix (string-remove-suffix suffix base))
                        (prefix (string-remove-prefix prefix base)))
                (cond (suffix (concat base suffix))
                      (prefix (concat prefix base)))))
             (same-dir (concat dir new-base "." ext))
             (swapped (el-project--swap-leading-dir
                       same-dir
                       (if testp test-dirs impl-dirs)
                       (if testp impl-dirs test-dirs))))
        (delete-dups (list swapped same-dir))))))

(defun el-project-break-string (relative-path line)
  "Format a debugger break location for RELATIVE-PATH at LINE."
  (format "break %s:%d" relative-path line))

(provide 'el-project)
;;; el-project.el ends here
