;; -*- lexical-binding: t; -*-
;;; el-clock.el --- Clock arithmetic used by org tables

;;; Commentary:
;; `hms-to-minutes' и `hms-to-pomodoros' вызываются из формул org-таблиц
;; в ~/org/tasks и ~/org/snippets, поэтому их имена сохранены без
;; префикса el- и их поведение закреплено тестами.

;;; Code:

(require 'subr-x)

(defconst el-clock-pomodoro-minutes 25
  "Length of one pomodoro in minutes.")

(defun hms-to-minutes (str)
  "Convert STR to a whole number of minutes.
STR may be \"H:MM\", \"H:MM:SS\" or a bare number of minutes, with or
without surrounding whitespace.  Blank, nil and unparsable input yield 0,
so a stray cell cannot break the recalculation of a whole org table."
  (cond
   ((or (null str) (string-blank-p str)) 0)
   ((string-match-p ":" str)
    (let* ((parts (split-string (string-trim str) ":"))
           (hours (string-to-number (or (nth 0 parts) "0")))
           (minutes (string-to-number (or (nth 1 parts) "0"))))
      (+ (* hours 60) minutes)))
   (t (truncate (string-to-number str)))))

(defun hms-to-pomodoros (str)
  "Convert STR to a whole number of pomodoros, truncating toward zero.
Surrounding org bold markers are stripped, so \"*1:30*\" and \"1:30\"
agree."
  (let ((str (and str (string-trim str))))
    (cond
     ((or (null str) (string-blank-p str)) 0)
     ((and (string-prefix-p "*" str) (string-suffix-p "*" str))
      (hms-to-pomodoros (substring str 1 -1)))
     (t (/ (hms-to-minutes str) el-clock-pomodoro-minutes)))))

(defun el-clock-format-line (task minutes)
  "Format TASK and MINUTES as a one-line clock summary."
  (format "%s (%d min)" task minutes))

(provide 'el-clock)
;;; el-clock.el ends here
