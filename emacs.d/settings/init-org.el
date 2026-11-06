;; -*- lexical-binding: t; -*-

(require 'init-core)
(require 'init-keys)

(defun current-journal-entry-path ()
  "Return the filepath for the current day's journal entry.
Format: ~/org/journal/DD-MM-YYYY.org.gpg"
  (expand-file-name
   (format-time-string "journal/%Y-%m-%d.org.gpg")
   "~/org/"))

(defun create-or-open-current-journal-entry ()
  "Open today's journal entry, creating it if necessary."
  (interactive)
  (let ((path (current-journal-entry-path)))
    (unless (file-exists-p path)
      (write-region "" nil path))
    (find-file path)))

(defun my/org-clock-show-active ()
  "Report the running clock as a single line."
  (interactive)
  (message
   "%s"
   (if (org-clocking-p)
       (format "%s (%d min)"
        org-clock-heading
        (floor (org-time-convert-to-integer (time-since org-clock-start-time)) 60))
     "no active clocks!")))

(use-package org
  :ensure nil
  :config
  (require 'org-habit)
  (setq org-directory org-dir
        org-agenda-files '("projects/gtd.org" "projects/events.org" "projects/backlog.org" "projects/routines.org")
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

(setq org-capture-templates
      '(("e" "English word" entry
         (file+headline "drill/english_words.org" "Words")
         "* %? :drill:\n[]\n")
        ("t" "Project Todo" entry
         (file+headline "projects/gtd.org" "inbox")
         (file "templates/todo.org"))
        ("b" "temp daily note" entry
         (file+headline (lambda () (current-journal-entry-path))
                        "buffer")
         (file "templates/buffer.org"))))

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (shell . t)
   (python . t)))

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

(use-package denote
  :hook (dired-mode . denote-dired-mode)
  :config
  (setq denote-directory (expand-file-name org-dir)
        denote-prompts '(title keywords subdirectory))
  (denote-rename-buffer-mode 1))

(setq org-clock-clocked-in-display "both")

(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)
(global-set-key (kbd "C-c d j") #'create-or-open-current-journal-entry)
(global-set-key (kbd "C-c d b") #'denote-backlinks)
(global-set-key (kbd "C-c d f") #'denote-open-or-create)
(global-set-key (kbd "C-c d l") #'denote-link)
(global-set-key (kbd "C-c d i") #'denote-link-after-creating)

(global-set-key (kbd "C-c o c") #'my/org-clock-show-active)

(provide 'init-org)
