;; -*- lexical-binding: t; -*-
;;; Tests for el-docker.el.  Run with:
;;;   emacs -Q -batch -L lib -l tests/el-docker-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'el-docker)

(defconst el-docker-test--ps-output
  "web|2026-10-01 11:22:33 +0300 MSK|a1b2c3d4e5f6
db|2026-09-30 09:00:00 +0300 MSK|f6e5d4c3b2a1
"
  "Verbatim shape of `docker ps --format {{.Names}}|{{.CreatedAt}}|{{.ID}}'.")

(ert-deftest el-docker-test-parses-two-containers ()
  (should (equal 2 (length (el-docker-parse-ps el-docker-test--ps-output)))))

(ert-deftest el-docker-test-label-shows-name-created-and-id ()
  (should (equal "web (2026-10-01 11:22:33 +0300 MSK) [a1b2c3d4e5f6]"
                 (car (nth 0 (el-docker-parse-ps el-docker-test--ps-output))))))

(ert-deftest el-docker-test-keeps-name-and-id ()
  (should (equal '("web" . "a1b2c3d4e5f6")
                 (cdr (nth 0 (el-docker-parse-ps el-docker-test--ps-output))))))

(ert-deftest el-docker-test-empty-output-is-nil ()
  (should (null (el-docker-parse-ps "")))
  (should (null (el-docker-parse-ps "\n"))))

(ert-deftest el-docker-test-skips-malformed-lines ()
  ;; Строка без идентификатора бесполезна для tramp — её надо отбросить,
  ;; а не предлагать как кандидата.
  (should (equal '("web")
                 (mapcar (lambda (c) (car (cdr c)))
                         (el-docker-parse-ps
                          "web|2026-10-01|a1b2c3d4e5f6\nbroken-line\n")))))
