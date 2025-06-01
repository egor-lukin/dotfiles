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
;; (package! org-ql :recipe (:repo "LukinEgor/org-ql" :branch "file-dynamic-blocks"))
(package! org-ql)
(package! org-mind-map)
(package! sound-wav)
(package! cider)
;; (package! helm-dash)
(package! hledger-mode)
(unpin! visual-fill-column)
(package! org-recoll :recipe (:repo "alraban/org-recoll"))
(package! ranger)
(package! ereader)
(package! nov :recipe (:repo "https://depp.brause.cc/nov.el.git"))

(package! telega :pin "ab03a5ead11e9a0abc96cae6025cd87135a71a57")
(package! magit)
(package! magit-section)

;; (package! nmcli-wifi :recipe (:repo "https://github.com/LukinEgor/nmcli-wifi"))
(package! whisper :recipe (:repo "https://github.com/natrys/whisper.el.git"))

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
(package! gptel)
;; (package! aider
;;   :recipe (:host github :repo "tninja/aider.el" :files ("aider.el")))

(package! org-fc
  :recipe (:host github
           :repo "l3kn/org-fc"
           :files ("*.el" "README.md" "awk" "docs")))

(package! org-drill)

(package! aidermacs
  :recipe (:host github
           :repo "MatthewZMD/aidermacs"))
