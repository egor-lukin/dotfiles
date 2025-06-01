(setq workspace-dir "~/dotfiles/")
(setq emacs-dir (concat workspace-dir "doom.d/"))
(setq projects-dir "~/dev/")
(setq org-dir "~/org/")
(setq gtd-dir (concat org-dir "/roam/gtd/"))

(load-file (expand-file-name "flows.el" emacs-dir))

(setq user-full-name "Egor Lukin"
      user-mail-address "mail@egorlukin.me")

(setq multi-term-program-switches "--login")

(require 'epa-file)
(epa-file-enable)
(setq epa-file-encrypt-to "mail@egorlukin.me")
(setq epg-pinentry-mode 'loopback)

(with-eval-after-load 'company
  (define-key company-mode-map (kbd "<tab>") 'company-complete))

(setq yas-snippet-dirs '("~/org/snippets"
                         "~/emacs.d/mysnippets"))

(setq doom-theme 'doom-monokai-pro)

(setq doom-font (font-spec :family "monospace" :size 42 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "sans" :size 42))

(setq display-line-numbers-type t)

(setq gtd/files '("gtd.org" "backlog.org" "archieved.org"))

(defun gtd/all-files ()
  (mapcar
   (lambda (f) (concat gtd-dir f))
   (append
    (mapcar
     (lambda (f) (concat "archived/" f))
     (seq-filter
      (lambda (f) (not(member f '("." ".."))))
      (directory-files (concat gtd-dir "archived"))))
    gtd/files)))

(after! org
  (setq org-directory org-dir)
  (setq org-log-done t)
  (setq org-log-into-drawer t)
  (setq org-download-dir (concat org-dir "screenshots/"))
  (setq org-archive-location (concat gtd-dir "archieved.org::"))

  (setq org-agenda-files '("~/org/roam/gtd"))

  (setq org-refile-targets '((org-agenda-files :maxlevel . 2)))

  (setq org-todo-keywords
        '((sequence "TODO" "IN-PROGRESS" "WAIT" "|" "DONE" "CLOSED"))))

(require 'org-habit)

(setq org-habit-show-habits-only-for-today t)
(setq org-habit-preceding-days 25)
(setq org-habit-following-days 3)

(use-package org-drill
  :ensure t
  :config
  (setq org-drill-spaced-repetition-algorithm 'sm2))

(use-package! gptel
 :config
 (setq! gptel-api-key (getenv "OPENAI_API_KEY")))

(defun my/org-roam-node-find-by-directory ()
  (interactive)
  (let* ((directories '("tasks" "literate" "conceptual" "projects" "planning"))
        (directory (completing-read "Enter directory: " directories)))
    (org-roam-node-find t nil
                        (lambda (node)
                          (let ((tags (org-roam-node-tags node)))
                            (member directory tags))))))

(after! org-roam
  (setq org-roam-directory "~/org/roam")
  (setq org-roam-db-location  "~/org/roam/org-roam.db")

  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry
           "* %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%A, %d %B %Y>\n"))))

  ;; add specific template for 'tasks' notes
  (setq org-roam-capture-templates
        '(("l" "Literate note" plain
           "%?"
           :if-new (file+head "literate/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :literate\n")
           :unnarrowed t)
          ("t" "Tasks note" plain
           "%?"
           :if-new (file+head "tasks/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :task\n")
           :unnarrowed t)
          ("p" "Project note" plain
           "%?"
           :if-new (file+head "projects/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :project\n")
           :unnarrowed t)
          ))

  (map! :leader
        :prefix "r"
        :desc "org-roam-node-insert" "i" #'org-roam-node-insert
        :desc "org-roam-node-find" "f" #'org-roam-node-find
        :desc "org-roam-node-find-by-directory" "t" #'my/org-roam-node-find-by-directory
        :desc "org-roam-dailies-goto-date" "s" #'org-roam-dailies-goto-date
        :desc "org-roam-dailies-goto-today" "d" #'org-roam-dailies-goto-today
        :desc "org-roam-buffer" "l" #'org-roam-buffer
        :desc "org-roam-show-graph" "g" #'org-roam-show-graph
        :desc "org-roam-dailies-find-next-note" "n" #'org-roam-dailies-find-next-note
        :desc "org-roam-dailies-find-previous-note" "p" #'org-roam-dailies-find-previous-note
        :desc "org-roam-buffer-toggle" "b" #'org-roam-buffer-toggle
        :desc "org-roam-capture" "c" #'org-roam-capture))

(defun my/daily-note-filename ()
  (let ((date (format-time-string "%Y-%m-%d" (current-time))))
    (concat
     "~/org/roam/daily/"
     date
     ".org")))

;; %Y-%m-%d.org
(after! org
  (setq org-capture-templates
        '(("t" "Todo" entry
           (file+headline "roam/gtd/gtd.org" "Inbox")
           (file "templates/todo.org"))
          ("e" "English word" entry
           (file+headline "anki/english_words.org" "Backlog")
           (file "templates/english_words.org"))
          ("b" "Add entry to daily buffer" entry
           (file+headline (lambda () (my/daily-note-filename)) "buffer")
           (file "templates/buffer.org")))))

(setq org-clock-persist 'history)
(org-clock-persistence-insinuate)
(setq org-clock-persist t)

(use-package ellama
  :init
  ;; setup key bindings
  (setopt ellama-keymap-prefix "C-c e")
  ;; language you want ellama to translate to
  (setopt ellama-language "Russian")
  ;; could be llm-openai for example
  (require 'llm-ollama)

  (setopt ellama-sessions-directory "~/org/ellama")

  (setopt ellama-provider
		    (make-llm-ollama
		     ;; this model should be pulled to use it
		     ;; value should be the same as you print in terminal during pull
		     :chat-model "llama3:latest"
		     :embedding-model "llama3:latest"))
  ;; Predefined llm providers for interactive switching.
  ;; You shouldn't add ollama providers here - it can be selected interactively
  ;; without it. It is just example.
  ;; (setopt ellama-providers
  ;;       	    '(("llama3" . (make-llm-ollama
  ;;       			   :chat-model "zephyr:7b-beta-q6_K"
  ;;       			   :embedding-model "zephyr:7b-beta-q6_K"))
  ;;       	      ("mistral" . (make-llm-ollama
  ;;       			    :chat-model "mistral:7b-instruct-v0.2-q6_K"
  ;;       			    :embedding-model "mistral:7b-instruct-v0.2-q6_K"))
  ;;       	      ("mixtral" . (make-llm-ollama
  ;;       			    :chat-model "mixtral:8x7b-instruct-v0.1-q3_K_M-4k"
  ;;       			    :embedding-model "mixtral:8x7b-instruct-v0.1-q3_K_M-4k"))))
  ;; Naming new sessions with llm
  (setopt ellama-naming-provider
	    (make-llm-ollama
	     :chat-model "llama3:latest"
	     :embedding-model "llama3:latest"))
  (setopt ellama-naming-scheme 'ellama-generate-name-by-llm)
  ;; Translation llm provider
  (setopt ellama-translation-provider (make-llm-ollama
					 :chat-model "llama3:latest"
					 :embedding-model "llama3:latest")))

(use-package aidermacs
  :config
  (setq
   aidermacs-openai-api-key (getenv "OPENAI_API_KEY")
   aidermacs-anthropic-api-key (getenv "ANTHROPIC_API_KEY")))

(setq projectile-project-search-path '("~/dev"))

(setq helm-mode-fuzzy-match t)

(setq ivy-re-builders-alist
      '((counsel-ag . regexp-quote)
        (t      . ivy--regex-fuzzy)))

(map! :leader
      :prefix "s"
      :desc "projectile-grep" "g" #'projectile-grep)

(setq ein:output-area-inlined-images t)

(map! :leader
      :prefix "j"
      :desc "execute cell" "e" #'ein:worksheet-execute-cell
      :desc "save notebook" "s" #'ein:notebook-save-notebook-command
      :desc "insert below" "b" #'ein:worksheet-insert-cell-below
      :desc "insert below" "a" #'ein:worksheet-insert-cell-after
      :desc "notebook list" "l" #'ein:notebooklist-open)

;; Google Translate Integration
(global-set-key "\C-ct" 'google-translate-at-point)
(global-set-key "\C-cr" 'google-translate-at-point-reverse)
(global-set-key "\C-cT" 'google-translate-query-translate)

(setq google-translate-default-source-language '"en")
(setq google-translate-default-target-language '"ru")

(setq google-translate-backend-method 'curl)

(use-package google-translate
  ;; :ensure t
  :custom
  (google-translate-backend-method 'curl)
  :config
   (defun google-translate--search-tkk () "Search TKK." (list 430675 2721866130)))

(setq browse-url-browser-function 'eww-browse-url)
(setq eww-download-directory "~/cached-web-pages")

;; Auto-rename new eww buffers
(defun xah-rename-eww-hook ()
  "Rename eww browser's buffer so sites open in new page."
  (rename-buffer "eww" t))
(add-hook 'eww-mode-hook #'xah-rename-eww-hook)
;; C-u M-x eww will force a new eww buffer
(defun modi/force-new-eww-buffer (orig-fun &rest args)
  "When prefix argument is used, a new eww buffer will be created,
regardless of whether the current buffer is in `eww-mode'."
  (if current-prefix-arg
      (with-temp-buffer
        (apply orig-fun args))
    (apply orig-fun args)))
(advice-add 'eww :around #'modi/force-new-eww-buffer)

(defun eww-search-current-line ()
  "Search the web using the current line's trimmed content with eww and set it as the selected region."
(interactive)
  (let* ((start (line-beginning-position))
         (end (line-end-position))
         (current-line (buffer-substring-no-properties start end))
         (trimmed-line (string-trim current-line)))
    ;; Replace current line with the trimmed one
    (delete-region start end)
    (insert trimmed-line)
    ;; Set the region to the trimmed line
    (set-mark (point))
    (goto-char start)
    ;; Call eww-search-word with the trimmed line
    (eww-search-words)))

(after! eww
  (map! :leader
        :prefix "e"
        :desc "eww-list-buffers" "l" #'eww-list-buffers
        :desc "eww-search-current-line" "f" #'eww-search-current-line
        :desc "eww-copy-page-url" "y" #'eww-copy-page-url))

(after! elfeed
  (setq elfeed-search-filter "@1-month-ago +unread")
  (setq elfeed-db-directory "~/elfeed.db"))

(setq deft-directory "~/org")
(setq deft-extensions '("txt" "tex" "org"))
(setq deft-recursive t)

(require 'openwith)
(openwith-mode t)
(setq openwith-associations
            (list
             (list (openwith-make-extension-regexp
                    '("mpg" "mpeg" "mp3" "mp4"
                      "avi" "wmv" "wav" "mov" "flv"
                      "ogm" "ogg" "mkv"))
                   "vlc"
                   '(file))
             ;; (list (openwith-make-extension-regexp
             ;;        '("xbm" "pbm" "pgm" "ppm" "pnm"
             ;;          "png" "gif" "bmp" "tif" "jpeg" "jpg"))
             ;;       "eog"
             ;;       '(file))
             ;; '("\\.pdf" "evince" (file))
             '("\\.djvu" "evince" (file))
             ))

(defvar polybar--default-header "no active clocks!")

(defun polybar--format-line (task time)
  (concat task " ("(number-to-string time) " min)"))

(defun polybar-current-clock-line ()
  (interactive)
  (message
   (if (org-clocking-p)
       (let ((header org-clock-heading)
             (time
              (floor
               (org-time-convert-to-integer (time-since org-clock-start-time))
               60)))
         (polybar--format-line header time))
     polybar--default-header)))

(map! :leader :prefix "b" :desc "polybar-current-clock-line" "c" #'polybar-current-clock-line)

(setq hledger-jfile "~/org/finances/ledger.journal")

 (defun eshell-load-bash-aliases ()
    "Read Bash aliases and add them to the list of eshell aliases."
    ;; Bash needs to be run - temporarily - interactively
    ;; in order to get the list of aliases.
      (with-temp-buffer
        (call-process "bash" nil '(t nil) nil "-ci" "alias")
        (goto-char (point-min))
        (while (re-search-forward "alias \\(.+\\)='\\(.+\\)'$" nil t)
          (eshell/alias (match-string 1) (match-string 2)))))

(setq helm-dash-docsets-path "~/.docsets")

(map! :leader
      :prefix "l"
      :desc "helm-dash-at-point" "p" #'helm-dash-at-point
      :desc "helm-dash-at-point" "f" #'helm-dash)

(map! :leader
      :prefix "b"
      :desc "list-bookmarks" "l" #'list-bookmarks
      :desc "bookmark-delete" "d" #'bookmark-delete
      :desc "bookmark-set" "s" #'bookmark-set)

(when (not (getenv "TERMUX_VERSION"))
  (xclip-mode 1))

(defun delete-file-and-buffer ()
  "Kill the current buffer and deletes the file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if filename
        (if (y-or-n-p (concat "Do you really want to delete file " filename " ?"))
            (progn
              (delete-file filename)
              (message "Deleted file %s." filename)
              (kill-buffer)))
      (message "Not a file visiting buffer!"))))

(defun rename-file-and-buffer (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME."
  (interactive "sNew name: ")
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not filename)
        (message "Buffer '%s' is not visiting a file!" name)
      (if (get-buffer new-name)
          (message "A buffer named '%s' already exists!" new-name)
        (progn
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil))))))

(defun org--photos-list ()
  (let* ((date (string-replace "-" "" (org-read-date)))
         (photos-path "~/photos/mobile/DCIM/Camera/")
         (command (concat "ls " photos-path " | grep " date))
         (photo-paths (split-string (shell-command-to-string command) "\n")))
    (seq-reduce
     (lambda (acc time)
       (if (not (string-blank-p time))
           (concat acc "\n"
                   "#+attr_html: :width 750px\n"
                   "[[file:" photos-path time "][" time "]" "]") acc))
     photo-paths "")))

(defun org-insert-photos ()
  (interactive)
  (insert (org--photos-list)))

;; (hms-to-pomodoros "1:22")
(defun hms-to-pomodoros (str)
  (/ (hms-to-minutes str) 25))

;; (hms-to-minutes "1:12")
(defun hms-to-minutes (str)
  (let* ((lst (split-string str ":"))
         (hour (nth 0 lst))
         (minute (nth 1 lst)))
    (+ (* (string-to-number hour) 60)
       (string-to-number minute))))

(use-package whisper
  :bind ("C-h r" . whisper-run)
  :config
  (setq whisper-install-directory "~/dev/whisper.cpp"
        whisper-model "base"
        whisper-language "auto"
        whisper-translate nil))

(setq docker-tramp-use-names t)

(defun my/helm-docker-containers ()
  "Open helm with docker ps output for quick tramp access to containers."
  (interactive)
  (let* ((cmd "docker ps --format '{{.Names}}|{{.CreatedAt}}|{{.ID}}'")
         (container-data (split-string (shell-command-to-string cmd) "\n" t))
         (formatted-containers 
          (mapcar (lambda (item)
                    (let* ((parts (split-string item "|"))
                           (name (car parts))
                           (created (cadr parts))
                           (hash (caddr parts)))
                      (cons (format "%s (%s) [%s]" name created hash) 
                            (cons name hash))))
                  container-data))
         (selected (helm :sources (helm-build-sync-source "Docker Containers"
                                    :candidates formatted-containers
                                    :action (lambda (candidate)
                                              (let ((container-name (car candidate))
                                                    (container-hash (cdr candidate)))
                                                (helm :sources (helm-build-sync-source "Access Method"
                                                                :candidates 
                                                                `(("By Name" . ,container-name)
                                                                  ("By Hash" . ,container-hash))
                                                                :action (lambda (access-method)
                                                                          (find-file (format "/docker:%s:/" access-method))))
                                                      :buffer "*helm docker access method*"))))
                         :buffer "*helm docker containers*")))
    selected))

(map! :leader
      :prefix "d"
      :desc "Access docker containers via tramp" "d" #'my/helm-docker-containers)

(setq org-use-fast-todo-selection t)

(setq telega-use-docker t)

(winner-mode +1)

(setq org-attach-directory "~/photos/attachments")

(setq org-agenda-overriding-columns-format "%100ITEM  %TODO %7EFFORT %PRIORITY     100%TAGS")

;; PRDs flow
(defun prd/create-prd-file ()
  "Create a PRD org file from the current org header, prompt for directory, and insert a link."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (error "Not in org-mode"))
  (save-excursion
    ;; Find the current org heading
    (org-back-to-heading t)
    (let* ((header (nth 4 (org-heading-components)))
           (dir "~/org/prd")
           (timestamp (format-time-string "%Y%m%d%H%M%S"))
           (sanitized-header (replace-regexp-in-string "[/\\?%*:|\"<> ]" "_" header))
           (filename (concat dir "/" timestamp "-" sanitized-header ".org")))
      ;; Create the new file with a header
      (with-temp-file filename
        (insert (format "#+title: %s\n\n" header)))
      ;; Insert a link to the new file in the current heading's content
      (org-end-of-meta-data t)
      (insert (format "\n[[file:%s][PRD: %s]]\n" filename header))
      ;; Optionally, open the new file
      (find-file-other-window filename))))


(map! :leader
      :prefix "p"
      :desc "Toggle between implementation and test" "t" #'projectile-toggle-between-implementation-and-test)

(map! :leader
      :prefix "e"
      :desc "Toggle between implementation and test" "s" #'eww-search-words )

(map! :leader
      :prefix "a"
      :desc "Run aidermacs" "a" #'aidermacs-transient-menu)

(defun my/copy-current-file-path-to-clipboard ()
  "Copy the path to the current file to the clipboard."
  (interactive)
  (let ((filename (or (buffer-file-name) default-directory)))
    (when filename
      (kill-new (expand-file-name filename))
      (message "Copied file path: %s" (expand-file-name filename)))))

(map! :leader
      :prefix "f"
      :desc "Copy current file path to clipboard" "y" #'copy-current-file-path-to-clipboard)
