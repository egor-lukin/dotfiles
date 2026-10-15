;; -*- lexical-binding: t; -*-
;;; init-core.el --- Paths, identity, encryption, file hygiene

;;; Code:

;;;; Пути и личные данные

(defvar workspace-dir (expand-file-name "~/dotfiles/")
  "Корень репозитория dotfiles.  Имя сохранено из doom.d/config.el,
на него опираются пакеты в dotfiles/lisp/.")

(defvar projects-dir (expand-file-name "~/dev/")
  "Каталог с рабочими проектами.")

(defvar org-dir (expand-file-name "~/org/")
  "Корень org-файлов.")

(setq user-full-name "Egor Lukin"
      user-mail-address "mail@egorlukin.me")

(defun termux-p ()
  "Return the Termux version string when running under Termux, else nil."
  (getenv "TERMUX_VERSION"))

(use-package no-littering
  :demand t
  :config
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (startup-redirect-eln-cache
   (no-littering-expand-var-file-name "eln-cache/")))


(require 'epa-file)

;; auto-encryption-mode включён по умолчанию с Emacs 29; повторный
;; epa-file-enable только печатает предупреждение при каждом старте.
(unless (bound-and-true-p auto-encryption-mode)
  (auto-encryption-mode 1))

(setq epa-file-encrypt-to user-mail-address
      epg-pinentry-mode 'loopback)


(setq auto-save-visited-interval 5
      auto-save-visited-predicate (lambda () (derived-mode-p 'org-mode)))
(auto-save-visited-mode 1)

(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

(winner-mode 1)

(save-place-mode 1)
(setq create-lockfiles nil)

(provide 'init-core)
