(defun my/move-check-in-to-daily-note ()
  "Move 'check-in' items from the current buffer to daily note based on 'CREATED_AT' property."
  (interactive)
  (message "start")
  (my/map-check-ins
   (lambda (daily-note-file)
     (message daily-note-file)
     (org-copy-subtree)
     (my/insert-check-in-to-daily-note daily-note-file (current-kill 0))
     (org-cut-subtree)))  ;; Remove the 'check-in' heading after processing
  (message "finish"))

(defun my/map-check-ins (handler)
  (org-map-entries
   (lambda ()
     (when (or (string= (org-get-heading t t t t) "check-in") (string= (org-get-heading t t t t) "workout"))
       (let* ((created-at (org-entry-get (point) "CREATED"))
              (daily-note-file (my/daily-note-filename created-at)))
         (funcall handler daily-note-file))))
   nil))

(defun my/daily-note-filename (date)
  "Generate the filename for the daily note based on DATE."
  (concat
   "~/org/roam/daily/"
   (format-time-string "%Y-%m-%d" (org-time-string-to-time date))
   ".org"))

(defun my/insert-check-in-to-daily-note (daily-note-file subtree)
  "Insert the 'check-in' SUBTREE into the specified DAILY-NOTE-FILE under 'test header'."
  (with-current-buffer (find-file-noselect daily-note-file)
    (goto-char (point-min))
    (re-search-forward "^\\* buffer" nil t)
    (insert (concat "\n" subtree "\n"))
    (save-buffer)))

(defun my/org-header-summarize-and-insert ()
  "Summarize the URL in org-mode header at point and insert the summary asynchronously."
  (interactive)
  (let* ((heading (org-get-heading t t t t))
         (url heading)
         (summary-buffer (generate-new-buffer "*gptel-summary*")))
    (message url)
    (when (and url (not (string-empty-p url)))
      (message "when")
      (eww-browse-url url)
      (with-current-buffer "eww"
        (let ((content (buffer-string)))
          (gptel-request
              content  ; Use the EWW content as the prompt
            :buffer summary-buffer
            :callback (lambda (response _info)
                        (with-current-buffer (org-get-current-buffer)
                          (save-excursion
                            (org-beginning-of-line)
                            (insert (format "\n\"%s\"" response)))))))))))


(defun my/org-agenda-list-as-string ()
  "Return the org-agenda-list output as a string."
  (with-temp-buffer
    (let ((standard-output (current-buffer)))
      (org-agenda-list nil (format-time-string "%Y-%m-%d") 'day)
      (buffer-string))))
