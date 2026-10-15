;; -*- lexical-binding: t; -*-

(require 'init-core)
(require 'init-keys)

(require 'subr-x)

(defconst el-clock-pomodoro-minutes 25
  "Length of one pomodoro in minutes.")

(defun hms-to-minutes (str)
  "Convert STR to a whole number of minutes.
STR may be \"H:MM\", \"H:MM:SS\" or a bare number of minutes, with or
without surrounding whitespace.  Blank, nil and unparsable input yield 0,
so a stray cell cannot break the recalculation of a whole org table."
  (cond
   ((or (null str) (string-blank-p str)) 0)
   ((string-match-p ":" str)
    (let* ((parts (split-string (string-trim str) ":"))
           (hours (string-to-number (or (nth 0 parts) "0")))
           (minutes (string-to-number (or (nth 1 parts) "0"))))
      (+ (* hours 60) minutes)))
   (t (truncate (string-to-number str)))))

(defun hms-to-pomodoros (str)
  "Convert STR to a whole number of pomodoros, truncating toward zero.
Surrounding org bold markers are stripped, so \"*1:30*\" and \"1:30\"
agree."
  (let ((str (and str (string-trim str))))
    (cond
     ((or (null str) (string-blank-p str)) 0)
     ((and (string-prefix-p "*" str) (string-suffix-p "*" str))
      (hms-to-pomodoros (substring str 1 -1)))
     (t (/ (hms-to-minutes str) el-clock-pomodoro-minutes)))))

(defun el-clock-format-line (task minutes)
  "Format TASK and MINUTES as a one-line clock summary."
  (format "%s (%d min)" task minutes))

(defvar my/org-projects-dir (expand-file-name "projects/" org-dir))

(defun my/org-agenda-files ()
  (when (file-directory-p my/org-projects-dir)
    (directory-files my/org-projects-dir t "\\.org\\(\\.gpg\\)?\\'")))

(use-package org
  :ensure nil
  :config
  (require 'org-habit)
  (setq org-directory org-dir
        org-agenda-files (my/org-agenda-files)
        org-log-into-drawer t
        org-log-done t
        org-use-fast-todo-selection t
        org-return-follows-link t
        org-mouse-1-follows-link t
        org-refile-targets '((org-agenda-files :maxlevel . 2))
        org-todo-keywords '((sequence "TODO" "IN-PROGRESS" "WAIT" "|" "DONE" "CLOSED"))
        org-habit-show-habits-only-for-today t
        org-habit-preceding-days 25
        org-habit-following-days 3
        org-attach-directory (expand-file-name "~/org/attachments")
        org-agenda-prefix-format '((agenda . " %i %-5:c%?-5t% s"))
        org-agenda-overriding-columns-format
        "%100ITEM  %TODO %7EFFORT %PRIORITY     100%TAGS"))

;; Evil's normal state shadows `org-mode-map', so RET has to be bound on the
;; `evil-org-mode' minor mode to reach `org-open-at-point'.
(with-eval-after-load 'evil-org
  (evil-define-key '(normal visual) 'evil-org-mode
    (kbd "RET") #'org-open-at-point))

(setq org-clock-persist t
      org-clock-persist-query-resume nil)
(with-eval-after-load 'org
  (org-clock-persistence-insinuate))

(defun my/org-clock-show-active ()
  "Report the running clock as a single line for polybar."
  (interactive)
  (message
   "%s"
   (if (org-clocking-p)
       (el-clock-format-line
        org-clock-heading
        (floor (org-time-convert-to-integer (time-since org-clock-start-time)) 60))
     "no active clocks!")))

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


(use-package org-drill
  :vc (:url "https://gitlab.com/phillord/org-drill.git" :rev :newest)
  :commands (org-drill org-drill-resume)
  :config
  (setq org-drill-spaced-repetition-algorithm 'sm2))

(use-package org-pomodoro
  :commands (org-pomodoro))


(use-package ob-async
  :after org
  :demand t)

(el-leader!
  "x"     '(org-capture :which-key "capture")
  "n"     '(:ignore t :which-key "org")
  "n a"   '(org-agenda :which-key "agenda")
  "n t"   '(org-todo-list :which-key "todo list")
  "n c"   '(:ignore t :which-key "clock")
  "n c i" '(org-clock-in :which-key "clock in")
  "n c o" '(org-clock-out :which-key "clock out")
  "n c g" '(org-clock-goto :which-key "goto clock")
  "n c c" '(my/org-clock-show-active :which-key "polybar clock line"))

(provide 'init-org)
