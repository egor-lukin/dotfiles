;; -*- lexical-binding: t; -*-
;;; el-mobile.el --- Termux-only settings

;;; Commentary:
;; Грузится последним, поэтому может переопределять настройки любого
;; модуля выше.  org-mobile-mode живёт в dotfiles/lisp и нужен только здесь.

;;; Code:

(require 'init-core)

(add-to-list 'load-path
             (expand-file-name "lisp/org-mobile-mode" workspace-dir))
(require 'org-mobile)

(when (featurep 'org-mobile-mode)
  (add-hook 'org-mode-hook #'org-mobile-mode))

(setq org-agenda-prefix-format '((agenda . " "))
      display-line-numbers-type nil)

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (remove-hook hook #'display-line-numbers-mode))

(provide 'init-mobile)
