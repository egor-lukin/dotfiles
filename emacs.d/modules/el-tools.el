;; -*- lexical-binding: t; -*-
;;; el-tools.el --- Git, shells, projects, docker, files, snippets

;;; Code:

(require 'el-core)
(require 'el-keys)
(require 'el-docker)
(require 'el-project)


;;;; Git

(use-package magit
  :commands (magit-status magit-blame-addition magit-log-current))

(use-package diff-hl
  :demand t
  :config
  (global-diff-hl-mode 1)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))


;;;; Терминалы

(use-package vterm
  :commands (vterm vterm-other-window)
  :config (setq vterm-max-scrollback 10000))

(defun el-eshell-load-bash-aliases ()
  "Read Bash aliases and add them to the list of eshell aliases."
  (with-temp-buffer
    (call-process "bash" nil '(t nil) nil "-ci" "alias")
    (goto-char (point-min))
    (while (re-search-forward "alias \\(.+\\)='\\(.+\\)'$" nil t)
      (eshell/alias (match-string 1) (match-string 2)))))

(with-eval-after-load 'eshell
  (add-hook 'eshell-alias-load-hook #'el-eshell-load-bash-aliases))

(use-package tramp-term
  :commands (tramp-term))


;;;; Проекты

(setq project-vc-extra-root-markers '(".project.el" "Gemfile" "package.json"))

;; Замена projectile-project-search-path: без этого project-switch-project
;; показывает пустой список, пока проект не открыли руками.  Один уровень
;; вложенности, как и у projectile; ~0.1 с на 173 проекта в ~/dev.
(with-eval-after-load 'project
  (when (file-directory-p projects-dir)
    (project-remember-projects-under projects-dir nil)))

(defun el-project-toggle-test ()
  "Jump between the current file and its test counterpart.
When no counterpart exists, visit the most likely path so the file can be
created in place."
  (interactive)
  (let* ((project (or (project-current) (user-error "Not in a project")))
         (root (project-root project))
         (file (or (buffer-file-name) (user-error "Buffer is not visiting a file")))
         (relative (file-relative-name file root))
         (candidates (el-project-counterparts relative)))
    (unless candidates
      (user-error "No test mapping for %s" relative))
    (find-file
     (expand-file-name
      (or (seq-find (lambda (c) (file-exists-p (expand-file-name c root))) candidates)
          (car candidates))
      root))))

(defun el-project-break-location-copy ()
  "Copy a debugger break location for the current line to the kill ring."
  (interactive)
  (let* ((file (or (buffer-file-name) (user-error "Buffer is not visiting a file")))
         (root (when-let* ((project (project-current))) (project-root project)))
         (relative (if root (file-relative-name file root) file))
         (text (el-project-break-string relative (line-number-at-pos))))
    (kill-new text)
    (message "Copied: %s" text)))


;;;; Docker через tramp
;; Метод /docker: встроен в Emacs 29+ (tramp-container); docker-tramp не нужен.

(use-package docker
  :commands (docker))

(defun el-docker-find-file ()
  "Pick a running container and open its filesystem over tramp."
  (interactive)
  (let* ((output (shell-command-to-string
                  (format "docker ps --format '%s'" el-docker-ps-format)))
         (candidates (el-docker-parse-ps output)))
    (unless candidates
      (user-error "No running containers"))
    (let* ((label (completing-read "Container: " (mapcar #'car candidates) nil t))
           (entry (cdr (assoc label candidates)))
           (by (completing-read "Access by: " '("name" "id") nil t))
           (target (if (equal by "name") (car entry) (cdr entry))))
      (find-file (format "/docker:%s:/" target)))))


;;;; Файловые команды

(defun el-delete-file-and-buffer ()
  "Delete the file the current buffer visits, then kill the buffer."
  (interactive)
  (let ((filename (buffer-file-name)))
    (unless filename
      (user-error "Not a file visiting buffer"))
    (when (y-or-n-p (format "Do you really want to delete file %s ? " filename))
      (delete-file filename)
      (message "Deleted file %s." filename)
      (kill-buffer))))

(defun el-rename-file-and-buffer (new-name)
  "Rename both the current buffer and the file it visits to NEW-NAME."
  (interactive "sNew name: ")
  (let ((filename (buffer-file-name)))
    (unless filename
      (user-error "Buffer '%s' is not visiting a file" (buffer-name)))
    (when (get-buffer new-name)
      (user-error "A buffer named '%s' already exists" new-name))
    (rename-file filename new-name 1)
    (set-visited-file-name new-name)
    (rename-buffer new-name)
    (set-buffer-modified-p nil)))


;;;; Пароли

(use-package password-store
  :commands (password-store-get password-store-copy password-store-edit))


;;;; Dired

(setq dired-listing-switches "-alh --group-directories-first"
      dired-dwim-target t
      dired-kill-when-opening-new-dired-buffer t)

(use-package diredfl
  :hook (dired-mode . diredfl-mode))


;;;; Сниппеты

(use-package yasnippet
  :demand t
  :config
  (setq yas-snippet-dirs
        (list (expand-file-name "snippets" org-dir)
              (expand-file-name "snippets" user-emacs-directory)))
  (yas-global-mode 1))


;;;; Скобки

(use-package smartparens
  :demand t
  :config
  (require 'smartparens-config)
  (smartparens-global-mode 1)
  (show-paren-mode 1))


;;;; Воркспейсы

(use-package persp-mode
  :demand t
  :config
  (setq persp-nil-name "main"
        persp-auto-resume-time 0
        persp-auto-save-opt 1)
  (persp-mode 1))


;;;; Документация и Makefile

(use-package dash-docs
  :vc (:url "https://github.com/dash-docs-el/dash-docs.git" :rev :newest)
  :commands (dash-docs-search)
  :config
  (setq dash-docs-docsets-path (expand-file-name "~/.docsets")))

(use-package consult-dash
  :commands (consult-dash))

(use-package makefile-executor
  :vc (:url "https://github.com/Olivia5k/makefile-executor.el.git" :rev :newest)
  :commands (makefile-executor-execute-project-target))


;;;; Биндинги

(el-leader!
  "g"   '(:ignore t :which-key "git")
  "g g" '(magit-status :which-key "status")
  "g b" '(magit-blame-addition :which-key "blame")
  "g l" '(magit-log-current :which-key "log")
  "g d" '(magit-diff-buffer-file :which-key "diff file")

  "p"   '(:ignore t :which-key "project")
  "p p" '(project-switch-project :which-key "switch project")
  "p f" '(project-find-file :which-key "find file")
  "p b" '(consult-project-buffer :which-key "project buffer")
  "p d" '(project-dired :which-key "dired")
  "p c" '(project-compile :which-key "compile")
  "p k" '(project-kill-buffers :which-key "kill buffers")
  "p t" '(el-project-toggle-test :which-key "toggle impl/test")

  "f d" '(el-delete-file-and-buffer :which-key "delete file")
  "f R" '(el-rename-file-and-buffer :which-key "rename file")
  "f b" '(el-project-break-location-copy :which-key "copy break location")

  "o d" '(el-docker-find-file :which-key "docker tramp")
  "o t" '(vterm :which-key "vterm")
  "o e" '(eshell :which-key "eshell")
  "o D" '(docker :which-key "docker")

  "l"   '(:ignore t :which-key "lookup")
  "l f" '(consult-dash :which-key "docsets")
  "l p" '(dash-docs-search :which-key "docsets at point")

  "m"   '(:ignore t :which-key "make")
  "m p" '(makefile-executor-execute-project-target :which-key "project target")

  "b l" '(list-bookmarks :which-key "list bookmarks")
  "b d" '(bookmark-delete :which-key "delete bookmark")
  "b s" '(bookmark-set :which-key "set bookmark")

  "TAB"   '(:ignore t :which-key "workspace")
  "TAB n" '(persp-add-new :which-key "new")
  "TAB d" '(persp-kill :which-key "kill")
  "TAB ." '(persp-switch :which-key "switch"))

(provide 'el-tools)
;;; el-tools.el ends here
