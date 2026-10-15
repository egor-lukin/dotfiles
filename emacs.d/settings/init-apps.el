;; -*- lexical-binding: t; -*-
(require 'init-core)
(require 'init-keys)


;; External links go to the system browser; eww stays available on demand
;; (`C-u' before a link-following command, plus the SPC e bindings below).
(setq browse-url-browser-function #'browse-url-default-browser
      browse-url-secondary-browser-function #'eww-browse-url)

(el-leader!
  "e"   '(:ignore t :which-key "eww")
  "e e" '(eww :which-key "eww")
  "e l" '(eww-list-buffers :which-key "list buffers")
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

;; (use-package telega
;;   :commands (telega)
;;   :config (setq telega-use-docker t))


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


(provide 'init-apps)
