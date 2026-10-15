;; -*- lexical-binding: t; -*-
;;; init-ui.el --- Theme, modeline, fonts, line numbers, zen

;;; Code:

(require 'init-core)
(require 'init-keys)


;;;; Тема и modeline

(use-package doom-themes
  :demand t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-monokai-pro :no-confirm)
  (doom-themes-org-config))

(use-package nerd-icons :demand t)

;; (use-package doom-modeline
;;   :demand t
;;   :config
;;   (setq doom-modeline-height 25
;;         doom-modeline-buffer-file-name-style 'relative-from-project)
;;   (doom-modeline-mode 1))


;;;; Шрифты
;; :size 50 в doom-font это пиксели; здесь десятые пункта.

(defvar font-height 170)

(defun apply-fonts ()
  "Apply the configured fonts to the default and variable-pitch faces."
  (set-face-attribute 'default nil
                      :family "monospace"
                      :height font-height
                      :weight 'semi-light)
  (set-face-attribute 'variable-pitch nil
                      :family "sans"
                      :height font-height))

(when (display-graphic-p)
  (apply-fonts))

;; В daemon/клиентском режиме фрейма при загрузке ещё нет.
(add-hook 'server-after-make-frame-hook #'apply-fonts)


;;;; Номера строк и общий вид

(setq display-line-numbers-type t)
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

(setq-default truncate-lines nil)
(setq use-short-answers t
      ring-bell-function #'ignore)
(column-number-mode 1)

;; (use-package rainbow-delimiters
;;  :hook (prog-mode . rainbow-delimiters-mode))


;;;; Zen

;; (use-package visual-fill-column
;;  :config
;;  (setq visual-fill-column-width 100
;;        visual-fill-column-center-text t))

;; (use-package writeroom-mode
;;  :config
;;  (setq writeroom-width 100))

;; (el-leader!
;;  "t z" '(writeroom-mode :which-key "zen"))


;;(el-leader!
;;  "o"   '(:ignore t :which-key "open")
;;  "o w" '(world-clock :which-key "world clock"))

(provide 'init-ui)
