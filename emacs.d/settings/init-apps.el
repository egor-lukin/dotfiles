;; -*- lexical-binding: t; -*-
;;; el-apps.el --- Browser, feeds, chat, books, translation, finances, pdf

;;; Code:

(require 'init-core)
(require 'init-keys)


;;;; Браузер

(setq browse-url-browser-function #'eww-browse-url)

(defun el-eww-search-current-line ()
  "Trim the current line, select it and search the web for it with eww."
  (interactive)
  (let* ((start (line-beginning-position))
         (end (line-end-position))
         (trimmed (string-trim (buffer-substring-no-properties start end))))
    (delete-region start end)
    (insert trimmed)
    (set-mark (point))
    (goto-char start)
    (eww-search-words)))

(el-leader!
  "e"   '(:ignore t :which-key "eww")
  "e e" '(eww :which-key "eww")
  "e l" '(eww-list-buffers :which-key "list buffers")
  "e f" '(el-eww-search-current-line :which-key "search current line")
  "e s" '(eww-search-words :which-key "search words")
  "e y" '(eww-copy-page-url :which-key "copy url"))


(use-package elfeed
  :commands (elfeed)
  :config
  (setq elfeed-search-filter "@1-month-ago +unread"
        elfeed-db-directory (expand-file-name "~/elfeed.db")))

(use-package elfeed-org
  :vc (:url "https://github.com/remyhonig/elfeed-org.git" :rev :newest)
  :after elfeed
  :demand t
  :config
  (setq rmh-elfeed-org-files (list (expand-file-name "elfeed.org" org-dir)))
  (elfeed-org))


(use-package telega
  :commands (telega)
  :config (setq telega-use-docker t))


(use-package nov
  :vc (:url "https://depp.brause.cc/nov.el.git" :rev :newest)
  :mode ("\\.epub\\'" . nov-mode))


(use-package google-translate
  :vc (:url "https://github.com/atykhonov/google-translate.git"
       :rev "6f7b75b2aa1ff4e50b6f1579cafddafae5705dbd")
  :demand t
  :bind (("C-c t" . google-translate-at-point)
         ("C-c r" . google-translate-at-point-reverse)
         ("C-c T" . google-translate-query-translate))
  :config
  (setq google-translate-default-source-language "en"
        google-translate-default-target-language "ru"
        google-translate-backend-method 'curl)
  (defun google-translate--search-tkk ()
    "Search TKK."
    (list 430675 2721866130)))


(use-package hledger-mode
  :vc (:url "https://github.com/narendraj9/hledger-mode.git" :rev :newest)
  :mode ("\\.journal\\'" . hledger-mode)
  :config
  (setq hledger-jfile (expand-file-name "finances/ledger.journal" org-dir)))


(use-package pdf-tools
  :unless (termux-p)
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config (pdf-tools-install :no-query))


(el-leader!
  "o c" '(calendar :which-key "calendar")
  "o r" '(elfeed :which-key "rss")
  "o g" '(telega :which-key "telegram"))

(provide 'init-apps)
;;; el-apps.el ends here
