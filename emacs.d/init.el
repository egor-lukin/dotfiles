;; -*- lexical-binding: t; -*-
;;; init.el --- Entry point: bootstrap and load order only

;;; Code:

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

;; (require 'el-boot)

;; Шимы для функций, которых нет в этой сборке Emacs: нужны до загрузки
;; любого модуля, потому что их вызывают vertico и corfu.
(require 'el-compat)

(require 'init-core)
(require 'init-keys)
(require 'init-completion)
(require 'init-ui)
(require 'init-org)
(require 'init-denote)
(require 'init-ai)
(require 'init-tools)
(require 'init-apps)
(require 'init-local)


(if (termux-p)
  (require 'mobile)
  (require 'desktop))

;; (el-require-modules
;;  'core
;;  'keys
;;  'completion
;;  'ui
;;  'org
;;  'denote
;;  'ai
;;  'tools
;;  'apps
;;  'local)

;; (el-require-module
;;  (if (and (fboundp 'termux-p) (el-termux-p)) 'mobile 'desktop))

;; (when el-failed-modules
;;   (message "[el] %d module(s) failed: %S"
;;            (length el-failed-modules)
;;            (mapcar #'car el-failed-modules)))

;;; init.el ends here
