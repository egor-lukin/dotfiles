;; -*- lexical-binding: t; -*-

(require 'init-core)
(require 'init-keys)

(use-package org
  :ensure nil
  :config
  (require 'org-habit)
  (setq org-directory org-dir
        org-agenda-files '("projects/gtd.org" "projects/events.org" "projects/backlog.org")
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
  "t t"   '(org-pomodoro :which-key "org pomodoro")
  "m"     '(:ignore t :which-key "org")
  "m a"   '(org-agenda :which-key "agenda")
  "m t"   '(org-todo :which-key "org todo")
  "m c"   '(:ignore t :which-key "clock")
  "m c i" '(org-clock-in :which-key "clock in")
  "m c o" '(org-clock-out :which-key "clock out")
  "m c g" '(org-clock-goto :which-key "goto clock")
  "m c c" '(my/org-clock-show-active :which-key "polybar clock line"))

(provide 'init-org)
