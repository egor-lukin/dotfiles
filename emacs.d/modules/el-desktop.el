;; -*- lexical-binding: t; -*-
;;; el-desktop.el --- Desktop-only settings

;;; Code:

(require 'el-core)

(use-package xclip
  :demand t
  :config (xclip-mode 1))

(provide 'el-desktop)
;;; el-desktop.el ends here
