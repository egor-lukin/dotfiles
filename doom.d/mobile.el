(setq org-agenda-prefix-format
      '((agenda . " ")))

(setq display-line-numbers-type nil)
(remove-hook! '(prog-mode-hook text-mode-hook conf-mode-hook)
              #'display-line-numbers-mode)

(require 'org-mobile-mode)
(add-hook 'org-mode-hook #'org-mobile-mode)

(setq org-roam-node-display-template
      "${title:80}")
