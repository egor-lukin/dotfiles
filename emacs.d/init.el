;; -*- lexical-binding: t; -*-
;;; init.el --- Entry point: bootstrap and load order only

;;; Commentary:
;; Здесь нет настройки пакетов — только подключение архивов, use-package,
;; load-path и порядок загрузки модулей.  Порядок не произвольный:
;; el-core определяет пути, от которых зависят остальные модули;
;; el-keys создаёт el-leader!, без которого модули не могут вешать биндинги;
;; платформенный модуль идёт последним, чтобы мог переопределять всё выше.

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

(dolist (dir '("lib" "modules"))
  (add-to-list 'load-path (expand-file-name dir user-emacs-directory)))

(require 'el-boot)

;; Шимы для функций, которых нет в этой сборке Emacs: нужны до загрузки
;; любого модуля, потому что их вызывают vertico и corfu.
(require 'el-compat)

(el-require-modules
 'el-core
 'el-keys
 'el-completion
 'el-ui
 'el-org
 'el-denote
 'el-ai
 'el-tools
 'el-apps
 'el-local)

;; Если el-core не загрузился, el-termux-p не определена — развилка всё
;; равно должна выбрать модуль, а не уронить init.el.
(el-require-module
 (if (and (fboundp 'el-termux-p) (el-termux-p)) 'el-mobile 'el-desktop))

(when el-failed-modules
  (message "[el] %d module(s) failed: %S"
           (length el-failed-modules)
           (mapcar #'car el-failed-modules)))

;;; init.el ends here
