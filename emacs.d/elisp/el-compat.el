;; -*- lexical-binding: t; -*-
;;; el-compat.el --- Shims for functions this Emacs build predates

;;; Commentary:
;; Эта сборка Emacs — 31.0.50 из development-ветки, то есть версия уже
;; сообщает "31", а часть функций, добавленных в 31, в ней ещё
;; отсутствует.  Пакет compat такие пробелы не закрывает: он гейтит по
;; номеру версии и считает, что 31 умеет всё, что вошло в 31.
;;
;; Поэтому шимы здесь объявляются только если функции действительно нет:
;; после обновления Emacs файл перестаёт что-либо определять сам собой.

;;; Code:

(defvar el-compat-shimmed nil
  "List of function symbols this file had to define.
Пустой список означает, что сборка Emacs ничего не требует.")

;; Вызывается vertico.el:599, corfu.el:422, corfu-popupinfo.el:367 при
;; каждом дополнении, то есть без шима не работает минибуфер целиком.
(unless (fboundp 'set-local)
  (defun set-local (variable value)
    "Make VARIABLE buffer local and set it to VALUE."
    (set (make-local-variable variable) value))
  (push 'set-local el-compat-shimmed))

(provide 'el-compat)
;;; el-compat.el ends here
