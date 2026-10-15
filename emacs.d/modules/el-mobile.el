;; -*- lexical-binding: t; -*-
;;; el-mobile.el --- Termux-only settings

;;; Commentary:
;; Грузится последним, поэтому может переопределять настройки любого
;; модуля выше.  org-mobile-mode живёт в dotfiles/lisp и нужен только здесь.

;;; Code:

(require 'el-core)
(require 'el-boot)

(add-to-list 'load-path
             (expand-file-name "lisp/org-mobile-mode" workspace-dir))
(el-require-module 'org-mobile-mode)

(when (featurep 'org-mobile-mode)
  (add-hook 'org-mode-hook #'org-mobile-mode))

;; Узкий экран: повестка без префиксов, без номеров строк.
(setq org-agenda-prefix-format '((agenda . " "))
      display-line-numbers-type nil)

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (remove-hook hook #'display-line-numbers-mode))

(provide 'el-mobile)
;;; el-mobile.el ends here
