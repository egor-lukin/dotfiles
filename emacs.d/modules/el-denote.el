;; -*- lexical-binding: t; -*-
;;; el-denote.el --- Denote notes and journal

;;; Code:

(require 'el-core)
(require 'el-keys)

(use-package denote
  :hook (dired-mode . denote-dired-mode)
  :config
  (setq denote-directory (expand-file-name org-dir)
        denote-prompts '(title keywords subdirectory))
  (denote-rename-buffer-mode 1))

(use-package denote-journal
  :commands (denote-journal-new-entry
             denote-journal-new-or-existing-entry
             denote-journal-link-or-create-entry
             denote-journal-path-to-new-or-existing-entry)
  :hook (calendar-mode . denote-journal-calendar-mode)
  :config
  (setq denote-journal-directory (expand-file-name "journal" denote-directory)
        denote-journal-keyword "journal"
        denote-journal-title-format "%Y-%m-%d"))


;;;; Журнал в повестке
;; Review Focus 5: denote-journal-path-to-new-or-existing-entry создаёт
;; файл, поэтому вызывать его на загрузке конфига нельзя — каждый старт
;; Emacs плодил бы пустую запись.  Делаем это при открытии повестки.

(defun el-denote-journal-ensure-agenda-entry (&rest _)
  "Add today's journal entry to `org-agenda-files' if it is not there yet."
  (require 'denote-journal)
  (let ((path (denote-journal-path-to-new-or-existing-entry)))
    (when (and path (not (member path org-agenda-files)))
      (push path org-agenda-files))))

(advice-add 'org-agenda :before #'el-denote-journal-ensure-agenda-entry)


;;;; Навигация по дням
;; Определены в dotfiles/lisp/denote-extras, который грузит el-local.

(el-leader!
  "d"   '(:ignore t :which-key "denote")
  "d n" '(denote :which-key "denote")
  "d i" '(denote-link-after-creating :which-key "link after creating")
  "d j" '(denote-journal-new-or-existing-entry :which-key "journal entry")
  "d l" '(denote-link :which-key "link")
  "d b" '(denote-backlinks :which-key "backlinks")
  "d f" '(denote-open-or-create :which-key "open or create")
  "d [" '(my/denote-journal-open-previous-day :which-key "previous day")
  "d ]" '(my/denote-journal-open-next-day :which-key "next day"))

(provide 'el-denote)
;;; el-denote.el ends here
