;; -*- lexical-binding: t; -*-
;;; Tests for el-boot.el.  Run with:
;;;   emacs -Q -batch -L lib -l tests/el-boot-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'el-boot)

(defmacro el-boot-test--with-clean-state (&rest body)
  "Run BODY with `el-failed-modules' reset to nil."
  (declare (indent 0))
  `(let ((el-failed-modules nil))
     ,@body))

(ert-deftest el-boot-test-returns-feature-on-success ()
  (el-boot-test--with-clean-state
    (should (eq 'cl-lib (el-require-module 'cl-lib)))
    (should (null el-failed-modules))))

(ert-deftest el-boot-test-returns-nil-on-failure ()
  (el-boot-test--with-clean-state
    (should (null (el-require-module 'el-boot-no-such-module)))))

(ert-deftest el-boot-test-records-failure-with-message ()
  (el-boot-test--with-clean-state
    (el-require-module 'el-boot-no-such-module)
    (should (equal '(el-boot-no-such-module)
                   (mapcar #'car el-failed-modules)))
    (should (stringp (cdr (car el-failed-modules))))))

(ert-deftest el-boot-test-continues-after-failure ()
  (el-boot-test--with-clean-state
    (should (equal '(cl-lib seq)
                   (el-require-modules 'el-boot-no-such-module 'cl-lib 'seq)))
    (should (equal '(el-boot-no-such-module)
                   (mapcar #'car el-failed-modules)))))

(ert-deftest el-boot-test-records-each-module-once ()
  ;; Review Focus 3: повторный require сбойного модуля не плодит дубли.
  (el-boot-test--with-clean-state
    (el-require-module 'el-boot-no-such-module)
    (el-require-module 'el-boot-no-such-module)
    (should (equal '(el-boot-no-such-module)
                   (mapcar #'car el-failed-modules)))))

(ert-deftest el-boot-test-successful-reload-is-idempotent ()
  ;; Review Focus 3: повторный require загруженного модуля ничего не меняет.
  (el-boot-test--with-clean-state
    (el-require-module 'cl-lib)
    (el-require-module 'cl-lib)
    (should (null el-failed-modules))))
