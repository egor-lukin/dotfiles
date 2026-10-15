;; -*- lexical-binding: t; -*-
;;; el-ai.el --- gptel, agent shell and LLM tools

;;; Code:

(require 'init-core)
(require 'init-keys)

(use-package gptel
  :vc (:url "https://github.com/karthink/gptel.git" :branch "master" :rev :newest)
  :commands (gptel gptel-menu gptel-send gptel-rewrite)
  :config
  (setq gptel-default-mode 'org-mode
        gptel-model 'openrouter/free)

  (gptel-make-ollama "Ollama"
    :host "localhost:11434"
    :stream t
    :models '((gemma4:e2b :capabilities (media tool-use) :mime-types ("image/jpeg"))
              (hf.co/unsloth/gemma-4-E2B-it-qat-mobile-GGUF:UD-Q2_K_XL
               :capabilities (media tool-use) :mime-types ("image/jpeg"))))

  (gptel-make-openai "OpenRouter"
    :host "openrouter.ai"
    :endpoint "/api/v1/chat/completions"
    :stream t
    :key (lambda () (password-store-get "env/OPENROUTER_API_KEY"))
    :models '((openrouter/free :capabilities (media tool-use))
              openai/gpt-3.5-turbo
              z-ai/glm-5
              openai/gpt-5.1-chat
              openai/gpt-oss-120b
              qwen/qwen3.6-plus
              google/gemma-4-26b-a4b-it
              google/gemma-4-26b-a4b-it:free
              (google/gemma-4-26b-a4b-it
               :capabilities (media tool-use) :mime-types ("image/jpeg"))
              deepseek/deepseek-v4-flash
              deepseek/deepseek-v4-pro))

  (gptel-make-preset 'assistant
    :description "Universal assistant"
    :backend "OpenRouter"
    :model 'openrouter/free
    :use-context 'system
    :context (list (expand-file-name "prompts/assistant.org" org-dir))
    :temperature 0.0)

  (gptel-make-preset 'english-cards
    :description "Preset for generating english cards"
    :backend "OpenRouter"
    :model 'openrouter/free
    :use-context 'system
    :context (list (expand-file-name "prompts/english-words.org" org-dir))
    :temperature 0.1))


;;;; Тулы

(defmacro gptel-make-safe-tool (&rest args)
  "Define a gptel tool from ARGS whose function never signals.
Ошибка тула превращается в текст для модели, иначе один сбойный вызов
обрывает весь диалог."
  (let ((name (plist-get args :name))
        (fn   (plist-get args :function)))
    `(gptel-make-tool
      ,@args
      :function
      (lambda (&rest tool-args)
        (condition-case err
            (apply ,fn tool-args)
          (error
           (let ((msg (format "Tool error (%s): %s"
                              ,name (error-message-string err))))
             (message "[gptel] %s" msg)
             msg)))))))

(defun el-ai-find-train-tickets (from to date)
  "Return the output of the train search script for FROM, TO and DATE."
  (let ((default-directory workspace-dir))
    (with-output-to-string
      (with-current-buffer standard-output
        (call-process
         "bash" nil t nil "-lc"
         (format "bun run scripts/search_trains.ts --from %s --to %s --date %s"
                 (shell-quote-argument from)
                 (shell-quote-argument to)
                 (shell-quote-argument date)))))))

(with-eval-after-load 'gptel
  (gptel-make-safe-tool
   :name "search_trains"
   :description "Search trains between two cities for a given date (use only english naming for cities or Saint Peterburg -> Sankt-Peterburg, Moscow -> Moskva for this cities)"
   :function (lambda (from to date) (el-ai-find-train-tickets from to date))
   :args (list '(:name "from" :type string :description "Departure city")
               '(:name "to" :type string :description "Arrival city")
               '(:name "date" :type string
                 :description "Travel date in DD.MM.YYYY format"))
   :category "travel"))

(defun el-ai-rewrite-buffer ()
  "Select the whole buffer and call `gptel-rewrite' on it."
  (interactive)
  (save-excursion
    (mark-whole-buffer)
    (call-interactively #'gptel-rewrite)))


;;;; Agent shell

(use-package acp
  :vc (:url "https://github.com/xenodium/acp.el.git" :rev :newest)
  :demand t)

(use-package agent-shell
  :vc (:url "https://github.com/xenodium/agent-shell.git" :rev :newest)
  :after acp
  :demand t)

(use-package gptel-agent
  :vc (:url "https://github.com/karthink/gptel-agent.git" :rev :newest)
  :after gptel)


;;;; Биндинги

(el-leader!
  "a"   '(:ignore t :which-key "ai")
  "a g" '(gptel :which-key "gptel")
  "a m" '(gptel-menu :which-key "menu")
  "a s" '(gptel-send :which-key "send")
  "a a" '(gptel-add :which-key "add context")
  "a f" '(gptel-add-file :which-key "add file")
  "a o" '(gptel-abort :which-key "abort")
  "a r" '(gptel-rewrite :which-key "rewrite")
  "a c" '(gptel-context-remove-all :which-key "clear context")
  "a b" '(el-ai-rewrite-buffer :which-key "rewrite buffer")
  "a t" '(agent-shell :which-key "agent shell"))

(provide 'init-ai)
;;; ai.el ends here
