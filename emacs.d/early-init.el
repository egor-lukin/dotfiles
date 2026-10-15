;; -*- lexical-binding: t; -*-
;;; early-init.el --- Loaded before package init and the first frame

;;; Code:

;; Пакеты активирует init.el явно.
(setq package-enable-at-startup nil)

;; Поднять порог GC на время старта, вернуть рабочее значение после.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

;; Элементы фрейма отключаются до его отрисовки, иначе фрейм мигает.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(fullscreen . fullboth) default-frame-alist)

(setq inhibit-startup-screen t
      initial-scratch-message nil
      frame-inhibit-implied-resize t)

;;; early-init.el ends here
