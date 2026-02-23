(when (not (getenv "TERMUX_VERSION"))
  (package! xclip))

(package! anki-editor)
(package! tramp-term)
(package! google-translate :pin "6f7b75b2aa1ff4e50b6f1579cafddafae5705dbd")
(package! add-node-modules-path)
(package! prettier-js)
(package! eslint-fix)
(package! tide)
(package! zeal-at-point)
(package! dionysos)
(package! xterm-color)
(package! org-download)
(package! company-tabnine)
(package! graphviz-dot-mode)
(package! kubernetes-evil)
(package! org-ql)
(package! org-mind-map)
(package! sound-wav)
(package! cider)
(package! hledger-mode)
(package! org-recoll :recipe (:repo "alraban/org-recoll"))
(package! ranger)
(package! ereader)
(package! nov :recipe (:repo "https://depp.brause.cc/nov.el.git"))

(package! telega)
(package! magit)
(package! magit-section)

;; (package! nmcli-wifi :recipe (:repo "https://github.com/LukinEgor/nmcli-wifi"))
(package! whisper :recipe (:repo "natrys/whisper.el"))

(package! helm-tramp)
(package! openwith)
(package! org-auto-tangle)
(package! exec-path-from-shell)
(package! ob-async)

(package! org-ai
  :pin "5adfde1bc7db9026747fbfae4c154eeac4ef8e59"
  :recipe (:host github
           :repo "rksm/org-ai"
           :files ("*.el" "README.md" "snippets")))

(package! ellama)
(package! gptel
  :recipe (:repo "karthink/gptel"
           :branch "master" ))

(package! org-fc
  :recipe (:host github
           :repo "l3kn/org-fc"
           :files ("*.el" "README.md" "awk" "docs")))

(package! org-drill)
(package! ob-http)

(package! aidermacs
  :pin "8ce3d8c"
  :recipe (:host github
           :repo "MatthewZMD/aidermacs"))

(package! ob-gptel
  :recipe (:host github
           :branch "main"
           :repo "jwiegley/ob-gptel"))
