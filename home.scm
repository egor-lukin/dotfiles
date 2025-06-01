;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

;; To install python, add "python" to the packages list below.
(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (gnu home services)
             (guix gexp)
             (gnu home services shells))

(home-environment
  ;; Below is the list of packages that will show up in your
  ;; Home profile, under ~/.guix-home/profile.
  (packages (specifications->packages (list "glibc-locales" "ruby" "python")))

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services
   (list
    (service home-bash-service-type
             (home-bash-configuration
              (aliases '())
              (bashrc (list (local-file "/home/azx/dotfiles/.bashrc"
                                        "bashrc")))
              (bash-logout (list (local-file
                                  "/home/azx/dotfiles/.bash_logout"
                                  "bash_logout")))))
    (simple-service 'aider.conf.yml
                   home-files-service-type
                   (list
                    `(".aider.conf.yml" ,(local-file "/home/azx/dotfiles/aider.conf.yml"))))
    )))
