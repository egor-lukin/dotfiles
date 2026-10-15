(when (not (getenv "TERMUX_VERSION"))
  (package! xclip))

(package! tramp-term)
(package! google-translate :pin "6f7b75b2aa1ff4e50b6f1579cafddafae5705dbd")
(package! nov :recipe (:repo "https://depp.brause.cc/nov.el.git"))

(package! telega)

(package! ob-async)

(package! gptel
  :recipe (:repo "karthink/gptel"
           :branch "master" ))

(package! org-drill)

(package! acp)
(package! agent-shell)
(package! gptel-agent)

(package! denote)
(package! denote-journal)
