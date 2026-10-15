;; -*- lexical-binding: t; -*-
;;; Tests for el-project.el.  Run with:
;;;   emacs -Q -batch -L lib -l tests/el-project-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'el-project)

;;;; Переход между реализацией и тестом

(ert-deftest el-project-test-elisp-impl-to-test ()
  (should (member "lib/el-clock-test.el"
                  (el-project-counterparts "lib/el-clock.el"))))

(ert-deftest el-project-test-elisp-test-to-impl ()
  (should (member "lib/el-clock.el"
                  (el-project-counterparts "lib/el-clock-test.el"))))

(ert-deftest el-project-test-ruby-swaps-lib-and-spec ()
  (should (member "spec/models/user_spec.rb"
                  (el-project-counterparts "lib/models/user.rb"))))

(ert-deftest el-project-test-ruby-spec-back-to-lib ()
  (should (member "lib/models/user.rb"
                  (el-project-counterparts "spec/models/user_spec.rb"))))

(ert-deftest el-project-test-python-impl-to-test ()
  (should (member "tests/test_parser.py"
                  (el-project-counterparts "src/parser.py"))))

(ert-deftest el-project-test-python-test-to-impl ()
  (should (member "src/parser.py"
                  (el-project-counterparts "tests/test_parser.py"))))

(ert-deftest el-project-test-typescript-dot-test ()
  (should (member "app/api.test.ts"
                  (el-project-counterparts "app/api.ts")))
  (should (member "app/api.ts"
                  (el-project-counterparts "app/api.test.ts"))))

(ert-deftest el-project-test-same-directory-candidate-present ()
  ;; Не во всех проектах тесты лежат в отдельном каталоге.
  (should (member "lib/models/user_spec.rb"
                  (el-project-counterparts "lib/models/user.rb"))))

(ert-deftest el-project-test-unknown-extension-is-nil ()
  (should (null (el-project-counterparts "README.org")))
  (should (null (el-project-counterparts "Makefile"))))

;;;; Строка точки останова

(ert-deftest el-project-test-break-string ()
  (should (equal "break app/models/user.rb:42"
                 (el-project-break-string "app/models/user.rb" 42))))

(ert-deftest el-project-test-elisp-prefers-tests-dir ()
  ;; Этот репозиторий сам является контрпримером: реализации в lib/,
  ;; тесты в tests/.  Без переноса каталога SPC p t открыл бы
  ;; несуществующий lib/el-clock-test.el вместо tests/el-clock-test.el.
  (should (equal "tests/el-clock-test.el"
                 (car (el-project-counterparts "lib/el-clock.el"))))
  (should (equal "lib/el-clock.el"
                 (car (el-project-counterparts "tests/el-clock-test.el")))))
