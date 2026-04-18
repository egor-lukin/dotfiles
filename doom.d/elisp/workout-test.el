;;; workout-test.el --- Tests for workout review generator -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'subr-x)
(load-file (expand-file-name "workout.el" (file-name-directory (or load-file-name buffer-file-name))))

(defmacro workout-test/with-temp-env (&rest body)
  "Run BODY with isolated dailies/review paths."
  `(let* ((root (make-temp-file "workout-test-" t))
          (dailies (expand-file-name "dailies/" root))
          (review (expand-file-name "review.org" root)))
     (unwind-protect
         (let ((my/workout-dailies-path dailies)
               (my/workout-review-path review))
           (make-directory dailies t)
           ,@body)
       (delete-directory root t))))

(defun workout-test--write-daily (day body)
  "Write daily file for DAY string with BODY content."
  (let ((file (expand-file-name (concat day ".org") my/workout-dailies-path)))
    (with-temp-file file
      (insert body "\n"))
    file))

(defun workout-test--read-review ()
  "Read review file content as string, or empty when missing."
  (if (file-exists-p my/workout-review-path)
      (with-temp-buffer
        (insert-file-contents my/workout-review-path)
        (buffer-string))
    ""))

(defun workout-test--row-regexp (day notes-fragment)
  "Build regexp matching a review row for DAY and NOTES-FRAGMENT."
  (format "^|[[:space:]]*%s[[:space:]]*|[[:space:]]*.*%s.*|$"
          (regexp-quote day)
          (regexp-quote notes-fragment)))

(ert-deftest workout-test/extract-workout-any-level-case-insensitive-first-only ()
  (workout-test/with-temp-env
   (let ((file (workout-test--write-daily
                "2026-04-18"
                "* Plan\n** WORKOUT\nfirst note\n*** accessory\nalpha\n** Workout\nsecond note")))
     (should (equal (my/workout--extract-workout-subtree file)
                    "first note *** accessory alpha")))))

(ert-deftest workout-test/date-range-is-inclusive ()
  (workout-test/with-temp-env
   (workout-test--write-daily "2026-04-17" "* workout\nleft")
   (workout-test--write-daily "2026-04-18" "* workout\nright")
   (my/workout-review-from-date-range '(4 17 2026) '(4 18 2026))
   (let ((review (workout-test--read-review)))
     (should (string-match-p (workout-test--row-regexp "2026-04-17" "left") review))
     (should (string-match-p (workout-test--row-regexp "2026-04-18" "right") review)))))

(ert-deftest workout-test/today-command-uses-current-local-date ()
  (workout-test/with-temp-env
   (workout-test--write-daily "2026-04-18" "* workout\nnote today")
   (cl-letf (((symbol-function 'current-time)
              (lambda () (encode-time 10 0 9 18 4 2026))))
     (my/workout-review-today))
   (should (string-match-p
            (workout-test--row-regexp "2026-04-18" "note today")
            (workout-test--read-review)))))

(ert-deftest workout-test/current-week-uses-monday-sunday-boundaries ()
  (workout-test/with-temp-env
   ;; Reference date is Wednesday 2026-04-15; week should be 2026-04-13..2026-04-19.
   (workout-test--write-daily "2026-04-13" "* workout\nmon")
   (workout-test--write-daily "2026-04-19" "* workout\nsun")
   (workout-test--write-daily "2026-04-20" "* workout\noutside")
   (cl-letf (((symbol-function 'current-time)
              (lambda () (encode-time 0 0 8 15 4 2026))))
     (my/workout-review-current-week))
   (let ((review (workout-test--read-review)))
     (should (string-match-p (workout-test--row-regexp "2026-04-13" "mon") review))
     (should (string-match-p (workout-test--row-regexp "2026-04-19" "sun") review))
     (should-not (string-match-p (workout-test--row-regexp "2026-04-20" "outside") review)))))

(ert-deftest workout-test/incremental-update-append-and-preserve-unrelated-rows ()
  (workout-test/with-temp-env
   (with-temp-file my/workout-review-path
     (insert "| Day | Raw notes |\n")
     (insert "|-----+-----------|\n")
     (insert "| 2026-04-10 | stale |\n")
     (insert "| 2026-04-11 | keep-me |\n"))
   (workout-test--write-daily "2026-04-10" "* workout\nupdated")
   (workout-test--write-daily "2026-04-12" "* workout\nappended")
   (my/workout-review-from-date-range '(4 10 2026) '(4 12 2026))
   (let ((review (workout-test--read-review)))
     (should (string-match-p (workout-test--row-regexp "2026-04-10" "updated") review))
     (should (string-match-p (workout-test--row-regexp "2026-04-11" "keep-me") review))
     (should (string-match-p (workout-test--row-regexp "2026-04-12" "appended") review))
     (should (= 1
                (with-temp-buffer
                  (insert review)
                  (how-many (workout-test--row-regexp "2026-04-10" "updated")
                            (point-min) (point-max))))))))

(ert-deftest workout-test/missing-file-and-no-workout-heading-do-not-change-that-day ()
  (workout-test/with-temp-env
   (with-temp-file my/workout-review-path
     (insert "| Day | Raw notes |\n")
     (insert "|-----+-----------|\n")
     (insert "| 2026-04-17 | baseline |\n"))
   ;; Exists but no workout heading.
   (workout-test--write-daily "2026-04-18" "* journal\nno workouts")
   ;; 2026-04-19 file intentionally missing.
   (my/workout-review-from-date-range '(4 18 2026) '(4 19 2026))
   (let ((review (workout-test--read-review)))
     (should (string-match-p (workout-test--row-regexp "2026-04-17" "baseline") review))
     (should-not (string-match-p "2026-04-18" review))
     (should-not (string-match-p "2026-04-19" review)))))

(ert-deftest workout-test/create-review-file-with-header-when-missing ()
  (workout-test/with-temp-env
   (should-not (file-exists-p my/workout-review-path))
   (my/workout-review-from-date-range '(4 18 2026) '(4 18 2026))
   (let ((review (workout-test--read-review)))
     (should (file-exists-p my/workout-review-path))
     (should (string-match-p "^|[[:space:]]*Day[[:space:]]*|[[:space:]]*Raw notes[[:space:]]*|" review)))))

(provide 'workout-test)
;;; workout-test.el ends here
