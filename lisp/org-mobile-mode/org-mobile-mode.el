;;; org-mobile-mode.el --- Org mode improvements for touch screen  -*- lexical-binding: t; -*-

;;; Code:

(defvar org-mobile-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<double-mouse-1>") 'org-mobile-mode--handle-item-touch)
    (define-key map (kbd "<down-mouse-1>") 'org-mobile-mode--handle-item-touch)
    map)
  "Keymap for `org-mobile-mode'.")


(defcustom org-mobile-mode-option t
  "An example option for `org-mobile-mode'."
  :type 'boolean
  :group 'org-mobile-mode)


(defun org-mobile-mode--handle-item-touch ()
  "Handle a touch (double mouse-1) on an org element.
Determine the element type and respond accordingly."
  (interactive)
  (let* ((el (org-element-at-point))
         (type (org-element-type el)))
    (pcase type
      ('headline
       (org-cycle))

      ('item
       (if (org-element-property :checkbox el)
           (org-ctrl-c-ctrl-c)
         (message "list item")))

      (_
       (message "other: %s" type)))))


(defun org-mobile-mode--check-org-mode ()
  "Disable `org-mobile-mode' if current major mode is not `org-mode'."
  (when (and org-mobile-mode (not (derived-mode-p 'org-mode)))
    (org-mobile-mode -1)))

;;;###autoload
(define-minor-mode org-mobile-mode
  "Toggle `org-mobile-mode' minor mode.

When `org-mobile-mode' is enabled, it provides customization and commands.
This mode is only active in `org-mode' buffers; enabling it in other
buffers will automatically disable itself.

\\{org-mobile-mode-map}"
  :init-value nil
  :keymap org-mobile-mode-map
  :global nil
  :group 'org-mobile-mode
  (if org-mobile-mode
      (progn
        ;; Ensure we are in org-mode, otherwise disable immediately
        (unless (derived-mode-p 'org-mode)
          (org-mobile-mode -1)
          (message "org-mobile-mode only works in org-mode buffers"))
        ;; Add hook to disable if major mode changes away from org-mode
        (add-hook 'after-change-major-mode-hook
                  #'org-mobile-mode--check-org-mode
                  nil t))
    ;; Disabling: remove the hook
    (remove-hook 'after-change-major-mode-hook
                 #'org-mobile-mode--check-org-mode
                 t)))

;;;###autoload
(provide 'org-mobile-mode)

;;; org-mobile-mode.el ends here
