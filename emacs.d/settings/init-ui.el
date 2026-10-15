;; -*- lexical-binding: t; -*-
(require 'init-core)
(require 'init-keys)

(use-package doom-themes
  :demand t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-monokai-pro :no-confirm)
  (doom-themes-org-config))

(use-package nerd-icons :demand t)

(defvar font-height 200)

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

(add-hook 'server-after-make-frame-hook #'apply-fonts)


(setq display-line-numbers-type t)
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

(setq-default truncate-lines nil)
(setq use-short-answers t
      ring-bell-function #'ignore)
(column-number-mode 1)


(global-set-key (kbd "C-=") #'text-scale-increase)
(global-set-key (kbd "C--") #'text-scale-decrease)


(provide 'init-ui)
