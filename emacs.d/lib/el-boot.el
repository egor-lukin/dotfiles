;; -*- lexical-binding: t; -*-
;;; el-boot.el --- Module loading with error isolation

;;; Commentary:
;; Загрузка модулей конфигурации так, чтобы сбой одного модуля не обрывал
;; загрузку остальных: ошибка записывается в `el-failed-modules' и
;; попадает в *Messages*, а Emacs поднимается до рабочего состояния.

;;; Code:

(defvar el-failed-modules nil
  "Alist of (MODULE . ERROR-MESSAGE) for modules that failed to load.
Каждый модуль присутствует в списке не более одного раза.")

(defun el-require-module (module)
  "Require MODULE, recording a failure instead of aborting the load.
Return MODULE on success and nil on failure."
  (condition-case err
      (progn (require module) module)
    (error
     (let ((message (error-message-string err)))
       (unless (assq module el-failed-modules)
         (push (cons module message) el-failed-modules))
       (message "[el] module %s failed to load: %s" module message))
     nil)))

(defun el-require-modules (&rest modules)
  "Require each of MODULES in order via `el-require-module'.
Return the list of modules that loaded successfully, in request order."
  (delq nil (mapcar #'el-require-module modules)))

(provide 'el-boot)
;;; el-boot.el ends here
