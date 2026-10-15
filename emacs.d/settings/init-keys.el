;; -*- lexical-binding: t; -*-

(require 'init-core)

(use-package evil
  :init
  (setq evil-want-keybinding nil
        evil-want-integration t
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo
        evil-split-window-below t
        evil-vsplit-window-right t)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))


(with-eval-after-load 'evil
  (evil-define-operator el-comment-or-uncomment (beg end)
    "Toggle comments between BEG and END."
    :move-point nil
    (comment-or-uncomment-region beg end))

  (evil-define-key '(normal visual) 'global
    "gc" #'el-comment-or-uncomment))


(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-org
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))


(use-package general
  :demand t
  :config
  (general-create-definer el-leader!
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC"
    :prefix-command 'el-leader-prefix-command
    :prefix-map 'el-leader-map))

(which-key-mode 1)
(setq which-key-idle-delay 0.3)

(el-leader!
  "SPC" '(project-find-file :which-key "find file in project")
  ":"   '(execute-extended-command :which-key "M-x")
  "/"   '(consult-ripgrep :which-key "search project")
  ","   '(consult-buffer :which-key "switch buffer")
  "u"   '(universal-argument :which-key "universal arg")
  "."   '(dired-jump :which-key "dired jump")

  "f"   '(:ignore t :which-key "file")
  "f f" '(find-file :which-key "find file")
  "f s" '(save-buffer :which-key "save")
  "f S" '(write-file :which-key "save as")
  "f r" '(recentf-open-files :which-key "recent")

  "b"   '(:ignore t :which-key "buffer/bookmark")
  "b b" '(consult-buffer :which-key "switch buffer")
  "b k" '(kill-current-buffer :which-key "kill buffer")
  "b r" '(revert-buffer :which-key "revert")

  "w"   '(:keymap evil-window-map :which-key "window")
  "h"   '(:keymap help-map :which-key "help")

  "s"   '(:ignore t :which-key "search")
  "s s" '(consult-line :which-key "line")
  "s p" '(consult-ripgrep :which-key "project")
  "s d" '(consult-fd :which-key "find file by name")

  "t"   '(:ignore t :which-key "toggle")
  "t l" '(display-line-numbers-mode :which-key "line numbers")
  "t w" '(visual-line-mode :which-key "visual line")

  "q"   '(:ignore t :which-key "quit")
  "q q" '(save-buffers-kill-terminal :which-key "quit")
  "q r" '(restart-emacs :which-key "restart"))


(unless (termux-p)
  (setq x-super-keysym 'meta))

(provide 'init-keys)
