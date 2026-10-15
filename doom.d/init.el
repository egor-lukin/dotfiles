(doom! :input
       :completion
       company           ; the ultimate code completion backend
       helm              ; the *other* search engine for love and life
       ;; ido               ; the other *other* search engine...
       ;; ivy               ; a search engine for love and life

       :ui
       doom              ; what makes DOOM look the way it does
       workspaces        ; tab emulation, persistence & separate workspaces
       zen               ; distraction-free coding or writing

       :editor
       (evil +everywhere); come to the dark side, we have cookies
       fold              ; (nigh) universal code folding
       snippets          ; my elves. They type so I don't have to

       :emacs
       dired             ; making dired pretty [functional]
       ;; electric          ; smarter, keyword-based electric-indent
       ;; ibuffer           ; interactive buffer management
       ;; vc                ; version-control and Emacs, sitting in a tree

       :term
       eshell            ; a consistent, cross-platform shell (WIP)
       vterm             ; another terminals in Emacs

       :checkers
       ;; syntax              ; tasing you for every semicolon you forget
       ;; spell             ; tasing you for misspelling mispelling
       ;; grammar           ; tasing grammar mistake every you make

       :tools
       ;; ansible
       ;;debugger          ; FIXME stepping through code, to help you add bugs
       ;;direnv
       ;; docker
       ;;editorconfig      ; let someone else argue about tabs vs spaces
       ;; ein               ; tame Jupyter notebooks with emacs
       ;; (eval +overlay)     ; run code, run (also, repls)
       ;;gist              ; interacting with github gists
       (lookup           ; helps you navigate your code and documentation
        +docsets)        ; ...or in Dash docsets locally
       ;;lsp
       ;;macos             ; MacOS-specific commands
       magit             ; a git porcelain for Emacs
       make              ; run make tasks from Emacs
       pass              ; password manager for nerds
       pdf               ; pdf enhancements
       ;;prodigy           ; FIXME managing external services & code builders
       ;;rgb               ; creating color strings
       ;; terraform         ; infrastructure as code
       ;;tmux              ; an API for interacting with tmux
       ;;upload            ; map local to remote projects via ssh/ftp

       :lang
       ;;agda              ; types of types of types of types...
       ;;assembly          ; assembly for fun or debugging
       ;; cc                ; C/C++/Obj-C madness
       ;; clojure           ; java with a lisp
       ;;common-lisp       ; if you've seen one lisp, you've seen them all
       ;;coq               ; proofs-as-programs
       ;; crystal           ; ruby at the speed of c
       ;;csharp            ; unity, .NET, and mono shenanigans
       ;; data              ; config/data formats
       ;; elixir            ; erlang done right
       ;;elm               ; care for a cup of TEA?
       ;; emacs-lisp        ; drown in parentheses
       ;;erlang            ; an elegant language for a more civilized age
       ;;ess               ; emacs speaks statistics
       ;;faust             ; dsp, but you get to keep your soul
       ;;fsharp           ; ML stands for Microsoft's Language
       ;;fstar             ; (dependent) types and (monadic) effects and Z3
       ;; go                ; the hipster dialect
       ;;(haskell +dante)  ; a language that's lazier than I am
       ;;hy                ; readability of scheme w/ speed of python
       ;;idris             ;
       ;;(java +meghanada) ; the poster child for carpal tunnel syndrome
       ;; javascript        ; all(hope(abandon(ye(who(enter(here))))))
       ;;julia             ; a better, faster MATLAB
       ;;kotlin            ; a better, slicker Java(Script)
       ;; latex             ; writing papers in Emacs has never been so fun
       ;;lean
       ;;factor
       ;; ledger            ; an accounting system in Emacs
       ;;lua               ; one-based indices? one-based indices
       markdown          ; writing docs for people to ignore
       ;;nim               ; python + lisp at the speed of c
       ;;nix               ; I hereby declare "nix geht mehr!"
       ;;ocaml             ; an objective camel
       (org              ; organize your plain life in plain text
        +pomodoro)        ; be fruitful with the tomato technique)
                          ; using org-mode for presentations
       ;;perl              ; write code no one else can comprehend
       ;;php               ; perl's insecure younger brother
       ;;plantuml          ; diagrams for confusing people more
       ;;purescript        ; javascript, but functional
       ;; python            ; beautiful is better than ugly
       ;;qt                ; the 'cutest' gui framework ever
       ;;racket            ; a DSL for DSLs
       ;;rest              ; Emacs as a REST client
       ;;rst               ; ReST in peace
       ;; ruby              ; 1.step {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
       ;;rust              ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
       ;;scala             ; java, but good
       ;;scheme            ; a fully conniving family of lisps
       ;; sh                ; she sells {ba,z,fi}sh shells on the C xor
       ;;solidity          ; do you need a blockchain? No.
       ;;swift             ; who asked for emoji variables?
       ;;terra             ; Earth and Moon in alignment for performance.
       ;; web               ; the tubes

       :email
       (mu4e +gmail)
       ;;notmuch
       ;;(wanderlust +gmail)

       :app
       calendar
       ;;irc               ; how neckbeards socialize
       (rss +org)        ; emacs as an RSS reader
       ;;twitter           ; twitter client https://twitter.com/vnought

       :config
       ;literate
       (default +bindings +smartparens))
