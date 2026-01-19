(defun rspec-controller-file-p (a-file-name)
  "Check if A-FILE-NAME is a controller file."
  (and a-file-name
       (string-match-p "/controllers/.*_controller\\.rb$" a-file-name)))

(defun rspec-controller-spec-candidates (a-file-name)
  "Return list of possible spec file paths for controller A-FILE-NAME.
Checks both spec/controllers and spec/requests directories."
  (let* ((project-root (rspec-project-root a-file-name))
         (controller-name (file-name-base a-file-name))
         (resource-name (replace-regexp-in-string "_controller$" "" controller-name)))
    (list
     ;; spec/controllers/foo_controller_spec.rb
     (expand-file-name (concat "spec/controllers/" controller-name "_spec.rb") project-root)
     ;; spec/requests/foo_controller_spec.rb
     (expand-file-name (concat "spec/requests/" controller-name "_spec.rb") project-root)
     ;; spec/requests/foo_spec.rb (without _controller)
     (expand-file-name (concat "spec/requests/" resource-name "_spec.rb") project-root)
     ;; spec/requests/foo_request_spec.rb
     (expand-file-name (concat "spec/requests/" resource-name "_request_spec.rb") project-root))))

(defun rspec-find-existing-spec (candidates)
  "Return the first existing file from CANDIDATES, or nil if none exist."
  (cl-find-if #'file-exists-p candidates))

(defun rspec-spec-file-for (a-file-name)
  "Find spec for the specified file.
For controller files, checks both spec/controllers and spec/requests directories."
  (if (rspec-spec-file-p a-file-name)
      a-file-name
    (if (rspec-controller-file-p a-file-name)
        ;; Controller file: check multiple locations
        (let* ((candidates (rspec-controller-spec-candidates a-file-name))
               (existing (rspec-find-existing-spec candidates)))
          (or existing
              ;; Default to spec/controllers if none exist
              (car candidates)))
      ;; Non-controller file: use standard behavior
      (let ((replace-regex (if (rspec-target-in-holder-dir-p a-file-name)
                               "^\\.\\./[^/]+/"
                             "^\\.\\./"))
            (relative-file-name (file-relative-name a-file-name (rspec-spec-directory a-file-name))))
        (rspec-specize-file-name (expand-file-name (replace-regexp-in-string replace-regex "" relative-file-name)
                                                   (rspec-spec-directory a-file-name)))))))
