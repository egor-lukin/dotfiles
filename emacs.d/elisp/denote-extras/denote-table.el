;; -*- lexical-binding: t; -*-
(require 'seq)

(defun denote-table--search (pred)
  (let ((files (denote-directory-files)))
    (seq-filter
     (lambda (f) (denote-table--filter f pred))
     (mapcar 'denote-table--parse-path files))))

(defun denote-table--parse-path (path)
  (let* ((filename (file-name-nondirectory path))
	 (id (denote-retrieve-filename-identifier filename))
	 (title (denote-retrieve-filename-title filename))
	 (slug (car (last (butlast (split-string path "/")))))
	 (link (format "[[denote:%s][%s]]" id title))
	 (keywords (denote-retrieve-filename-keywords filename)))
    `(
      :filename ,filename
      :id ,id
      :title ,title
      :slug ,slug
      :link ,link
      :keywords ,keywords)))

(defun denote-table--filter (file pred)
  (let* ((filename (plist-get file :filename))
	 (id (plist-get file :id))
	 (title (plist-get file :title))
	 (slug (plist-get file :slug))
	 (link (plist-get file :link))
	 (keywords (plist-get file :keywords)))
        (eval `(let ((slug ,slug)
                 (filename ,filename)
                 (title ,title)
                 (id ,id)
                 (keywords ,keywords))
             ,(read pred)))))

(defun denote-table--render (files)
  (insert "| link | id |\n")
  (insert "|--+--|\n")
  (dolist (f files)
    (insert
     (format "| %s |\n"
	     (plist-get f :link)
	     (plist-get f :id)))
  (org-table-align)))

;;;###autoload
  (defun org-dblock-write:denote-table (params)
    "Generate finded denote files"
    (let ((pred (plist-get params :pred)))
      (denote-table--render
       (denote-table--search pred))))
