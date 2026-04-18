;;; workout.el --- Workout review table generator -*- lexical-binding: t; -*-

(require 'calendar)
(require 'cl-lib)
(require 'org)
(require 'subr-x)

(defgroup my/workout nil
  "Generate workout review rows from Org dailies."
  :group 'org)

(defcustom my/workout-dailies-path "~/org/roam/daily/"
  "Directory containing daily Org files named as YYYY-MM-DD.org."
  :type 'directory
  :group 'my/workout)

(defcustom my/workout-review-path "~/org/roam/workout-review.org"
  "Path to the Org file where the workout review table is stored."
  :type 'file
  :group 'my/workout)

(defconst my/workout--day-format "%Y-%m-%d")
(defconst my/workout--daily-file-format "%Y-%m-%d.org")
(defconst my/workout--table-header "| Day | Raw notes |")
(defconst my/workout--table-separator "|-----+-----------|")

(defun my/workout--normalize-date (date)
  "Normalize DATE to local midnight time value.

DATE accepts a time value, a calendar date list (MONTH DAY YEAR),
or a string parseable by `date-to-time'."
  (pcase date
    ((and (pred listp)
          (pred (lambda (d)
                  (and (= (length d) 3)
                       (integerp (nth 0 d))
                       (integerp (nth 1 d))
                       (integerp (nth 2 d))))))
     (let ((month (nth 0 date))
           (day (nth 1 date))
           (year (nth 2 date)))
       (encode-time 0 0 0 day month year)))
    ((pred stringp)
     (let* ((parsed (date-to-time date))
            (decoded (decode-time parsed)))
       (encode-time 0 0 0 (nth 3 decoded) (nth 4 decoded) (nth 5 decoded))))
    (_
     (let* ((decoded (decode-time date)))
       (encode-time 0 0 0 (nth 3 decoded) (nth 4 decoded) (nth 5 decoded))))))

(defun my/workout--day-key (date)
  "Format DATE as canonical table day key YYYY-MM-DD."
  (format-time-string my/workout--day-format (my/workout--normalize-date date)))

(defun my/workout--daily-file-for-date (date)
  "Resolve daily Org file path for DATE."
  (expand-file-name
   (format-time-string my/workout--daily-file-format (my/workout--normalize-date date))
   my/workout-dailies-path))

(defun my/workout--sanitize-cell (text)
  "Sanitize TEXT for a single-line Org table cell."
  (let* ((without-newlines (replace-regexp-in-string "[\n\r\t]+" " " text))
         (without-pipes (replace-regexp-in-string "|" "\\vert{}" without-newlines))
         (collapsed (replace-regexp-in-string "[[:space:]]+" " " without-pipes)))
    (string-trim collapsed)))

(defun my/workout--extract-workout-subtree (file)
  "Extract raw notes from first case-insensitive `workout' heading in FILE.

Returns nil when FILE is missing or no matching heading exists."
  (when (file-exists-p file)
    (with-temp-buffer
      (insert-file-contents file)
      (org-mode)
      (goto-char (point-min))
      (let (raw-notes)
        (while (and (not raw-notes)
                    (re-search-forward org-heading-regexp nil t))
          (when (string-equal
                 (downcase (string-trim (org-get-heading t t t t)))
                 "workout")
            (setq raw-notes
                  (buffer-substring-no-properties
                   (save-excursion
                     (org-end-of-meta-data t)
                     (point))
                   (save-excursion
                     (org-end-of-subtree t t)
                     (point))))))
         (when raw-notes
           (let ((sanitized (my/workout--sanitize-cell raw-notes)))
             (unless (string-empty-p sanitized)
               sanitized)))))))

(defun my/workout--date-range (start end)
  "Build inclusive list of dates from START to END.

START and END may be any accepted DATE form for `my/workout--normalize-date'."
  (let* ((start-time (my/workout--normalize-date start))
         (end-time (my/workout--normalize-date end))
         (from (if (time-less-p start-time end-time) start-time end-time))
         (to (if (time-less-p start-time end-time) end-time start-time))
         (cursor from)
         result)
    (while (not (time-less-p to cursor))
      (push cursor result)
      (setq cursor (time-add cursor (days-to-time 1))))
    (nreverse result)))

(defun my/workout--ensure-review-file ()
  "Create review file and table header when missing."
  (let ((review-file (expand-file-name my/workout-review-path)))
    (unless (file-exists-p review-file)
      (make-directory (file-name-directory review-file) t)
      (with-temp-file review-file
        (insert my/workout--table-header "\n"
                my/workout--table-separator "\n")))
    review-file))

(defun my/workout--parse-table-row (line)
  "Parse Org table LINE to (DAY . RAW-NOTES) or nil when malformed."
  (let ((cells (mapcar #'string-trim (split-string line "|" t))))
    (when (>= (length cells) 2)
      (cons (nth 0 cells)
            (mapconcat #'identity (cdr cells) " | ")))))

(defun my/workout--locate-review-table (lines)
  "Find workout review table boundaries in LINES.

Returns plist with :header-index, :separator-index and :end-index.
Returns nil when table header is missing."
  (let ((index 0)
        header-index)
    (while (and (< index (length lines)) (not header-index))
      (let ((row (my/workout--parse-table-row (nth index lines))))
        (when (and row (string-equal (car row) "Day"))
          (setq header-index index)))
      (setq index (1+ index)))
    (when header-index
      (let ((separator-index (1+ header-index))
            (end-index header-index))
        (while (and (< end-index (length lines))
                    (string-prefix-p "|" (nth end-index lines)))
          (setq end-index (1+ end-index)))
        (list :header-index header-index
              :separator-index separator-index
              :end-index (1- end-index))))))

(defun my/workout--render-row (day raw-notes)
  "Render Org table row for DAY and RAW-NOTES."
  (format "| %s | %s |" day raw-notes))

(defun my/workout--align-review-tables (buffer)
  "Align Org tables in BUFFER."
  (with-current-buffer buffer
    (org-mode)
    (goto-char (point-min))
    (while (re-search-forward "^|" nil t)
      (beginning-of-line)
      (ignore-errors (org-table-align))
      (forward-line 1))))

(defun my/workout--upsert-review-rows (rows)
  "Upsert ROWS into workout review table.

ROWS is an alist of (DAY . RAW-NOTES)."
  (let* ((review-file (my/workout--ensure-review-file))
         (content (with-temp-buffer
                    (insert-file-contents review-file)
                    (split-string (buffer-string) "\n" nil)))
         (table (my/workout--locate-review-table content)))
    (unless table
      (setq content (append content
                            (list my/workout--table-header my/workout--table-separator)))
      (setq table (my/workout--locate-review-table content)))
    (let* ((header-index (plist-get table :header-index))
           (end-index (plist-get table :end-index))
           (row-index-by-day (make-hash-table :test #'equal))
           (index (+ header-index 2)))
      (while (<= index end-index)
        (let* ((line (nth index content))
               (row (and (string-prefix-p "|" line)
                         (my/workout--parse-table-row line))))
          (when row
            (puthash (car row) index row-index-by-day)))
        (setq index (1+ index)))
      (dolist (row rows)
        (let* ((day (car row))
               (raw-notes (cdr row))
               (new-line (my/workout--render-row day raw-notes))
               (existing-index (gethash day row-index-by-day)))
          (if existing-index
              (setf (nth existing-index content) new-line)
            (setq content
                  (append (cl-subseq content 0 (1+ end-index))
                          (list new-line)
                          (cl-subseq content (1+ end-index))))
            (setq end-index (1+ end-index))
            (puthash day end-index row-index-by-day)))))
    (with-temp-buffer
      (insert (mapconcat #'identity content "\n"))
      (unless (bolp) (insert "\n"))
      (my/workout--align-review-tables (current-buffer))
      (write-region (point-min) (point-max) review-file nil 'silent))))

(defun my/workout--rows-from-dates (dates)
  "Collect (DAY . RAW-NOTES) rows for DATES.

Missing files or dates without workout headings are skipped."
  (let (rows)
    (dolist (date dates)
      (let* ((day (my/workout--day-key date))
             (file (my/workout--daily-file-for-date date))
             (raw-notes (my/workout--extract-workout-subtree file)))
        (when raw-notes
          (push (cons day raw-notes) rows))))
    (nreverse rows)))

(defun my/workout--generate-review-for-dates (dates)
  "Generate or update review rows for DATES."
  (let ((rows (my/workout--rows-from-dates dates)))
    (my/workout--ensure-review-file)
    (when rows
      (my/workout--upsert-review-rows rows))))

(defun my/workout-review-from-date-range (start end)
  "Generate workout review from inclusive START..END date range.

When called interactively, prompts for both dates via calendar."
  (interactive
   (list (calendar-read-date)
         (calendar-read-date)))
  (my/workout--generate-review-for-dates
   (my/workout--date-range start end)))

(defun my/workout-review-today ()
  "Generate workout review for current local day."
  (interactive)
  (my/workout--generate-review-for-dates (list (current-time))))

(defun my/workout-review-current-week ()
  "Generate workout review for current local week (Monday-Sunday)."
  (interactive)
  (let* ((now (current-time))
         (decoded (decode-time now))
         (day-of-week (nth 6 decoded))
         (days-since-monday (if (= day-of-week 0) 6 (1- day-of-week)))
         (week-start (time-subtract (my/workout--normalize-date now)
                                    (days-to-time days-since-monday)))
         (week-end (time-add week-start (days-to-time 6))))
    (my/workout--generate-review-for-dates (my/workout--date-range week-start week-end))))

(provide 'workout)
;;; workout.el ends here
