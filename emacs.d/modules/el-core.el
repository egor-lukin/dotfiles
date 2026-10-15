;; -*- lexical-binding: t; -*-
;;; el-core.el --- Paths, identity, encryption, file hygiene

;;; Code:

(require 'el-boot)


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

(defun el-termux-p ()
  "Return the Termux version string when running under Termux, else nil."
  (getenv "TERMUX_VERSION"))


;;;; Рантайм-файлы не в репозиторий

(use-package no-littering
  :demand t
  :config
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (startup-redirect-eln-cache
   (no-littering-expand-var-file-name "eln-cache/")))


;;;; Шифрование

(require 'epa-file)
(epa-file-enable)
(setq epa-file-encrypt-to user-mail-address
      epg-pinentry-mode 'loopback)


;;;; Файловая гигиена

;; Автосохранение только org-буферов, раз в 5 секунд.
(setq auto-save-visited-interval 5
      auto-save-visited-predicate (lambda () (derived-mode-p 'org-mode)))
(auto-save-visited-mode 1)

(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

(winner-mode 1)

(save-place-mode 1)
(setq create-lockfiles nil)

(provide 'el-core)
;;; el-core.el ends here
