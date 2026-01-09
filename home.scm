(use-modules (gnu home)
             (gnu packages)
             (guix profiles)
             (gnu services)
             (gnu home services)
             (guix gexp)
             (gnu home services shells))

(home-environment
  (packages (specifications->packages (list "glibc-locales"
                                            "ruby"
                                            "python"
                                            "libyaml"
                                            "openssl"
                                            "node")))

  (services
   (list
    (service home-bash-service-type
             (home-bash-configuration
              (aliases '())
              (bashrc (list (local-file ".bashrc"
                                        "bashrc")))
              (bash-logout (list (local-file
                                  ".bash_logout"
                                  "bash_logout")))))
    (simple-service 'ld-library-path
                    home-environment-variables-service-type
                    '(("LD_LIBRARY_PATH" . "$HOME/.guix-home/profile/lib")))
    (simple-service 'aider.conf.yml
                   home-files-service-type
                   (list
                    `(".aider.conf.yml" ,(local-file "aider.conf.yml"))))
    )))
