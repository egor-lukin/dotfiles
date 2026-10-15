;; -*- lexical-binding: t; -*-
;;; el-org.el --- Org mode, GTD, clocking, capture, drill

;;; Code:

(require 'el-core)
(require 'el-keys)
(require 'el-clock)


;;;; Файлы повестки
;; Review Focus 1: directory-files на отсутствующем каталоге сигналит
;; file-missing и обрывает загрузку модуля целиком.

(defvar el-org-projects-dir (expand-file-name "projects/" org-dir)
  "Directory whose org files make up the agenda.")

(defun el-org-agenda-files ()
  "Return the agenda files from `el-org-projects-dir'.
Return nil when the directory is missing, so a renamed or not-yet-cloned
org repository cannot break the configuration."
  (when (file-directory-p el-org-projects-dir)
    (directory-files el-org-projects-dir t "\\.org\\(\\.gpg\\)?\\'")))


;;;; Org

(use-package org
  :ensure nil
  :config
  (require 'org-habit)
  (setq org-directory org-dir
        org-agenda-files (el-org-agenda-files)
        org-log-into-drawer t
        org-log-done t
        org-use-fast-todo-selection t
        org-refile-targets '((org-agenda-files :maxlevel . 2))
        org-todo-keywords '((sequence "TODO" "IN-PROGRESS" "WAIT" "|" "DONE" "CLOSED"))
        org-habit-show-habits-only-for-today t
        org-habit-preceding-days 25
        org-habit-following-days 3
        org-attach-directory (expand-file-name "~/photos/attachments")
        org-agenda-prefix-format '((agenda . " %i %-5:c%?-5t% s"))
        org-agenda-overriding-columns-format
        "%100ITEM  %TODO %7EFFORT %PRIORITY     100%TAGS"))


;;;; Хронометраж

(setq org-clock-persist t
      org-clock-persist-query-resume nil)
(with-eval-after-load 'org
  (org-clock-persistence-insinuate))

(defvar el-org-polybar-idle-text "no active clocks!"
  "Text reported to polybar when no clock is running.")

(defun el-org-polybar-clock-line ()
  "Report the running clock as a single line for polybar."
  (interactive)
  (message
   "%s"
   (if (org-clocking-p)
       (el-clock-format-line
        org-clock-heading
        (floor (org-time-convert-to-integer (time-since org-clock-start-time)) 60))
     el-org-polybar-idle-text)))


;;;; Capture

(setq org-capture-templates
      '(("e" "English word" entry
         (file+headline "drill/english_words.org" "Words")
         "* %? :drill:\n[]\n")
        ("t" "Project Todo" entry
         (file+headline (lambda () (completing-read "File: " org-agenda-files))
                        "tasks")
         (file "templates/todo.org"))
        ("n" "new note (via denote)" plain
         (file denote-last-path)
         (function
          (lambda ()
            (let ((denote-use-directory
                   (read-directory-name "Subdirectory: " (denote-directory))))
              (denote-org-capture))))
         :no-save t
         :immediate-finish nil
         :kill-buffer t
         :jump-to-captured t)
        ("b" "temp daily note" entry
         (file+headline (lambda () (denote-journal-path-to-new-or-existing-entry))
                        "buffer")
         (file "templates/buffer.org"))))


;;;; Drill и помодоро

(use-package org-drill
  :vc (:url "https://gitlab.com/phillord/org-drill.git" :rev :newest)
  :commands (org-drill org-drill-resume)
  :config
  (setq org-drill-spaced-repetition-algorithm 'sm2))

(use-package org-pomodoro
  :commands (org-pomodoro))


;;;; Babel

(use-package ob-async
  :after org
  :demand t)

(use-package ob-http
  :vc (:url "https://github.com/zweifisch/ob-http.git" :rev :newest)
  :after org
  :demand t)


;;;; Биндинги

(el-leader!
  "x"     '(org-capture :which-key "capture")
  "n"     '(:ignore t :which-key "org")
  "n a"   '(org-agenda :which-key "agenda")
  "n t"   '(org-todo-list :which-key "todo list")
  "n c"   '(:ignore t :which-key "clock")
  "n c i" '(org-clock-in :which-key "clock in")
  "n c o" '(org-clock-out :which-key "clock out")
  "n c g" '(org-clock-goto :which-key "goto clock")
  "b c"   '(el-org-polybar-clock-line :which-key "polybar clock line"))

(provide 'el-org)
;;; el-org.el ends here
