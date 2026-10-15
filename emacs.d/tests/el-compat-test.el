;; -*- lexical-binding: t; -*-
;;; Tests for el-compat.el.  Run with:
;;;   emacs -Q -batch -L lib -l tests/el-compat-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'el-compat)

(defvar el-compat-test--var 'global
  "Variable used to check that `set-local' does not touch the global value.")

(ert-deftest el-compat-test-set-local-is-available ()
  ;; vertico.el:599, corfu.el:422 и corfu-popupinfo.el:367 вызывают
  ;; set-local на каждом дополнении.  В сборках Emacs 31, сделанных до
  ;; появления этой функции, compat её не подставляет: он версионно
  ;; гейтит и считает, что 31 уже всё умеет.  Без шима ломается любое
  ;; дополнение в минибуфере.
  (should (fboundp 'set-local)))

(ert-deftest el-compat-test-set-local-sets-buffer-local-value ()
  (with-temp-buffer
    (set-local 'el-compat-test--var 'local)
    (should (local-variable-p 'el-compat-test--var))
    (should (eq 'local el-compat-test--var)))
  (should (eq 'global el-compat-test--var)))

(ert-deftest el-compat-test-set-local-returns-the-value ()
  (with-temp-buffer
    (should (eq 'v (set-local 'el-compat-test--var 'v)))))
