;; -*- lexical-binding: t; -*-
;;; el-local.el --- Local packages from dotfiles/lisp

;;; Commentary:
;; Пакеты остаются в dotfiles/lisp, путь к ним строится от workspace-dir.
;; org-mobile-mode здесь не грузится: он нужен только под Termux и
;; подключается модулем el-mobile.

;;; Code:

(require 'el-core)
(require 'el-boot)

(dolist (dir '("lisp/denote-extras"
               "lisp/logbook-table"
               "lisp/open-meteo"
               "lisp/org-babel-search"))
  (add-to-list 'load-path (expand-file-name dir workspace-dir)))

;; Сбой одного локального пакета не должен ронять остальные.
(el-require-modules 'denote-extras 'logbook-table 'open-meteo 'ob-search)

;; Выполняется после того, как ob-search и ob-http оказались в load-path.
(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((http . t)
     (search . t))))

(provide 'el-local)
;;; el-local.el ends here
