;; -*- lexical-binding: t; -*-
;;; el-docker.el --- Parse docker ps output into completion candidates

;;; Code:

(defconst el-docker-ps-format "{{.Names}}|{{.CreatedAt}}|{{.ID}}"
  "Format string passed to `docker ps --format'.")

(defun el-docker-parse-ps (output)
  "Parse OUTPUT of `docker ps --format el-docker-ps-format'.
Return a list of (LABEL NAME . ID).  Lines that do not carry all three
fields are skipped, because without an id they are useless for tramp."
  (delq nil
        (mapcar
         (lambda (line)
           (let ((parts (split-string line "|")))
             (when (= 3 (length parts))
               (let ((name (nth 0 parts))
                     (created (nth 1 parts))
                     (id (nth 2 parts)))
                 (cons (format "%s (%s) [%s]" name created id)
                       (cons name id))))))
         (split-string output "\n" t))))

(provide 'el-docker)
;;; el-docker.el ends here
