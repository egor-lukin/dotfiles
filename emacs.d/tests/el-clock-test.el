;; -*- lexical-binding: t; -*-
;;; Tests for el-clock.el.  Run with:
;;;   emacs -Q -batch -L lib -l tests/el-clock-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'el-clock)

;;;; hms-to-minutes

(ert-deftest el-clock-test-minutes-from-hours-and-minutes ()
  (should (equal 90 (hms-to-minutes "1:30"))))

(ert-deftest el-clock-test-minutes-zero-hours ()
  (should (equal 45 (hms-to-minutes "0:45"))))

(ert-deftest el-clock-test-minutes-ignores-seconds ()
  (should (equal 90 (hms-to-minutes "1:30:15"))))

(ert-deftest el-clock-test-minutes-bare-number-is-minutes ()
  ;; Review Focus 2: в org-таблице ячейка может быть просто числом.
  ;; Исходная реализация падала здесь на (string-to-number nil).
  (should (equal 90 (hms-to-minutes "90"))))

(ert-deftest el-clock-test-minutes-blank-is-zero ()
  (should (equal 0 (hms-to-minutes "")))
  (should (equal 0 (hms-to-minutes "   ")))
  (should (equal 0 (hms-to-minutes nil))))

(ert-deftest el-clock-test-minutes-garbage-is-zero ()
  ;; Review Focus 2: мусор не должен обрывать пересчёт всей таблицы.
  (should (equal 0 (hms-to-minutes "n/a"))))

;;;; hms-to-pomodoros

(ert-deftest el-clock-test-pomodoros-truncate-toward-zero ()
  (should (equal 3 (hms-to-pomodoros "1:30")))
  (should (equal 0 (hms-to-pomodoros "0:24")))
  (should (equal 1 (hms-to-pomodoros "0:25"))))

(ert-deftest el-clock-test-pomodoros-strips-bold-markers ()
  (should (equal 3 (hms-to-pomodoros "*1:30*"))))

(ert-deftest el-clock-test-pomodoros-blank-is-zero ()
  (should (equal 0 (hms-to-pomodoros "")))
  (should (equal 0 (hms-to-pomodoros nil))))

;;;; Строка для polybar

(ert-deftest el-clock-test-format-line ()
  (should (equal "Write plan (12 min)"
                 (el-clock-format-line "Write plan" 12))))

(ert-deftest el-clock-test-pomodoros-strips-padded-bold-markers ()
  ;; Жирные длительности реально встречаются в ~/org/tasks (например
  ;; |      *0:00* |).  Если поле придёт с окружающими пробелами, префикс
  ;; "*" перестаёт совпадать и значение молча превращается в 0.
  (should (equal 3 (hms-to-pomodoros " *1:30* ")))
  (should (equal 90 (hms-to-minutes "  1:30  "))))
