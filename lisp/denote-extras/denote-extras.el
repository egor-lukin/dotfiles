;; -*- lexical-binding: t; -*-

(defun my/denote-journal-open-next-day ()
  "Open the Denote journal file for the next day."
  (interactive)
  (if (denote-journal-file-is-journal-p (buffer-file-name))
      (let* ((current-date (my/denote-journal--extract-date buffer-file-name))
            (date (my/denote-journal--next-date current-date))
            (time (date-to-time date))
            (files (denote-journal--get-entry time 1)))
        (if files
            (find-file (car files))
          (message "No journal file for %s" date)))
    (message "Current buffer is not a Denote journal file")))

(defun my/denote-journal-open-previous-day ()
  "Open the Denote journal file for the previous day."
  (interactive)
  (if (denote-journal-file-is-journal-p (buffer-file-name))
      (let* ((current-date (my/denote-journal--extract-date buffer-file-name))
            (date (my/denote-journal--previous-date current-date))
            (time (date-to-time date))
            (files (denote-journal--get-entry time 1)))
        (if files
            (find-file (car files))
          (message "No journal file for %s" date)))
    (message "Current buffer is not a Denote journal file")))

(defun my/denote-journal--previous-date (date)
  (format-time-string
   "%Y-%m-%d"
   (time-subtract (date-to-time date) (days-to-time 1))))

(defun my/denote-journal--next-date (date)
  (format-time-string
   "%Y-%m-%d"
   (time-add (date-to-time date) (days-to-time 1))))

(defun my/denote-journal--extract-date (buffer-file-name)
  (when (string-match "--\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\)__" buffer-file-name)
    (match-string 1 buffer-file-name)))

(defmacro comment (&rest _) nil)

(provide 'denote-extras)

(comment
 (find-file
 (car (denote-journal--get-entry (date-to-time "2026-09-23") 1)))

 (my/denote-journal--extract-date "20260924T112655--2026-09-24__journal.org")
 (my/denote-journal--next-date "2026-09-24")
 (my/denote-journal--previous-date "2026-09-24")
 )
