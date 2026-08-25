 ;; basic settings
(setq-local outline-regexp "^\f")


 ;; basic variables
(setq workspace-dir "~/dotfiles/"
      projects-dir "~/dev/"
      org-dir "~/org/"
      emacs-dir (concat workspace-dir "doom.d/")
      user-full-name "Egor Lukin"
      user-mail-address "mail@egorlukin.me")

 ;; YaSnippets

(setq yas-snippet-dirs (list (concat org-dir "snippets") "~/emacs.d/mysnippets"))

 ;; UI settings
(setq doom-theme 'doom-monokai-pro)

(setq doom-font (font-spec :family "monospace" :size 50 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "sans" :size 50))

(setq display-line-numbers-type t)


 ;; Emacs term/shell
(setq multi-term-program-switches "--login")

(defun eshell-load-bash-aliases ()
  "Read Bash aliases and add them to the list of eshell aliases."
  ;; Bash needs to be run - temporarily - interactively
  ;; in order to get the list of aliases.
  (with-temp-buffer
    (call-process "bash" nil '(t nil) nil "-ci" "alias")
    (goto-char (point-min))
    (while (re-search-forward "alias \\(.+\\)='\\(.+\\)'$" nil t)
      (eshell/alias (match-string 1) (match-string 2)))))


 ;; GPG settings
(require 'epa-file)
(epa-file-enable)
(setq epa-file-encrypt-to user-mail-address)
(setq epg-pinentry-mode 'loopback)

(defun my/epa-dired-do-encrypt-with-same-recipients ()
  "Encrypt marked files."
  (interactive)
  (let (keys (epa-select-keys (epg-make-context) "Select recipients for encryption.
If no one is selected, symmetric encryption will be performed.  "))
    (dolist (file (dired-get-marked-files))
      (epa-encrypt-file
       (expand-file-name file)
       keys
       ))
    (revert-buffer)))

(defun my/epa-dired-do-encrypt ()
  "Encrypt marked files, selecting recipients once for all files."
  (interactive)
  (let* ((ctx (epg-make-context))
         (keys (epa-select-keys
                ctx
                "Select recipients for encryption.
If none are selected, symmetric encryption will be performed.")))
    (dolist (file (dired-get-marked-files))
      (epa-encrypt-file
       (expand-file-name file)
       keys))
    (revert-buffer)))


 ;; Org Mode / GTD
(setq org-use-fast-todo-selection t)

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

(defun hms-to-pomodoros (str)
  (cond
   ((or (null str) (string-empty-p str)) 0)
   ((and (string-prefix-p "*" str) (string-suffix-p "*" str)) (/ (hms-to-minutes (substring str 1 -1)) 25))
   (t (/ (hms-to-minutes str) 25))))

(defun hms-to-minutes (str)
  (let* ((lst (split-string str ":"))
         (hour (nth 0 lst))
         (minute (nth 1 lst)))
    (+ (* (string-to-number hour) 60)
       (string-to-number minute))))

(setq org-attach-directory "~/photos/attachments")

(setq org-agenda-overriding-columns-format "%100ITEM  %TODO %7EFFORT %PRIORITY     100%TAGS")

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

(map! :leader
      :prefix "b"
      :desc "polybar-current-clock-line" "c" #'polybar-current-clock-line)

(defun gtd/org-file-has-project-tag-p (file)
  "Return non-nil if FILE contains #+FILETAGS with :project:."
  (with-temp-buffer
    (insert-file-contents file nil 0 5000) ; read first 5000 chars, enough for header
    (goto-char (point-min))
    (re-search-forward "^#\\+FILETAGS:.*:project:" nil t)))

(after! org
  (require 'org-habit)
  (setq org-directory org-dir
        org-log-into-drawer t
        org-agenda-files (directory-files "~/org/projects/" t "\\.org\\(\\.gpg\\)?$")
        org-refile-targets '((org-agenda-files :maxlevel . 2))
        org-todo-keywords
        '((sequence "TODO" "IN-PROGRESS" "WAIT" "|" "DONE" "CLOSED"))
        org-log-done t
        org-habit-show-habits-only-for-today t
        org-habit-preceding-days 25
        org-habit-following-days 3))

(use-package org-drill
  :ensure t
  :config
  (setq org-drill-spaced-repetition-algorithm 'sm2))

(after! org
  (setq org-capture-templates
        '(("t" "Todo" entry
           (file+headline "projects/gtd.org" "Inbox")
           (file "templates/todo.org"))
          ("e" "English word" entry
           (file+headline "drill/english_words.org" "Words")
           "* %? :drill:\n[]\n")
          ("p" "Project Todo" entry
           (file+headline (lambda ()
                            (let ((file (completing-read "File: " (directory-files "~/org/projects" nil "\\.org$"))))
                              (concat "~/org/projects/" file)))
                          "Inbox")
           (file "templates/todo.org")))))

(map! :leader
      "x" #'org-capture)

(setq org-clock-persist 'history)
(org-clock-persistence-insinuate)
(setq org-clock-persist t)

(setq org-agenda-prefix-format
      '((agenda . " %i %-5:c%?-5t% s")))

 ;; Search
(setq helm-mode-fuzzy-match t)

(setq ivy-re-builders-alist
      '((counsel-ag . regexp-quote)
        (t      . ivy--regex-fuzzy)))


 ;; Google Translate Integration
(global-set-key "\C-ct" 'google-translate-at-point)
(global-set-key "\C-cr" 'google-translate-at-point-reverse)
(global-set-key "\C-cT" 'google-translate-query-translate)

(setq google-translate-default-source-language '"en"
      google-translate-default-target-language '"ru"
      google-translate-backend-method 'curl)

(use-package google-translate
  ;; :ensure t
  :custom
  (google-translate-backend-method 'curl)
  :config
   (defun google-translate--search-tkk () "Search TKK." (list 430675 2721866130)))


 ;; Eww
(setq browse-url-browser-function 'eww-browse-url)

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
        :desc "eww" "e" #'eww
        :desc "eww-list-buffers" "l" #'eww-list-buffers
        :desc "eww-search-current-line" "f" #'eww-search-current-line
        :desc "eww-copy-page-url" "y" #'eww-copy-page-url))

 ;; Elfeed
(after! elfeed
  (setq elfeed-search-filter "@1-month-ago +unread")
  (setq elfeed-db-directory "~/elfeed.db"))


 ;; OpenWith
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
             '("\\.djvu" "evince" (file))
             ))


 ;; Ledger
(setq hledger-jfile "~/org/finances/ledger.journal")
(add-to-list 'auto-mode-alist '("\\.journal\\'" . hledger-mode))


 ;; Dash docsets
(setq helm-dash-docsets-path "~/.docsets")
(setq dash-docs-docsets-path "~/.docsets")

(map! :leader
      :prefix "l"
      :desc "helm-dash-at-point" "p" #'helm-dash-at-point
      :desc "helm-dash" "f" #'helm-dash)

 ;; Whisper
(use-package whisper
  :bind ("C-h r" . whisper-run)
  :config
  (setq whisper-install-directory "~/dev/whisper.cpp"
        whisper-model "base"
        whisper-language "en"
        whisper-translate nil))


 ;; Docker
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



 ;; Telega
(setq telega-use-docker t)

 ;; Projectile
(setq projectile-project-search-path '("~/dev"))

(map! :leader
      :prefix "p"
      :desc "Toggle between implementation and test" "t" #'projectile-toggle-between-implementation-and-test)

(map! :leader
      :prefix "e"
      :desc "Toggle between implementation and test" "s" #'eww-search-words )


 ;; K8s
(map! :leader
      :prefix "k"
      :desc "Kubernetes overview" "o" #'kubernetes-overview
      :desc "Kubernetes set namespace" "n" #'kubernetes-set-namespace
      :desc "Kubernetes exec into" "e" #'kubernetes-exec-into
      :desc "Kubernetes context" "c" #'kubernetes-context)


 ;; Rspec
(map! :leader
      :prefix "["
      :desc "rspec-toggle-spec-and-target" "t" #'rspec-toggle-spec-and-target
      :desc "rspec-verify" "v" #'rspec-verify
      :desc "rspec-verify-all" "a" #'rspec-verify-all
      :desc "rspec-rerun" "r" #'rspec-rerun
      :desc "rspec-verify-single" "s" #'rspec-verify-single)


 ;; Gptel

(use-package! gptel
  :config
  (setq gptel-default-mode 'org-mode
        gptel-model 'deepseek/deepseek-v4-flash)

 (gptel-make-ollama "Ollama"
   :host "localhost:11434"
   :stream t
   :models '((gemma4:e2b :capabilities (media tool-use) :mime-types ("image/jpeg"))
             (hf.co/unsloth/gemma-4-E2B-it-qat-mobile-GGUF:UD-Q2_K_XL :capabilities (media tool-use) :mime-types ("image/jpeg"))))

 (gptel-make-openai "OpenRouter"
   :host "openrouter.ai"
   :endpoint "/api/v1/chat/completions"
   :stream t
   :key (lambda () (password-store-get "env/OPENROUTER_API_KEY"))
   :models '(openai/gpt-3.5-turbo
             z-ai/glm-5
             openai/gpt-5.1-chat
             openai/gpt-oss-120b
             qwen/qwen3.6-plus
             google/gemma-4-26b-a4b-it
             google/gemma-4-26b-a4b-it:free
             (google/gemma-4-26b-a4b-it :capabilities (media tool-use) :mime-types ("image/jpeg"))
             deepseek/deepseek-v4-flash
             deepseek/deepseek-v4-pro)))

(setq gptel-default-mode 'org-mode
      gptel-model 'deepseek/deepseek-v4-flash)

(gptel-make-preset 'assistant
  :description "Universal assistant"
  :backend "OpenRouter"
  :model 'deepseek/deepseek-v4-flash
  :use-context 'system
  :context '("~/org/prompts/assistant.org")
  :temperature 0.0)

(gptel-make-preset 'english-cards
  :description "Preset for generating english cards"
  :backend "OpenRouter"
  :model 'deepseek/deepseek-v4-flash
  :use-context 'system
  :context '("~/org/prompts/english-words.org")
  :temperature 0.1)

(defmacro gptel-make-safe-tool (&rest args)
  "Wrap a gptel tool function with error handling."
  (let ((name (plist-get args :name))
        (fn   (plist-get args :function)))
    `(gptel-make-tool
      ,@args
      :function
      (lambda (&rest tool-args)
        (condition-case err
            (apply ,fn tool-args)
          (error
           (let ((msg (format "Tool error (%s): %s"
                              ,name
                              (error-message-string err))))
             (message "[gptel] %s" msg)
             msg)))))))

(defun find-train-tickets (from to date)
  (let ((default-directory (expand-file-name "~/dotfiles")))
    (with-output-to-string
      (with-current-buffer standard-output
        (call-process
         "bash" nil t nil
         "-lc"
         (format "bun run tools/search_trains.ts --from %s --to %s --date %s"
                 (shell-quote-argument from)
                 (shell-quote-argument to)
                 (shell-quote-argument date)))))))

(gptel-make-safe-tool
 :name "search_trains"
 :description "Search trains between two cities for a given date (use only english naming for cities or Saint Peterburg -> Sankt-Peterburg, Moscow -> Moskva for this cities)"
 :function
 (lambda (from to date)
   (find-train-tickets from to date))
 :args (list
        '(:name "from"
          :type string
          :description "Departure city")
        '(:name "to"
          :type string
          :description "Arrival city")
        '(:name "date"
          :type string
          :description "Travel date in DD.MM.YYYY format"))
 :category "travel")

(defun my/gptel-rewrite-buffer ()
  "Select the entire buffer and call gptel-rewrite on it."
  (interactive)
  (save-excursion
    (mark-whole-buffer)
    (call-interactively #'gptel-rewrite)))

(map! :leader
      :prefix "a"
      :desc "Gptel" "g" #'gptel
      :desc "Gptel menu" "m" #'gptel-menu
      :desc "Gptel send" "s" #'gptel-send
      :desc "Gptel add" "a" #'gptel-add
      :desc "Gptel add file" "f" #'gptel-add-file
      :desc "Gptel abort" "o" #'gptel-abort
      :desc "Gptel rewrite" "r" #'gptel-rewrite
      :desc "Gptel clean context" "c" #'gptel-context-remove-all
      :desc "Gptel rewrite buffer" "b" #'my/gptel-rewrite-buffer)

(use-package ob-gptel
  :hook ((org-mode . ob-gptel-install-completions))
  :defines ob-gptel-install-completions
  :config
  (add-to-list 'org-babel-load-languages '(gptel . t))
  ;; Optional, for better completion-at-point
  (defun ob-gptel-install-completions ()
    (add-hook 'completion-at-point-functions
              'ob-gptel-capf nil t)))

 ;; World Clock
(setq world-clock-list
      '(("UTC" "UTC")
        ("Etc/GMT-3" "+3 UTC")
        ("Etc/GMT-4" "+4 UTC"))
      world-clock-time-format "%a %d %b %R %Z")

 ;; Makefile
(map! :leader
      :prefix "m"
      :desc "makefile-executor-execute-project-target" "p" #'makefile-executor-execute-project-target)
 ;; extra
(unpin! visual-fill-column)

(winner-mode +1)

(map! :leader
      :prefix "b"
      :desc "list-bookmarks" "l" #'list-bookmarks
      :desc "bookmark-delete" "d" #'bookmark-delete
      :desc "bookmark-set" "s" #'bookmark-set)

(with-eval-after-load 'company
  (define-key company-mode-map (kbd "<tab>") 'company-complete))

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


(org-babel-do-load-languages
 'org-babel-load-languages
 '((http . t)))

(defun my-break-location-copy ()
  "Copy break file_path:line_number to clipboard."
  (interactive)
  (let ((text (my-break-location)))
    (kill-new text)
    (message "Copied: %s" text)))

(defun my-break-location ()
  "Generate string: break file_path:line_number"
  (interactive)
  (let* ((file (or (buffer-file-name) ""))
         (project-root (when (fboundp 'project-current)
                         (when-let ((proj (project-current)))
                           (project-root proj))))
         (relative-file (if project-root
                            (file-relative-name file project-root)
                          file))
         (line (line-number-at-pos))
         (result (format "break %s:%d" relative-file line)))
    (if (called-interactively-p 'any)
        (message "%s" result)
      result)))

(setq auto-save-visited-interval 5)
(setq auto-save-visited-predicate (lambda () (derived-mode-p 'org-mode)))
(auto-save-visited-mode 1)

(toggle-frame-fullscreen)

(require 'acp)
(require 'agent-shell)

(setq x-super-keysym 'meta)

(global-auto-revert-mode 1)


 ;; load additonal scripts
(add-to-list 'load-path "../lisp/org-mobile-mode")

(if (getenv "TERMUX_VERSION")
    (load-file (expand-file-name "mobile.el" emacs-dir))
    (load-file (expand-file-name "desktop.el" emacs-dir)))


 ;; Denote

;;(info "(denote) Sample configuration")
(use-package denote
  :ensure t
  :hook (dired-mode . denote-dired-mode)
  :config
  (setq
   denote-directory (expand-file-name "~/org/")
   denote-prompts '(title keywords subdirectory))
  (denote-rename-buffer-mode 1))

(map! :leader
      :prefix "d"
      :desc "denote" "n" #'denote
      :desc "denote-link-after-creating" "i" #'denote-link-after-creating
      :desc "denote-journal-new-or-existing-entry" "j" #'denote-journal-new-or-existing-entry
      :desc "denote-open-or-create" "f" #'denote-open-or-create)

(use-package denote-journal
  :ensure t
  :commands (denote-journal-new-entry
             denote-journal-new-or-existing-entry
             denote-journal-link-or-create-entry)
  :hook (calendar-mode . denote-journal-calendar-mode)
  :config
  (setq denote-journal-directory
        (expand-file-name "journal" denote-directory))
  (setq denote-journal-keyword "journal")
  (setq denote-journal-title-format "%Y-%m-%d"))

(with-eval-after-load 'org-capture
  (setq org-capture-templates
        (append
         '(("n" "new note (via denote)" plain
            (file denote-last-path)
            (function
             (lambda ()
               (let ((denote-use-directory (read-directory-name "Subdirectory: " (denote-directory))))
                 (denote-org-capture))))
            :no-save t
            :immediate-finish nil
            :kill-buffer t
            :jump-to-captured t)
           ("b" "temp daily note" entry
            (file+headline (lambda () (denote-journal-path-to-new-or-existing-entry)) "buffer")
            (file "templates/buffer.org")))
         org-capture-templates)))
