;; -*- lexical-binding: t; -*-
(require 'package)

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))

(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t
      use-package-always-defer nil
      use-package-expand-minimally t)

(dolist (dir '("elisp" "settings"))
  (add-to-list 'load-path (expand-file-name dir user-emacs-directory)))

(let ((default-directory (expand-file-name "elisp" user-emacs-directory)))
  (normal-top-level-add-subdirs-to-load-path))

(defvar el-compat-shimmed nil)
(unless (fboundp 'set-local)
  (defun set-local (variable value)
    "Make VARIABLE buffer local and set it to VALUE."
    (set (make-local-variable variable) value))
  (push 'set-local el-compat-shimmed))

(require 'denote-extras)
(require 'logbook-table)
(require 'open-meteo)
(require 'ob-search)

(require 'init-core)
(require 'init-keys)
(require 'init-completion)
(require 'init-ui)
(require 'init-org)
(require 'init-denote)
(require 'init-ai)
(require 'init-tools)
(require 'init-apps)

(if (termux-p)
  (require 'mobile)
  (require 'desktop))

