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
    (insert (concat "\n*" subtree "\n"))
    (save-buffer)))

;; (defun test-my/map-check-ins ()
;;   "Test for `my/map-check-ins` function."
;;   (let ((test-buffer (generate-new-buffer "*test-check-in*"))
;;         (called nil)
;;         (expected-file (my/daily-note-filename "2025-04-10")))
;;     (with-current-buffer test-buffer
;;       (org-mode)  ;; Ensure the buffer is in Org-mode
;;       (insert "* Inbox\n** check-in\n:PROPERTIES:\n:CREATED: 2025-04-10\n:END:\nSome
;; content here\n")
;;       (goto-char (point-min))
;;       (my/map-check-ins
;;        (lambda (daily-note-file)
;;          (setq called t)
;;          (cl-assert (string= daily-note-file expected-file))))
;;       (cl-assert called))
;;     (kill-buffer test-buffer)))
