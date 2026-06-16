(setq org-agenda-prefix-format
      '((agenda . " ")))

(display-line-numbers-mode -1)

(require 'org-mobile-mode)
(add-hook 'org-mode-hook #'org-mobile-mode)
