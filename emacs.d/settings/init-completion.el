;; -*- lexical-binding: t; -*-

(require 'init-keys)


(use-package vertico
  :demand t
  :config
  (setq vertico-cycle t
        vertico-count 15)
  (vertico-mode 1))

(use-package orderless
  :demand t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :demand t
  :config (marginalia-mode 1))

(use-package consult
  :demand t
  :config
  (setq consult-narrow-key "<"
        xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))

(savehist-mode 1)
(recentf-mode 1)
(setq recentf-max-saved-items 200
      enable-recursive-minibuffers t
      completion-ignore-case t
      read-file-name-completion-ignore-case t)


(use-package corfu
  :demand t
  :config
  (setq corfu-cycle t
        corfu-auto t
        corfu-auto-prefix 2
        corfu-auto-delay 0.2
        corfu-quit-no-match 'separator)
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))

(use-package cape
  :demand t
  :config
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(setq tab-always-indent 'complete)

(provide 'init-completion)
