# Vanilla Emacs Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Перенести конфигурацию Doom Emacs из `dotfiles/doom.d/` в vanilla-конфиг `dotfiles/emacs.d/` так, чтобы ежедневные сценарии (org/GTD, denote, gptel, magit, elfeed, vterm) работали без Doom, при этом Doom оставался запускаемым до и после миграции.

**Architecture:** Тонкий `init.el` только с bootstrap и порядком загрузки; предметная конфигурация в `modules/el-*.el`, каждый с `provide`; чистая логика, которую можно тестировать без установки пакетов, вынесена в `lib/el-*.el` и покрыта ERT. Каждый `require` модуля изолирован: сбой записывается в `el-failed-modules`, остальные модули грузятся дальше. Весь период миграции новый конфиг запускается параллельно живому Doom через `--init-directory`.

**Tech Stack:** Emacs 31.0.50, встроенный `package.el` + `use-package` (с `:vc` для git-рецептов), `evil` + `evil-collection` + `general.el`, `vertico`/`orderless`/`marginalia`/`consult`/`embark`, `corfu`/`cape`, встроенный `project.el`, ERT для тестов.

**Spec:** [docs/superpowers/specs/2026-10-15-vanilla-emacs-migration-design.md](../specs/2026-10-15-vanilla-emacs-migration-design.md)

## Global Constraints

- Emacs 31.0.50 — минимальная целевая версия; можно опираться на встроенные `use-package`, `which-key`, `restart-emacs`, `tramp-container` (`/docker:`), `--init-directory`.
- Менеджер пакетов — только встроенный `package.el` + `use-package`; `straight.el`, `elpaca`, `quelpa` не используются.
- `use-package-always-ensure t`; git-источники только через `:vc`.
- Префикс всех собственных символов — `el-`; приватные — `el-<area>--<name>`.
- Все файлы конфига начинаются с `;; -*- lexical-binding: t; -*-`.
- `doom.d/` не изменяется, не переименовывается и не удаляется ни на одном этапе. Симлинк `~/.config/doom → ~/dotfiles/doom.d/` остаётся на месте.
- `~/.config/emacs` до задачи 13 не трогается: весь новый конфиг запускается через `--init-directory ~/dotfiles/emacs.d`.
- Локальные пакеты остаются в `dotfiles/lisp/`; путь к ним строится от `workspace-dir`.
- Рантайм-файлы Emacs не попадают в git: `emacs.d/elpa/`, `emacs.d/var/`, `emacs.d/etc/`, `emacs.d/eln-cache/` в `.gitignore`.
- Имя пользователя и почта: `Egor Lukin`, `mail@egorlukin.me`.
- Выброшенное осознанно перечислено в спеке (раздел «Выброшено осознанно») — не переносить и не «дописывать по дороге».

## Review Focus

Входные условия, которые спека подразумевает, но ни один «счастливый путь» не проверяет:

1. **`~/org/projects/` отсутствует или переименован** → `directory-files` сигналит `file-missing`, и `el-org` не загружается целиком (та же мина есть в текущем `config.el`). Тест в задаче 6.
2. **`hms-to-minutes` получает строку без двоеточия** (`"90"`) или мусор → `string-to-number` на `nil` сигналит ошибку прямо в формуле org-таблицы в `~/org/tasks/`. Тест в задаче 6.
3. **Модуль требуется повторно или сбойный модуль требуется дважды** → дубли в `el-failed-modules` и повторная регистрация биндингов. Тест в задаче 1.
4. **Запуск под Termux**, где нет X11 → `x-super-keysym`, `xclip`, fullscreen и pdf-tools не должны исполняться. Проверка в задачах 3 и 12 запуском smoke с `TERMUX_VERSION=1`.
5. **`denote-journal` на старте** → `denote-journal-path-to-new-or-existing-entry` создаёт файл журнала как побочный эффект загрузки конфига, то есть каждый запуск Emacs плодит пустую запись. Проверка в задаче 7 подсчётом файлов в `~/org/journal/` до и после трёх запусков.

---

## File Structure

```
emacs.d/
  Makefile              # цели test / smoke / smoke-termux
  early-init.el         # GC, фрейм, package-enable-at-startup nil
  init.el               # package.el, use-package, load-path, порядок модулей
  lib/
    el-boot.el          # el-require-module, el-failed-modules
    el-clock.el         # hms-to-minutes, hms-to-pomodoros, формат строки polybar
    el-docker.el        # разбор вывода docker ps
    el-project.el       # impl<->test пути, break-location, файловые команды
  modules/
    el-core.el          # пути, личные данные, gpg, autosave, autorevert, winner
    el-keys.el          # evil, general, el-leader!, ядро словаря
    el-completion.el    # vertico/orderless/marginalia/consult/embark/corfu/cape
    el-ui.el            # тема, modeline, шрифты, номера строк, zen, world-clock
    el-org.el           # org, habit, agenda, clock, capture, drill, babel
    el-denote.el        # denote, denote-journal, denote-extras
    el-ai.el            # gptel, acp, agent-shell, gptel-agent
    el-tools.el         # magit, vterm, eshell, project, pass, docker, dired, snippets
    el-apps.el          # eww, elfeed(+elfeed-org), telega, nov, translate, hledger, pdf
    el-local.el         # require пяти пакетов из dotfiles/lisp/
    el-mobile.el        # правки под Termux
    el-desktop.el       # xclip
  snippets/             # замена ~/emacs.d/mysnippets
  tests/
    el-boot-test.el
    el-clock-test.el
    el-docker-test.el
    el-project-test.el
```

Разделение `lib/` и `modules/`: файлы в `lib/` не содержат `use-package` и не тянут внешних пакетов, поэтому ERT грузит их через `emacs -Q -batch -L lib` без сети и без установки чего-либо. Файлы в `modules/` — это проводка: `use-package`, `setq`, хуки, биндинги; они проверяются батч-стартом целого конфига. Это уточнение к структуре из спеки, сделанное ради тестируемости: спека перечисляла только `modules/`.

---

## Task 1: Каркас загрузки и тестовая оснастка

**Files:**
- Create: `emacs.d/lib/el-boot.el`
- Create: `emacs.d/tests/el-boot-test.el`
- Create: `emacs.d/early-init.el`
- Create: `emacs.d/init.el`
- Create: `emacs.d/Makefile`
- Create: `emacs.d/snippets/.gitkeep`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: ничего.
- Produces:
  - `el-failed-modules` — список `(SYMBOL . STRING)`, пополняется при сбоях загрузки.
  - `(el-require-module SYMBOL)` → `SYMBOL` при успехе, `nil` при сбое.
  - `(el-require-modules &rest SYMBOLS)` → список успешно загруженных символов, в порядке запроса.
  - `make test`, `make smoke`, `make smoke-termux` в каталоге `emacs.d/`.

- [ ] **Step 1: Написать падающий тест на изоляцию ошибок**

Создать `emacs.d/tests/el-boot-test.el`:

```elisp
;; -*- lexical-binding: t; -*-
;;; Tests for el-boot.el.  Run with:
;;;   emacs -Q -batch -L lib -l tests/el-boot-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'el-boot)

(defmacro el-boot-test--with-clean-state (&rest body)
  "Run BODY with `el-failed-modules' reset to nil."
  (declare (indent 0))
  `(let ((el-failed-modules nil))
     ,@body))

(ert-deftest el-boot-test-returns-feature-on-success ()
  (el-boot-test--with-clean-state
    (should (eq 'cl-lib (el-require-module 'cl-lib)))
    (should (null el-failed-modules))))

(ert-deftest el-boot-test-returns-nil-on-failure ()
  (el-boot-test--with-clean-state
    (should (null (el-require-module 'el-boot-no-such-module)))))

(ert-deftest el-boot-test-records-failure-with-message ()
  (el-boot-test--with-clean-state
    (el-require-module 'el-boot-no-such-module)
    (should (equal '(el-boot-no-such-module)
                   (mapcar #'car el-failed-modules)))
    (should (stringp (cdr (car el-failed-modules))))))

(ert-deftest el-boot-test-continues-after-failure ()
  (el-boot-test--with-clean-state
    (should (equal '(cl-lib seq)
                   (el-require-modules 'el-boot-no-such-module 'cl-lib 'seq)))
    (should (equal '(el-boot-no-such-module)
                   (mapcar #'car el-failed-modules)))))

(ert-deftest el-boot-test-records-each-module-once ()
  ;; Review Focus 3: повторный require сбойного модуля не плодит дубли.
  (el-boot-test--with-clean-state
    (el-require-module 'el-boot-no-such-module)
    (el-require-module 'el-boot-no-such-module)
    (should (equal '(el-boot-no-such-module)
                   (mapcar #'car el-failed-modules)))))

(ert-deftest el-boot-test-successful-reload-is-idempotent ()
  ;; Review Focus 3: повторный require загруженного модуля ничего не меняет.
  (el-boot-test--with-clean-state
    (el-require-module 'cl-lib)
    (el-require-module 'cl-lib)
    (should (null el-failed-modules))))
```

- [ ] **Step 2: Запустить тест и убедиться, что он падает**

```bash
cd ~/dotfiles/emacs.d && emacs -Q -batch -L lib -l tests/el-boot-test.el -f ert-run-tests-batch-and-exit
```

Ожидается: ошибка `Cannot open load file: el-boot` — файла ещё нет.

- [ ] **Step 3: Реализовать `lib/el-boot.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-boot.el --- Module loading with error isolation

;;; Commentary:
;; Загрузка модулей конфигурации так, чтобы сбой одного модуля не обрывал
;; загрузку остальных: ошибка записывается в `el-failed-modules' и
;; попадает в *Messages*, а Emacs поднимается до рабочего состояния.

;;; Code:

(defvar el-failed-modules nil
  "Alist of (MODULE . ERROR-MESSAGE) for modules that failed to load.
Каждый модуль присутствует в списке не более одного раза.")

(defun el-require-module (module)
  "Require MODULE, recording a failure instead of aborting the load.
Return MODULE on success and nil on failure."
  (condition-case err
      (progn (require module) module)
    (error
     (let ((message (error-message-string err)))
       (unless (assq module el-failed-modules)
         (push (cons module message) el-failed-modules))
       (message "[el] module %s failed to load: %s" module message))
     nil)))

(defun el-require-modules (&rest modules)
  "Require each of MODULES in order via `el-require-module'.
Return the list of modules that loaded successfully, in request order."
  (delq nil (mapcar #'el-require-module modules)))

(provide 'el-boot)
;;; el-boot.el ends here
```

- [ ] **Step 4: Запустить тест и убедиться, что он проходит**

```bash
cd ~/dotfiles/emacs.d && emacs -Q -batch -L lib -l tests/el-boot-test.el -f ert-run-tests-batch-and-exit
```

Ожидается: `Ran 6 tests, 6 results as expected`.

- [ ] **Step 5: Написать `early-init.el`**

```elisp
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
```

- [ ] **Step 6: Написать `init.el` с полным порядком модулей**

Модули, которых ещё нет, будут попадать в `el-failed-modules` — это ожидаемо и именно так проверяется прогресс по задачам.

```elisp
;; -*- lexical-binding: t; -*-
;;; init.el --- Entry point: bootstrap and load order only

;;; Commentary:
;; Здесь нет настройки пакетов — только подключение архивов, use-package,
;; load-path и порядок загрузки модулей.  Порядок не произвольный:
;; el-core определяет пути, от которых зависят остальные модули;
;; el-keys создаёт el-leader!, без которого модули не могут вешать биндинги;
;; платформенный модуль идёт последним, чтобы мог переопределять всё выше.

;;; Code:

(require 'package)

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))

(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t
      use-package-always-defer nil
      use-package-expand-minimally t)

(dolist (dir '("lib" "modules"))
  (add-to-list 'load-path (expand-file-name dir user-emacs-directory)))

(require 'el-boot)

(el-require-modules
 'el-core
 'el-keys
 'el-completion
 'el-ui
 'el-org
 'el-denote
 'el-ai
 'el-tools
 'el-apps
 'el-local)

;; Если el-core не загрузился, el-termux-p не определена — развилка всё
;; равно должна выбрать модуль, а не уронить init.el.
(el-require-module
 (if (and (fboundp 'el-termux-p) (el-termux-p)) 'el-mobile 'el-desktop))

(when el-failed-modules
  (message "[el] %d module(s) failed: %S"
           (length el-failed-modules)
           (mapcar #'car el-failed-modules)))

;;; init.el ends here
```

- [ ] **Step 7: Написать `Makefile`**

`smoke` не использует `-Q`: флаг `-q` внутри `-Q` отключает загрузку init-файла, а нам нужна именно она. `--batch` сам по себе init-файл загружает.

```makefile
EMACS ?= emacs
TESTS := $(wildcard tests/*-test.el)

CHECK := (if el-failed-modules \
              (error "failed modules: %S" el-failed-modules) \
            (message "smoke ok"))

.PHONY: test smoke smoke-termux

## Юнит-тесты чистой логики из lib/.  Сеть и установка пакетов не нужны.
test:
	$(EMACS) -Q -batch -L lib $(addprefix -l ,$(TESTS)) \
	  -f ert-run-tests-batch-and-exit

## Полный старт конфигурации.  Первый запуск скачивает пакеты.
smoke:
	$(EMACS) -batch --init-directory $(CURDIR) --eval '$(CHECK)'

## То же, но с видом на Termux: проверяет платформенную развилку.
smoke-termux:
	TERMUX_VERSION=1 $(EMACS) -batch --init-directory $(CURDIR) --eval '$(CHECK)'
```

- [ ] **Step 8: Дополнить `.gitignore`**

```bash
cd ~/dotfiles && cat >> .gitignore <<'EOF'
emacs.d/elpa/
emacs.d/var/
emacs.d/etc/
emacs.d/eln-cache/
emacs.d/transient/
emacs.d/.cache/
EOF
touch emacs.d/snippets/.gitkeep
```

- [ ] **Step 9: Запустить `make test` и `make smoke`**

```bash
cd ~/dotfiles/emacs.d && make test
```
Ожидается: `6 results as expected`.

```bash
cd ~/dotfiles/emacs.d && make smoke
```
Ожидается: падение с `failed modules: ...` и перечислением всех 11 ещё не созданных модулей. Это зелёный результат для этой задачи: механизм изоляции работает, Emacs дошёл до конца `init.el`, а не умер на первом `require`.

Если вместо этого видно сетевую ошибку от `package-refresh-contents` — это проблема доступа к ELPA, а не конфига; её надо разрешить до следующей задачи, иначе `use-package` в задачах 2+ не сможет ставить пакеты.

- [ ] **Step 10: Коммит**

```bash
cd ~/dotfiles && git add emacs.d .gitignore && git commit -m "feat(emacs): add vanilla config skeleton with isolated module loading"
```

---

## Task 2: Модуль el-core

**Files:**
- Create: `emacs.d/modules/el-core.el`

**Interfaces:**
- Consumes: ничего.
- Produces:
  - `(el-termux-p)` → строка версии Termux или `nil`. Используется `init.el` и `el-keys`.
  - Переменные путей: `workspace-dir`, `projects-dir`, `org-dir`. Имена сохранены из `doom.d/config.el`, потому что на них ссылается `dotfiles/lisp/org-mobile-mode/org-mobile-mode.el`.

- [ ] **Step 1: Проверить, на какие имена переменных опираются локальные пакеты**

```bash
cd ~/dotfiles && grep -rn "workspace-dir\|org-dir\|projects-dir\|emacs-dir" lisp/
```

Ожидается: совпадения в `lisp/org-mobile-mode/org-mobile-mode.el` и/или других файлах. Эти имена менять нельзя — именно поэтому `workspace-dir` и `org-dir` остаются без префикса `el-`. Если совпадений нет, имена всё равно сохраняются: на них ссылается `el-local` и `el-mobile`.

- [ ] **Step 2: Написать `modules/el-core.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-core.el --- Paths, identity, encryption, file hygiene

;;; Code:

(require 'el-boot)


;;;; Пути и личные данные

(defvar workspace-dir (expand-file-name "~/dotfiles/")
  "Корень репозитория dotfiles.  Имя сохранено из doom.d/config.el,
на него опираются пакеты в dotfiles/lisp/.")

(defvar projects-dir (expand-file-name "~/dev/")
  "Каталог с рабочими проектами.")

(defvar org-dir (expand-file-name "~/org/")
  "Корень org-файлов.")

(setq user-full-name "Egor Lukin"
      user-mail-address "mail@egorlukin.me")

(defun el-termux-p ()
  "Return the Termux version string when running under Termux, else nil."
  (getenv "TERMUX_VERSION"))


;;;; Рантайм-файлы не в репозиторий

(use-package no-littering
  :demand t
  :config
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (startup-redirect-eln-cache
   (no-littering-expand-var-file-name "eln-cache/")))


;;;; Шифрование

(require 'epa-file)
(epa-file-enable)
(setq epa-file-encrypt-to user-mail-address
      epg-pinentry-mode 'loopback)


;;;; Файловая гигиена

;; Автосохранение только org-буферов, раз в 5 секунд.
(setq auto-save-visited-interval 5
      auto-save-visited-predicate (lambda () (derived-mode-p 'org-mode)))
(auto-save-visited-mode 1)

(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

(winner-mode 1)

(save-place-mode 1)
(setq create-lockfiles nil)

(provide 'el-core)
;;; el-core.el ends here
```

- [ ] **Step 3: Проверить, что модуль загружается, а остальные ещё нет**

```bash
cd ~/dotfiles/emacs.d && make smoke 2>&1 | tail -3
```

Ожидается: в списке `failed modules` больше нет `el-core`, остальные 10 на месте.

- [ ] **Step 4: Проверить значения переменных и побочные эффекты**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (princ (format "org-dir=%s termux=%s autosave=%s revert=%s\n" org-dir (el-termux-p) auto-save-visited-mode global-auto-revert-mode)) (unless (file-directory-p org-dir) (error "org-dir missing")))'
```

Ожидается: `org-dir=/home/azx/org/ termux=nil autosave=t revert=t` и отсутствие ошибки.

- [ ] **Step 5: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/modules/el-core.el && git commit -m "feat(emacs): add el-core module"
```

---

## Task 3: Модуль el-keys — evil, general, ядро словаря

**Files:**
- Create: `emacs.d/modules/el-keys.el`

**Interfaces:**
- Consumes: `(el-termux-p)` из `el-core`.
- Produces:
  - Макрос `el-leader!` — `general-create-definer` на `SPC` (normal/visual/motion) и `M-SPC` (insert/emacs). Все последующие модули вешают биндинги только через него.
  - Форма вызова: `(el-leader! "d n" '(denote :which-key "denote"))`.

**Клавиши пишутся через пробел.** `general` склеивает префикс и ключ и отдаёт в `kbd`, поэтому `"TABn"` разбирается как четыре литеральных символа `T A B n`, а не как TAB и `n`. Проверено: `(kbd "SPC TABn")` → `" TABn"`, `(kbd "SPC TAB n")` → `" \tn"`. Поэтому во всех модулях — `"f f"`, `"TAB n"`, `"n c i"`, и так далее.

- [ ] **Step 1: Написать `modules/el-keys.el`**

`evil-want-keybinding nil` обязан быть установлен до загрузки `evil`, иначе `evil-collection` работать не будет — это самая частая ошибка при ручной сборке evil-стека.

```elisp
;; -*- lexical-binding: t; -*-
;;; el-keys.el --- Modal editing and the leader dictionary

;;; Code:

(require 'el-core)


;;;; Evil

(use-package evil
  :init
  ;; Должно быть до загрузки evil, иначе evil-collection бессилен.
  (setq evil-want-keybinding nil
        evil-want-integration t
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo
        evil-split-window-below t
        evil-vsplit-window-right t)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-org
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))


;;;; Леадер

(use-package general
  :demand t
  :config
  (general-create-definer el-leader!
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC"
    :prefix-command 'el-leader-prefix-command
    :prefix-map 'el-leader-map))

(which-key-mode 1)
(setq which-key-idle-delay 0.3)


;;;; Ядро словаря
;; Предметные биндинги (org, denote, gptel, eww, docker) объявляются
;; в своих модулях — здесь только то, что не принадлежит ни одному.

(el-leader!
  "SPC" '(project-find-file :which-key "find file in project")
  ":"   '(execute-extended-command :which-key "M-x")
  "/"   '(consult-ripgrep :which-key "search project")
  ","   '(consult-buffer :which-key "switch buffer")
  "u"   '(universal-argument :which-key "universal arg")

  "f"   '(:ignore t :which-key "file")
  "f f" '(find-file :which-key "find file")
  "f s" '(save-buffer :which-key "save")
  "f S" '(write-file :which-key "save as")
  "f r" '(recentf-open-files :which-key "recent")
  "f p" '(el-find-config-file :which-key "find config file")

  "b"   '(:ignore t :which-key "buffer/bookmark")
  "b b" '(consult-buffer :which-key "switch buffer")
  "b k" '(kill-current-buffer :which-key "kill buffer")
  "b i" '(consult-imenu :which-key "imenu")
  "b r" '(revert-buffer :which-key "revert")

  "w"   '(:keymap evil-window-map :which-key "window")
  "h"   '(:keymap help-map :which-key "help")

  "s"   '(:ignore t :which-key "search")
  "s s" '(consult-line :which-key "line")
  "s p" '(consult-ripgrep :which-key "project")
  "s d" '(consult-fd :which-key "find file by name")

  "t"   '(:ignore t :which-key "toggle")
  "t l" '(display-line-numbers-mode :which-key "line numbers")
  "t w" '(visual-line-mode :which-key "visual line")

  "q"   '(:ignore t :which-key "quit")
  "q q" '(save-buffers-kill-terminal :which-key "quit")
  "q r" '(restart-emacs :which-key "restart"))


;;;; Конфиг под рукой

(defun el-find-config-file ()
  "Open a file from the Emacs configuration directory."
  (interactive)
  (let ((default-directory user-emacs-directory))
    (call-interactively #'find-file)))


;;;; X11-специфичное

;; Review Focus 4: под Termux и Wayland этого делать нельзя.
(when (and (eq window-system 'x) (not (el-termux-p)))
  (setq x-super-keysym 'meta))

(provide 'el-keys)
;;; el-keys.el ends here
```

- [ ] **Step 2: Проверить загрузку и наличие леадер-биндингов**

Загрузка `el-completion` ещё не сделана, поэтому `consult-*` команды пока не определены — биндинг на несуществующую команду это нормально для `general`, ошибки не будет.

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (unless (fboundp (quote el-leader!)) (error "el-leader! missing")) (unless evil-mode (error "evil-mode off")) (unless (keymapp el-leader-map) (error "no leader map")) (unless (keymap-lookup el-leader-map "f f") (error "SPC f f unbound")) (message "keys ok"))'
```

Ожидается: `keys ok`.

- [ ] **Step 3: Проверить Review Focus 4 — запуск с видом на Termux**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(princ (format "termux=%s super=%s\n" (el-termux-p) x-super-keysym))' && TERMUX_VERSION=1 emacs -batch --init-directory $(pwd) --eval '(princ (format "termux=%s super=%s\n" (el-termux-p) x-super-keysym))'
```

Ожидается: в обоих случаях `super=nil` (в батче `window-system` равен `nil`, то есть ветка не исполняется), во втором вызове `termux=1`. Факт, который проверяется: `x-super-keysym` не выставляется там, где нет X11.

- [ ] **Step 4: Проверить вручную в интерактивном Emacs**

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Проверить: evil в normal-режиме; `SPC` показывает which-key-меню; `SPC f f` открывает find-file; `SPC w s` делит окно; `SPC h v` открывает describe-variable; `SPC :` даёт M-x.

- [ ] **Step 5: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/modules/el-keys.el && git commit -m "feat(emacs): add el-keys module with evil, general and core leader map"
```

---

## Task 4: Модуль el-completion

**Files:**
- Create: `emacs.d/modules/el-completion.el`

**Interfaces:**
- Consumes: `el-leader!` из `el-keys`.
- Produces: рабочие `consult-buffer`, `consult-line`, `consult-ripgrep`, `consult-fd`, `consult-imenu` — на них уже ссылается ядро словаря из задачи 3.

- [ ] **Step 1: Написать `modules/el-completion.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-completion.el --- Minibuffer and in-buffer completion

;;; Code:

(require 'el-keys)


;;;; Минибуфер

(use-package vertico
  :demand t
  :config
  (setq vertico-cycle t
        vertico-count 15)
  (vertico-mode 1))

(use-package orderless
  :demand t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :demand t
  :config (marginalia-mode 1))

(use-package consult
  :demand t
  :config
  (setq consult-narrow-key "<"
        xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))

(use-package embark
  :demand t
  ;; M-. не занимаем: это xref-find-definitions.
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(savehist-mode 1)
(recentf-mode 1)
(setq recentf-max-saved-items 200
      enable-recursive-minibuffers t
      completion-ignore-case t
      read-file-name-completion-ignore-case t)


;;;; Дополнение в буфере

(use-package corfu
  :demand t
  :config
  (setq corfu-cycle t
        corfu-auto t
        corfu-auto-prefix 2
        corfu-auto-delay 0.2
        corfu-quit-no-match 'separator)
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))

(use-package cape
  :demand t
  :config
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(setq tab-always-indent 'complete)

(provide 'el-completion)
;;; el-completion.el ends here
```

- [ ] **Step 2: Проверить, что команды из ядра словаря теперь существуют**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(dolist (fn (quote (consult-buffer consult-line consult-ripgrep consult-fd consult-imenu))) (unless (fboundp fn) (error "%s missing" fn))) ' --eval '(progn (unless vertico-mode (error "vertico off")) (unless global-corfu-mode (error "corfu off")) (message "completion ok"))'
```

Ожидается: `completion ok`.

- [ ] **Step 3: Проверить вручную**

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Проверить: `SPC ,` показывает список буферов с аннотациями marginalia; `SPC s s` ищет по строкам текущего буфера; в `*scratch*` набрать `(messa` — всплывает corfu, TAB дополняет; `SPC s p` в каталоге проекта ищет через ripgrep.

- [ ] **Step 4: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/modules/el-completion.el && git commit -m "feat(emacs): add el-completion module with vertico and corfu stack"
```

---

## Task 5: Модуль el-ui

**Files:**
- Create: `emacs.d/modules/el-ui.el`

**Interfaces:**
- Consumes: `el-leader!` из `el-keys`, `(el-termux-p)` из `el-core`.
- Produces: `el-font-height` — высота шрифта в десятых пункта, используется `el-mobile` для переопределения.

**Пересчёт шрифта.** В `doom.d/config.el` стоит `(font-spec :family "monospace" :size 50)`. Целое число в `:size` у `font-spec` — это пиксели. `set-face-attribute` принимает `:height` в десятых пункта. При типичных 96 dpi 50 пикселей ≈ 37.5 пункта, то есть `:height 375`. Число подбирается глазами на шаге проверки — копировать `50` нельзя, это дало бы 5 пунктов.

- [ ] **Step 1: Написать `modules/el-ui.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-ui.el --- Theme, modeline, fonts, line numbers, zen

;;; Code:

(require 'el-core)
(require 'el-keys)


;;;; Тема и modeline

(use-package doom-themes
  :demand t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-monokai-pro :no-confirm)
  (doom-themes-org-config))

(use-package nerd-icons :demand t)

(use-package doom-modeline
  :demand t
  :config
  (setq doom-modeline-height 25
        doom-modeline-buffer-file-name-style 'relative-from-project)
  (doom-modeline-mode 1))


;;;; Шрифты
;; :size 50 в doom-font это пиксели; здесь десятые пункта.

(defvar el-font-height 375
  "Default face height in 1/10 pt.  Пересчёт из `:size 50' в пикселях.")

(defun el-apply-fonts ()
  "Apply the configured fonts to the default and variable-pitch faces."
  (set-face-attribute 'default nil
                      :family "monospace"
                      :height el-font-height
                      :weight 'semi-light)
  (set-face-attribute 'variable-pitch nil
                      :family "sans"
                      :height el-font-height))

(when (display-graphic-p)
  (el-apply-fonts))

;; В daemon/клиентском режиме фрейма при загрузке ещё нет.
(add-hook 'server-after-make-frame-hook #'el-apply-fonts)


;;;; Номера строк и общий вид

(setq display-line-numbers-type t)
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

(setq-default truncate-lines nil)
(setq use-short-answers t
       ring-bell-function #'ignore)
(column-number-mode 1)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))


;;;; Zen

(use-package visual-fill-column
  :config
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t))

(use-package writeroom-mode
  :config
  (setq writeroom-width 100))

(el-leader!
  "t z" '(writeroom-mode :which-key "zen"))


;;;; Мировые часы

(setq world-clock-list
      '(("UTC" "UTC")
        ("Etc/GMT-3" "+3 UTC")
        ("Etc/GMT-4" "+4 UTC"))
      world-clock-time-format "%a %d %b %R %Z")

(el-leader!
  "o"   '(:ignore t :which-key "open")
  "o w" '(world-clock :which-key "world clock"))

(provide 'el-ui)
;;; el-ui.el ends here
```

- [ ] **Step 2: Проверить загрузку темы и modeline**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (unless (memq (quote doom-monokai-pro) custom-enabled-themes) (error "theme not loaded: %S" custom-enabled-themes)) (unless doom-modeline-mode (error "modeline off")) (message "ui ok"))'
```

Ожидается: `ui ok`.

- [ ] **Step 3: Подобрать высоту шрифта глазами**

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Сравнить с работающим Doom (`emacs` без флагов, второе окно). Если новый шрифт крупнее или мельче — поправить `el-font-height` в `el-ui.el` и перезапустить. Готово, когда размер совпадает с Doom на глаз.

- [ ] **Step 4: Проверить номера строк и zen**

В интерактивном Emacs: открыть любой `.el` — номера строк есть; открыть `*scratch*` в `text-mode` — номера есть; `SPC t z` включает writeroom; `SPC o w` показывает три часовых пояса.

- [ ] **Step 5: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/modules/el-ui.el && git commit -m "feat(emacs): add el-ui module with doom theme, modeline and fonts"
```

---

## Task 6: Модуль el-org и библиотека el-clock

**Files:**
- Create: `emacs.d/lib/el-clock.el`
- Create: `emacs.d/tests/el-clock-test.el`
- Create: `emacs.d/modules/el-org.el`

**Interfaces:**
- Consumes: `org-dir` из `el-core`, `el-leader!` из `el-keys`.
- Produces:
  - `(hms-to-minutes STRING)` → integer. **Имя сохранено без префикса `el-`**, потому что функция вызывается из формул org-таблиц в `~/org/tasks/*.org` и `~/org/snippets/org-mode/*`; переименование сломало бы эти таблицы.
  - `(hms-to-pomodoros STRING)` → integer. То же.
  - `(el-clock-format-line TASK MINUTES)` → string вида `"Task (12 min)"`.
  - `(el-org-agenda-files)` → список файлов, безопасный при отсутствующем каталоге.

- [ ] **Step 1: Написать падающие тесты на `el-clock`**

Тесты закрепляют поведение, от которого зависят существующие org-таблицы, и добивают Review Focus 2.

Создать `emacs.d/tests/el-clock-test.el`:

```elisp
;; -*- lexical-binding: t; -*-
;;; Tests for el-clock.el.  Run with:
;;;   emacs -Q -batch -L lib -l tests/el-clock-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'el-clock)

;;;; hms-to-minutes

(ert-deftest el-clock-test-minutes-from-hours-and-minutes ()
  (should (equal 90 (hms-to-minutes "1:30"))))

(ert-deftest el-clock-test-minutes-zero-hours ()
  (should (equal 45 (hms-to-minutes "0:45"))))

(ert-deftest el-clock-test-minutes-ignores-seconds ()
  (should (equal 90 (hms-to-minutes "1:30:15"))))

(ert-deftest el-clock-test-minutes-bare-number-is-minutes ()
  ;; Review Focus 2: в org-таблице ячейка может быть просто числом.
  ;; Исходная реализация падала здесь на (string-to-number nil).
  (should (equal 90 (hms-to-minutes "90"))))

(ert-deftest el-clock-test-minutes-blank-is-zero ()
  (should (equal 0 (hms-to-minutes "")))
  (should (equal 0 (hms-to-minutes "   ")))
  (should (equal 0 (hms-to-minutes nil))))

(ert-deftest el-clock-test-minutes-garbage-is-zero ()
  ;; Review Focus 2: мусор не должен обрывать пересчёт всей таблицы.
  (should (equal 0 (hms-to-minutes "n/a"))))

;;;; hms-to-pomodoros

(ert-deftest el-clock-test-pomodoros-truncate-toward-zero ()
  (should (equal 3 (hms-to-pomodoros "1:30")))
  (should (equal 0 (hms-to-pomodoros "0:24")))
  (should (equal 1 (hms-to-pomodoros "0:25"))))

(ert-deftest el-clock-test-pomodoros-strips-bold-markers ()
  (should (equal 3 (hms-to-pomodoros "*1:30*"))))

(ert-deftest el-clock-test-pomodoros-blank-is-zero ()
  (should (equal 0 (hms-to-pomodoros "")))
  (should (equal 0 (hms-to-pomodoros nil))))

;;;; Строка для polybar

(ert-deftest el-clock-test-format-line ()
  (should (equal "Write plan (12 min)"
                 (el-clock-format-line "Write plan" 12))))
```

- [ ] **Step 2: Запустить тесты и убедиться, что они падают**

```bash
cd ~/dotfiles/emacs.d && emacs -Q -batch -L lib -l tests/el-clock-test.el -f ert-run-tests-batch-and-exit
```

Ожидается: `Cannot open load file: el-clock`.

- [ ] **Step 3: Реализовать `lib/el-clock.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-clock.el --- Clock arithmetic used by org tables

;;; Commentary:
;; `hms-to-minutes' и `hms-to-pomodoros' вызываются из формул org-таблиц
;; в ~/org/tasks и ~/org/snippets, поэтому их имена сохранены без
;; префикса el- и их поведение закреплено тестами.

;;; Code:

(require 'subr-x)

(defconst el-clock-pomodoro-minutes 25
  "Length of one pomodoro in minutes.")

(defun hms-to-minutes (str)
  "Convert STR to a whole number of minutes.
STR may be \"H:MM\", \"H:MM:SS\" or a bare number of minutes.  Blank,
nil and unparsable input yield 0, so a stray cell cannot break the
recalculation of a whole org table."
  (cond
   ((or (null str) (string-blank-p str)) 0)
   ((string-match-p ":" str)
    (let* ((parts (split-string str ":"))
           (hours (string-to-number (or (nth 0 parts) "0")))
           (minutes (string-to-number (or (nth 1 parts) "0"))))
      (+ (* hours 60) minutes)))
   (t (truncate (string-to-number str)))))

(defun hms-to-pomodoros (str)
  "Convert STR to a whole number of pomodoros, truncating toward zero.
Surrounding org bold markers are stripped, so \"*1:30*\" and \"1:30\"
agree."
  (cond
   ((or (null str) (string-blank-p str)) 0)
   ((and (string-prefix-p "*" str) (string-suffix-p "*" str))
    (hms-to-pomodoros (substring str 1 -1)))
   (t (/ (hms-to-minutes str) el-clock-pomodoro-minutes))))

(defun el-clock-format-line (task minutes)
  "Format TASK and MINUTES as a one-line clock summary."
  (format "%s (%d min)" task minutes))

(provide 'el-clock)
;;; el-clock.el ends here
```

- [ ] **Step 4: Запустить тесты и убедиться, что они проходят**

```bash
cd ~/dotfiles/emacs.d && make test
```

Ожидается: `Ran 16 tests, 16 results as expected` (6 из `el-boot` + 10 из `el-clock`).

- [ ] **Step 5: Сверить с поведением старой реализации на реальных данных**

```bash
cd ~/dotfiles && grep -rhn "hms-to-" ~/org/tasks ~/org/snippets 2>/dev/null | head -20
```

Посмотреть, в каком виде функции вызываются из таблиц, и убедиться, что аргументы покрыты тестами из шага 1. Если встретился формат, которого нет в тестах, добавить тест и при необходимости ветку в `hms-to-minutes`.

- [ ] **Step 6: Написать `modules/el-org.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-org.el --- Org mode, GTD, clocking, capture, drill

;;; Code:

(require 'el-core)
(require 'el-keys)
(require 'el-clock)


;;;; Файлы повестки
;; Review Focus 1: directory-files на отсутствующем каталоге сигналит
;; file-missing и обрывает загрузку модуля целиком.

(defvar el-org-projects-dir (expand-file-name "projects/" org-dir)
  "Directory whose org files make up the agenda.")

(defun el-org-agenda-files ()
  "Return the agenda files from `el-org-projects-dir'.
Return nil when the directory is missing, so a renamed or not-yet-cloned
org repository cannot break the configuration."
  (when (file-directory-p el-org-projects-dir)
    (directory-files el-org-projects-dir t "\\.org\\(\\.gpg\\)?\\'")))


;;;; Org

(use-package org
  :ensure nil
  :config
  (require 'org-habit)
  (setq org-directory org-dir
        org-agenda-files (el-org-agenda-files)
        org-log-into-drawer t
        org-log-done t
        org-use-fast-todo-selection t
        org-refile-targets '((org-agenda-files :maxlevel . 2))
        org-todo-keywords '((sequence "TODO" "IN-PROGRESS" "WAIT" "|" "DONE" "CLOSED"))
        org-habit-show-habits-only-for-today t
        org-habit-preceding-days 25
        org-habit-following-days 3
        org-attach-directory (expand-file-name "~/photos/attachments")
        org-agenda-prefix-format '((agenda . " %i %-5:c%?-5t% s"))
        org-agenda-overriding-columns-format
        "%100ITEM  %TODO %7EFFORT %PRIORITY     100%TAGS"))


;;;; Хронометраж

(setq org-clock-persist t
      org-clock-persist-query-resume nil)
(with-eval-after-load 'org
  (org-clock-persistence-insinuate))

(defvar el-org-polybar-idle-text "no active clocks!"
  "Text reported to polybar when no clock is running.")

(defun el-org-polybar-clock-line ()
  "Report the running clock as a single line for polybar."
  (interactive)
  (message
   "%s"
   (if (org-clocking-p)
       (el-clock-format-line
        org-clock-heading
        (floor (org-time-convert-to-integer (time-since org-clock-start-time)) 60))
     el-org-polybar-idle-text)))


;;;; Capture

(setq org-capture-templates
      '(("e" "English word" entry
         (file+headline "drill/english_words.org" "Words")
         "* %? :drill:\n[]\n")
        ("t" "Project Todo" entry
         (file+headline (lambda () (completing-read "File: " org-agenda-files))
                        "tasks")
         (file "templates/todo.org"))
        ("n" "new note (via denote)" plain
         (file denote-last-path)
         (function
          (lambda ()
            (let ((denote-use-directory
                   (read-directory-name "Subdirectory: " (denote-directory))))
              (denote-org-capture))))
         :no-save t
         :immediate-finish nil
         :kill-buffer t
         :jump-to-captured t)
        ("b" "temp daily note" entry
         (file+headline (lambda () (denote-journal-path-to-new-or-existing-entry))
                        "buffer")
         (file "templates/buffer.org"))))


;;;; Drill и помодоро

(use-package org-drill
  :vc (:url "https://gitlab.com/phillord/org-drill.git" :rev :newest)
  :commands (org-drill org-drill-resume)
  :config
  (setq org-drill-spaced-repetition-algorithm 'sm2))

(use-package org-pomodoro
  :commands (org-pomodoro))


;;;; Babel

(use-package ob-async
  :after org
  :demand t)

(use-package ob-http
  :vc (:url "https://github.com/zweifisch/ob-http.git" :rev :newest)
  :after org
  :demand t)


;;;; Биндинги

(el-leader!
  "x"     '(org-capture :which-key "capture")
  "n"     '(:ignore t :which-key "org")
  "n a"   '(org-agenda :which-key "agenda")
  "n t"   '(org-todo-list :which-key "todo list")
  "n c"   '(:ignore t :which-key "clock")
  "n c i" '(org-clock-in :which-key "clock in")
  "n c o" '(org-clock-out :which-key "clock out")
  "n c g" '(org-clock-goto :which-key "goto clock")
  "b c"   '(el-org-polybar-clock-line :which-key "polybar clock line"))

(provide 'el-org)
;;; el-org.el ends here
```

Загрузку языков babel добавляет `el-local` после того, как `ob-search` окажется в `load-path` — иначе `org-babel-do-load-languages` сигналит на неизвестном языке `search`.

- [ ] **Step 7: Проверить Review Focus 1 — отсутствующий каталог проектов**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (let ((el-org-projects-dir "/tmp/el-no-such-dir-12345/")) (unless (null (el-org-agenda-files)) (error "expected nil"))) (unless (el-org-agenda-files) (error "real agenda files empty")) (message "agenda ok: %d files" (length (el-org-agenda-files))))'
```

Ожидается: `agenda ok: N files`, где N больше нуля. Факт, который проверяется: отсутствующий каталог даёт `nil`, а не ошибку.

- [ ] **Step 8: Проверить загрузку модуля и capture-шаблоны**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (unless (= 4 (length org-capture-templates)) (error "expected 4 templates, got %d" (length org-capture-templates))) (unless (featurep (quote org-habit)) (error "org-habit missing")) (unless org-clock-persist (error "clock persist off")) (message "org ok"))'
```

Ожидается: `org ok`. Модуля `el-denote` ещё нет, поэтому шаблоны `n` и `b` пока сошлются на неопределённые функции — это проявится только при вызове capture, не при загрузке.

- [ ] **Step 9: Проверить вручную**

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Проверить: `SPC n a` открывает повестку с задачами из `~/org/projects/`; привычки отображаются; `SPC x` показывает список из 4 шаблонов; `SPC x t` даёт выбор файла и вставляет шаблон из `~/org/templates/todo.org`; `SPC n c i` на заголовке запускает хронометраж, `SPC b c` печатает строку с задачей и минутами.

- [ ] **Step 10: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/lib/el-clock.el emacs.d/tests/el-clock-test.el emacs.d/modules/el-org.el && git commit -m "feat(emacs): add el-org module and tested clock arithmetic"
```

---

## Task 7: Модуль el-denote

**Files:**
- Create: `emacs.d/modules/el-denote.el`

**Interfaces:**
- Consumes: `org-dir` из `el-core`, `el-leader!` из `el-keys`.
- Produces: рабочие `denote-last-path`, `denote-org-capture`, `denote-journal-path-to-new-or-existing-entry` — на них ссылаются capture-шаблоны `n` и `b` из задачи 6.

`denote` и `denote-journal` живут на GNU ELPA (зеркала `emacs-straight/*` в Doom это подтверждают), поэтому `:ensure t` достаточно, `:vc` не нужен.

**Исправления из спеки, которые надо внести именно здесь:**
- `SPC d n` → `denote` (в `doom.d/config.el` клавиша `"n"` забиндена дважды и `denote` недостижим);
- next/prev день журнала → `SPC d ]` и `SPC d [`;
- Review Focus 5: `(push (denote-journal-path-to-new-or-existing-entry) org-agenda-files)` в `with-eval-after-load 'org` создаёт файл журнала при каждом старте Emacs. Запись в повестку должна появляться при открытии повестки, а не при загрузке конфига.

- [ ] **Step 1: Зафиксировать текущее число файлов журнала**

```bash
ls ~/org/journal | wc -l
```

Записать число — оно понадобится на шаге 4.

- [ ] **Step 2: Написать `modules/el-denote.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-denote.el --- Denote notes and journal

;;; Code:

(require 'el-core)
(require 'el-keys)

(use-package denote
  :hook (dired-mode . denote-dired-mode)
  :config
  (setq denote-directory (expand-file-name org-dir)
        denote-prompts '(title keywords subdirectory))
  (denote-rename-buffer-mode 1))

(use-package denote-journal
  :commands (denote-journal-new-entry
             denote-journal-new-or-existing-entry
             denote-journal-link-or-create-entry
             denote-journal-path-to-new-or-existing-entry)
  :hook (calendar-mode . denote-journal-calendar-mode)
  :config
  (setq denote-journal-directory (expand-file-name "journal" denote-directory)
        denote-journal-keyword "journal"
        denote-journal-title-format "%Y-%m-%d"))


;;;; Журнал в повестке
;; Review Focus 5: denote-journal-path-to-new-or-existing-entry создаёт
;; файл, поэтому вызывать его на загрузке конфига нельзя — каждый старт
;; Emacs плодил бы пустую запись.  Делаем это при открытии повестки.

(defun el-denote-journal-ensure-agenda-entry (&rest _)
  "Add today's journal entry to `org-agenda-files' if it is not there yet."
  (require 'denote-journal)
  (let ((path (denote-journal-path-to-new-or-existing-entry)))
    (when (and path (not (member path org-agenda-files)))
      (push path org-agenda-files))))

(advice-add 'org-agenda :before #'el-denote-journal-ensure-agenda-entry)


;;;; Навигация по дням
;; Определены в dotfiles/lisp/denote-extras, который грузит el-local.

(el-leader!
  "d"   '(:ignore t :which-key "denote")
  "d n" '(denote :which-key "denote")
  "d i" '(denote-link-after-creating :which-key "link after creating")
  "d j" '(denote-journal-new-or-existing-entry :which-key "journal entry")
  "d l" '(denote-link :which-key "link")
  "d b" '(denote-backlinks :which-key "backlinks")
  "d f" '(denote-open-or-create :which-key "open or create")
  "d [" '(my/denote-journal-open-previous-day :which-key "previous day")
  "d ]" '(my/denote-journal-open-next-day :which-key "next day"))

(provide 'el-denote)
;;; el-denote.el ends here
```

- [ ] **Step 3: Проверить загрузку и биндинги**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (unless (string= (expand-file-name "~/org/") (expand-file-name denote-directory)) (error "denote-directory=%s" denote-directory)) (unless (eq (quote denote) (keymap-lookup el-leader-map "d n")) (error "SPC d n -> %S" (keymap-lookup el-leader-map "d n"))) (message "denote ok"))'
```

Ожидается: `denote ok`. Именно это закрепляет исправление: `SPC d n` ведёт на `denote`, а не на навигацию по дням.

- [ ] **Step 4: Проверить Review Focus 5 — старт не создаёт запись журнала**

```bash
cd ~/dotfiles/emacs.d && for i in 1 2 3; do emacs -batch --init-directory $(pwd) --eval '(message "start %d" 1)' >/dev/null 2>&1; done; ls ~/org/journal | wc -l
```

Ожидается: то же число, что на шаге 1. Если выросло — advice сработал не там, где задумано, или `denote-journal` всё ещё вызывается на загрузке.

- [ ] **Step 5: Проверить вручную**

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Проверить: `SPC d n` спрашивает заголовок, ключевые слова и подкаталог и создаёт заметку; `SPC d j` открывает запись за сегодня; `SPC d f` ищет среди заметок; `SPC n a` открывает повестку, и запись журнала за сегодня в ней присутствует.

- [ ] **Step 6: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/modules/el-denote.el && git commit -m "feat(emacs): add el-denote module, fix shadowed SPC d n and lazy journal agenda entry"
```

---

## Task 8: Модуль el-local — пакеты из dotfiles/lisp

**Files:**
- Create: `emacs.d/modules/el-local.el`

**Interfaces:**
- Consumes: `workspace-dir` из `el-core`; `org` из `el-org`.
- Produces: `my/denote-journal-open-previous-day`, `my/denote-journal-open-next-day` (из `denote-extras`) — на них ссылаются биндинги задачи 7; языки babel `http` и `search`.

- [ ] **Step 1: Посмотреть, что требуют локальные пакеты**

```bash
cd ~/dotfiles && head -25 lisp/denote-extras/denote-extras.el lisp/logbook-table/logbook-table.el lisp/open-meteo/open-meteo.el lisp/org-babel-search/ob-search.el
```

Нужно убедиться, какие `require` они делают и какие имена предоставляют. `org-mobile-mode` сознательно не грузится здесь — он нужен только под Termux и подключается в `el-mobile`.

- [ ] **Step 2: Написать `modules/el-local.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-local.el --- Local packages from dotfiles/lisp

;;; Commentary:
;; Пакеты остаются в dotfiles/lisp, путь к ним строится от workspace-dir.
;; org-mobile-mode здесь не грузится: он нужен только под Termux и
;; подключается модулем el-mobile.

;;; Code:

(require 'el-core)
(require 'el-boot)

(dolist (dir '("lisp/denote-extras"
               "lisp/logbook-table"
               "lisp/open-meteo"
               "lisp/org-babel-search"))
  (add-to-list 'load-path (expand-file-name dir workspace-dir)))

;; Сбой одного локального пакета не должен ронять остальные.
(el-require-modules 'denote-extras 'logbook-table 'open-meteo 'ob-search)

;; Выполняется после того, как ob-search и ob-http оказались в load-path.
(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((http . t)
     (search . t))))

(provide 'el-local)
;;; el-local.el ends here
```

- [ ] **Step 3: Проверить, что все четыре пакета загрузились**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (dolist (f (quote (denote-extras logbook-table open-meteo ob-search))) (unless (featurep f) (error "%s not loaded" f))) (dolist (fn (quote (my/denote-journal-open-previous-day my/denote-journal-open-next-day))) (unless (fboundp fn) (error "%s missing" fn))) (message "local ok"))'
```

Ожидается: `local ok`. Если какой-то пакет в `el-failed-modules` — посмотреть текст ошибки в выводе и дописать недостающий `require` в сам пакет в `dotfiles/lisp/`.

- [ ] **Step 4: Проверить языки babel**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (require (quote org)) (dolist (lang (quote (http search))) (unless (assq lang org-babel-load-languages) (error "%s not registered" lang))) (message "babel ok"))'
```

Ожидается: `babel ok`.

- [ ] **Step 5: Прогнать тесты ob-search в новом окружении**

```bash
cd ~/dotfiles/lisp/org-babel-search && emacs -Q -batch -L . -l ob-search-test.el -f ert-run-tests-batch-and-exit
```

Ожидается: тесты проходят (кроме помеченных `:live`, которые требуют реального `ddgr`). Это проверка, что переезд конфига не задел сам пакет.

- [ ] **Step 6: Проверить вручную**

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Проверить: в org-буфере блок `#+begin_src search` исполняется по `C-c C-c` и возвращает таблицу; `SPC d [` и `SPC d ]` переключают дни журнала; `logbook-table` и `open-meteo` отвечают на `M-x`.

- [ ] **Step 7: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/modules/el-local.el && git commit -m "feat(emacs): add el-local module loading dotfiles/lisp packages"
```

---

## Task 9: Модуль el-ai

**Files:**
- Create: `emacs.d/modules/el-ai.el`

**Interfaces:**
- Consumes: `workspace-dir`, `org-dir` из `el-core`; `el-leader!` из `el-keys`.
- Produces: `(el-ai-find-train-tickets FROM TO DATE)` → string; макрос `gptel-make-safe-tool` (имя сохранено из `config.el`).

Точные git-источники (сняты с remote'ов straight-репозиториев текущего Doom):
- `gptel` → `https://github.com/karthink/gptel.git`, ветка `master`
- `gptel-agent` → `https://github.com/karthink/gptel-agent.git`
- `acp` → `https://github.com/xenodium/acp.el.git`
- `agent-shell` → `https://github.com/xenodium/agent-shell.git`

- [ ] **Step 1: Проверить, что ключ достаётся из pass**

```bash
pass show env/OPENROUTER_API_KEY | head -c 8 && echo "...ok"
```

Ожидается: первые символы ключа. Если `pass` спрашивает пароль — это нормально, важно что путь существует. Если путь не найден — исправить путь в конфиге на шаге 2, а не выдумывать ключ.

- [ ] **Step 2: Написать `modules/el-ai.el`**

Списки моделей, presets и тул `search_trains` переносятся из `doom.d/config.el` дословно — это пользовательские данные, а не код, который надо «улучшать».

```elisp
;; -*- lexical-binding: t; -*-
;;; el-ai.el --- gptel, agent shell and LLM tools

;;; Code:

(require 'el-core)
(require 'el-keys)

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

(provide 'el-ai)
;;; el-ai.el ends here
```

- [ ] **Step 3: Проверить загрузку и регистрацию бэкендов**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (require (quote gptel)) (unless (eq gptel-default-mode (quote org-mode)) (error "mode=%S" gptel-default-mode)) (dolist (b (quote ("OpenRouter" "Ollama"))) (unless (assoc b gptel--known-backends) (error "backend %s missing" b))) (unless (fboundp (quote el-ai-find-train-tickets)) (error "train tool fn missing")) (message "ai ok: backends=%S" (mapcar (function car) gptel--known-backends)))'
```

Ожидается: `ai ok: backends=("Ollama" "OpenRouter")` в каком-то порядке. Если `gptel--known-backends` переименована в текущем master gptel — взять актуальное имя из `gptel.el` в `emacs.d/elpa/` и поправить проверку, а не конфиг.

- [ ] **Step 4: Проверить, что ключ не читается на загрузке**

Ключ обёрнут в lambda, то есть `pass` не должен вызываться при старте.

```bash
cd ~/dotfiles/emacs.d && time emacs -batch --init-directory $(pwd) --eval '(message "loaded")'
```

Ожидается: старт без запроса пароля GPG и без зависания.

- [ ] **Step 5: Проверить тул поиска поездов**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(princ (substring (el-ai-find-train-tickets "Moskva" "Sankt-Peterburg" "20.10.2026") 0 300))'
```

Ожидается: вывод скрипта (список поездов либо его сообщение об ошибке). Проверяется, что `default-directory` указывает в `~/dotfiles` и `bun` находится.

- [ ] **Step 6: Проверить вручную**

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Проверить: `SPC a g` открывает буфер gptel в org-mode; `SPC a m` показывает меню, в нём доступны presets `assistant` и `english-cards`; отправка запроса получает ответ (ключ берётся из pass); `SPC a t` запускает agent-shell.

- [ ] **Step 7: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/modules/el-ai.el && git commit -m "feat(emacs): add el-ai module with gptel backends, presets and tools"
```

---

## Task 10: Модуль el-tools и библиотеки el-docker, el-project

**Files:**
- Create: `emacs.d/lib/el-docker.el`
- Create: `emacs.d/tests/el-docker-test.el`
- Create: `emacs.d/lib/el-project.el`
- Create: `emacs.d/tests/el-project-test.el`
- Create: `emacs.d/modules/el-tools.el`

**Interfaces:**
- Consumes: `workspace-dir`, `org-dir` из `el-core`; `el-leader!` из `el-keys`.
- Produces:
  - `(el-docker-parse-ps OUTPUT)` → список `(LABEL NAME . ID)`.
  - `(el-project-counterparts RELATIVE-PATH)` → список строк-кандидатов.
  - `(el-project-break-string RELATIVE-PATH LINE)` → строка `"break path:line"`.
  - Команды: `el-docker-find-file`, `el-project-toggle-test`, `el-project-break-location-copy`, `el-delete-file-and-buffer`, `el-rename-file-and-buffer`.

- [ ] **Step 1: Написать падающие тесты на `el-docker`**

Создать `emacs.d/tests/el-docker-test.el`:

```elisp
;; -*- lexical-binding: t; -*-
;;; Tests for el-docker.el.  Run with:
;;;   emacs -Q -batch -L lib -l tests/el-docker-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'el-docker)

(defconst el-docker-test--ps-output
  "web|2026-10-01 11:22:33 +0300 MSK|a1b2c3d4e5f6
db|2026-09-30 09:00:00 +0300 MSK|f6e5d4c3b2a1
"
  "Verbatim shape of `docker ps --format {{.Names}}|{{.CreatedAt}}|{{.ID}}'.")

(ert-deftest el-docker-test-parses-two-containers ()
  (should (equal 2 (length (el-docker-parse-ps el-docker-test--ps-output)))))

(ert-deftest el-docker-test-label-shows-name-created-and-id ()
  (should (equal "web (2026-10-01 11:22:33 +0300 MSK) [a1b2c3d4e5f6]"
                 (car (nth 0 (el-docker-parse-ps el-docker-test--ps-output))))))

(ert-deftest el-docker-test-keeps-name-and-id ()
  (should (equal '("web" . "a1b2c3d4e5f6")
                 (cdr (nth 0 (el-docker-parse-ps el-docker-test--ps-output))))))

(ert-deftest el-docker-test-empty-output-is-nil ()
  (should (null (el-docker-parse-ps "")))
  (should (null (el-docker-parse-ps "\n"))))

(ert-deftest el-docker-test-skips-malformed-lines ()
  ;; Строка без идентификатора бесполезна для tramp — её надо отбросить,
  ;; а не предлагать как кандидата.
  (should (equal '("web")
                 (mapcar (lambda (c) (car (cdr c)))
                         (el-docker-parse-ps
                          "web|2026-10-01|a1b2c3d4e5f6\nbroken-line\n")))))
```

- [ ] **Step 2: Запустить и убедиться, что падает**

```bash
cd ~/dotfiles/emacs.d && emacs -Q -batch -L lib -l tests/el-docker-test.el -f ert-run-tests-batch-and-exit
```

Ожидается: `Cannot open load file: el-docker`.

- [ ] **Step 3: Реализовать `lib/el-docker.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-docker.el --- Parse docker ps output into completion candidates

;;; Code:

(defconst el-docker-ps-format "{{.Names}}|{{.CreatedAt}}|{{.ID}}"
  "Format string passed to `docker ps --format'.")

(defun el-docker-parse-ps (output)
  "Parse OUTPUT of `docker ps --format el-docker-ps-format'.
Return a list of (LABEL NAME . ID).  Lines that do not carry all three
fields are skipped, because without an id they are useless for tramp."
  (delq nil
        (mapcar
         (lambda (line)
           (let ((parts (split-string line "|")))
             (when (= 3 (length parts))
               (let ((name (nth 0 parts))
                     (created (nth 1 parts))
                     (id (nth 2 parts)))
                 (cons (format "%s (%s) [%s]" name created id)
                       (cons name id))))))
         (split-string output "\n" t))))

(provide 'el-docker)
;;; el-docker.el ends here
```

- [ ] **Step 4: Запустить и убедиться, что проходит**

```bash
cd ~/dotfiles/emacs.d && emacs -Q -batch -L lib -l tests/el-docker-test.el -f ert-run-tests-batch-and-exit
```

Ожидается: `Ran 5 tests, 5 results as expected`.

- [ ] **Step 5: Написать падающие тесты на `el-project`**

Создать `emacs.d/tests/el-project-test.el`:

```elisp
;; -*- lexical-binding: t; -*-
;;; Tests for el-project.el.  Run with:
;;;   emacs -Q -batch -L lib -l tests/el-project-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(require 'el-project)

;;;; Переход между реализацией и тестом

(ert-deftest el-project-test-elisp-impl-to-test ()
  (should (member "lib/el-clock-test.el"
                  (el-project-counterparts "lib/el-clock.el"))))

(ert-deftest el-project-test-elisp-test-to-impl ()
  (should (member "lib/el-clock.el"
                  (el-project-counterparts "lib/el-clock-test.el"))))

(ert-deftest el-project-test-ruby-swaps-lib-and-spec ()
  (should (member "spec/models/user_spec.rb"
                  (el-project-counterparts "lib/models/user.rb"))))

(ert-deftest el-project-test-ruby-spec-back-to-lib ()
  (should (member "lib/models/user.rb"
                  (el-project-counterparts "spec/models/user_spec.rb"))))

(ert-deftest el-project-test-python-impl-to-test ()
  (should (member "tests/test_parser.py"
                  (el-project-counterparts "src/parser.py"))))

(ert-deftest el-project-test-python-test-to-impl ()
  (should (member "src/parser.py"
                  (el-project-counterparts "tests/test_parser.py"))))

(ert-deftest el-project-test-typescript-dot-test ()
  (should (member "app/api.test.ts"
                  (el-project-counterparts "app/api.ts")))
  (should (member "app/api.ts"
                  (el-project-counterparts "app/api.test.ts"))))

(ert-deftest el-project-test-same-directory-candidate-present ()
  ;; Не во всех проектах тесты лежат в отдельном каталоге.
  (should (member "lib/models/user_spec.rb"
                  (el-project-counterparts "lib/models/user.rb"))))

(ert-deftest el-project-test-unknown-extension-is-nil ()
  (should (null (el-project-counterparts "README.org")))
  (should (null (el-project-counterparts "Makefile"))))

;;;; Строка точки останова

(ert-deftest el-project-test-break-string ()
  (should (equal "break app/models/user.rb:42"
                 (el-project-break-string "app/models/user.rb" 42))))
```

- [ ] **Step 6: Запустить и убедиться, что падает**

```bash
cd ~/dotfiles/emacs.d && emacs -Q -batch -L lib -l tests/el-project-test.el -f ert-run-tests-batch-and-exit
```

Ожидается: `Cannot open load file: el-project`.

- [ ] **Step 7: Реализовать `lib/el-project.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-project.el --- Implementation/test navigation on top of project.el

;;; Commentary:
;; Замена projectile-toggle-between-implementation-and-test.  Логика
;; сопоставления путей чистая и покрыта тестами; команда поверх неё
;; обращается к project.el.

;;; Code:

(require 'subr-x)

(defconst el-project-test-rules
  '(("el"  :suffix "-test")
    ("rb"  :suffix "_spec" :impl-dirs ("lib" "app") :test-dirs ("spec"))
    ("py"  :prefix "test_" :impl-dirs ("src") :test-dirs ("tests"))
    ("ts"  :suffix ".test")
    ("tsx" :suffix ".test")
    ("js"  :suffix ".test")
    ("jsx" :suffix ".test"))
  "Rules mapping implementation files to their test counterparts.
Each entry is (EXTENSION . PLIST) where PLIST may contain:
  :suffix     appended to the basename of the test file
  :prefix     prepended to the basename of the test file
  :impl-dirs  leading path segments used by implementation files
  :test-dirs  leading path segments used by test files")

(defun el-project--swap-leading-dir (path from-dirs to-dirs)
  "Return PATH with a leading segment from FROM-DIRS replaced by TO-DIRS' first.
PATH is returned unchanged when either list is empty or no segment matches."
  (if (and from-dirs to-dirs)
      (let* ((segments (split-string path "/"))
             (head (car segments)))
        (if (member head from-dirs)
            (string-join (cons (car to-dirs) (cdr segments)) "/")
          path))
    path))

(defun el-project--test-name-p (base rule)
  "Return non-nil when BASE already looks like a test name under RULE."
  (let ((suffix (plist-get rule :suffix))
        (prefix (plist-get rule :prefix)))
    (or (and suffix (string-suffix-p suffix base))
        (and prefix (string-prefix-p prefix base)))))

(defun el-project-counterparts (path)
  "Return candidate counterpart paths for PATH, relative to a project root.
When PATH looks like a test the candidates are implementation files, and
vice versa.  Candidates are ordered by preference and are not checked for
existence.  Return nil when no rule covers PATH's extension."
  (let* ((ext (file-name-extension path))
         (rule (cdr (assoc ext el-project-test-rules))))
    (when rule
      (let* ((dir (or (file-name-directory path) ""))
             (base (file-name-base path))
             (suffix (plist-get rule :suffix))
             (prefix (plist-get rule :prefix))
             (impl-dirs (plist-get rule :impl-dirs))
             (test-dirs (plist-get rule :test-dirs))
             (testp (el-project--test-name-p base rule))
             (new-base
              (if testp
                  (cond (suffix (string-remove-suffix suffix base))
                        (prefix (string-remove-prefix prefix base)))
                (cond (suffix (concat base suffix))
                      (prefix (concat prefix base)))))
             (same-dir (concat dir new-base "." ext))
             (swapped (el-project--swap-leading-dir
                       same-dir
                       (if testp test-dirs impl-dirs)
                       (if testp impl-dirs test-dirs))))
        (delete-dups (list swapped same-dir))))))

(defun el-project-break-string (relative-path line)
  "Format a debugger break location for RELATIVE-PATH at LINE."
  (format "break %s:%d" relative-path line))

(provide 'el-project)
;;; el-project.el ends here
```

- [ ] **Step 8: Запустить и убедиться, что проходит**

```bash
cd ~/dotfiles/emacs.d && make test
```

Ожидается: `Ran 31 tests, 31 results as expected` (6 boot + 10 clock + 5 docker + 10 project).

- [ ] **Step 9: Написать `modules/el-tools.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-tools.el --- Git, shells, projects, docker, files, snippets

;;; Code:

(require 'el-core)
(require 'el-keys)
(require 'el-docker)
(require 'el-project)


;;;; Git

(use-package magit
  :commands (magit-status magit-blame-addition magit-log-current))

(use-package diff-hl
  :demand t
  :config
  (global-diff-hl-mode 1)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))


;;;; Терминалы

(use-package vterm
  :commands (vterm vterm-other-window)
  :config (setq vterm-max-scrollback 10000))

(defun el-eshell-load-bash-aliases ()
  "Read Bash aliases and add them to the list of eshell aliases."
  (with-temp-buffer
    (call-process "bash" nil '(t nil) nil "-ci" "alias")
    (goto-char (point-min))
    (while (re-search-forward "alias \\(.+\\)='\\(.+\\)'$" nil t)
      (eshell/alias (match-string 1) (match-string 2)))))

(with-eval-after-load 'eshell
  (add-hook 'eshell-alias-load-hook #'el-eshell-load-bash-aliases))

(use-package tramp-term
  :commands (tramp-term))


;;;; Проекты

(setq project-vc-extra-root-markers '(".project.el" "Gemfile" "package.json"))

(defun el-project-toggle-test ()
  "Jump between the current file and its test counterpart.
When no counterpart exists, visit the most likely path so the file can be
created in place."
  (interactive)
  (let* ((project (or (project-current) (user-error "Not in a project")))
         (root (project-root project))
         (file (or (buffer-file-name) (user-error "Buffer is not visiting a file")))
         (relative (file-relative-name file root))
         (candidates (el-project-counterparts relative)))
    (unless candidates
      (user-error "No test mapping for %s" relative))
    (find-file
     (expand-file-name
      (or (seq-find (lambda (c) (file-exists-p (expand-file-name c root))) candidates)
          (car candidates))
      root))))

(defun el-project-break-location-copy ()
  "Copy a debugger break location for the current line to the kill ring."
  (interactive)
  (let* ((file (or (buffer-file-name) (user-error "Buffer is not visiting a file")))
         (root (when-let ((project (project-current))) (project-root project)))
         (relative (if root (file-relative-name file root) file))
         (text (el-project-break-string relative (line-number-at-pos))))
    (kill-new text)
    (message "Copied: %s" text)))


;;;; Docker через tramp
;; Метод /docker: встроен в Emacs 29+ (tramp-container); docker-tramp не нужен.

(use-package docker
  :commands (docker))

(defun el-docker-find-file ()
  "Pick a running container and open its filesystem over tramp."
  (interactive)
  (let* ((output (shell-command-to-string
                  (format "docker ps --format '%s'" el-docker-ps-format)))
         (candidates (el-docker-parse-ps output)))
    (unless candidates
      (user-error "No running containers"))
    (let* ((label (completing-read "Container: " (mapcar #'car candidates) nil t))
           (entry (cdr (assoc label candidates)))
           (by (completing-read "Access by: " '("name" "id") nil t))
           (target (if (equal by "name") (car entry) (cdr entry))))
      (find-file (format "/docker:%s:/" target)))))


;;;; Файловые команды

(defun el-delete-file-and-buffer ()
  "Delete the file the current buffer visits, then kill the buffer."
  (interactive)
  (let ((filename (buffer-file-name)))
    (unless filename
      (user-error "Not a file visiting buffer"))
    (when (y-or-n-p (format "Do you really want to delete file %s ? " filename))
      (delete-file filename)
      (message "Deleted file %s." filename)
      (kill-buffer))))

(defun el-rename-file-and-buffer (new-name)
  "Rename both the current buffer and the file it visits to NEW-NAME."
  (interactive "sNew name: ")
  (let ((filename (buffer-file-name)))
    (unless filename
      (user-error "Buffer '%s' is not visiting a file" (buffer-name)))
    (when (get-buffer new-name)
      (user-error "A buffer named '%s' already exists" new-name))
    (rename-file filename new-name 1)
    (set-visited-file-name new-name)
    (rename-buffer new-name)
    (set-buffer-modified-p nil)))


;;;; Пароли

(use-package password-store
  :commands (password-store-get password-store-copy password-store-edit))


;;;; Dired

(setq dired-listing-switches "-alh --group-directories-first"
      dired-dwim-target t
      dired-kill-when-opening-new-dired-buffer t)

(use-package diredfl
  :hook (dired-mode . diredfl-mode))


;;;; Сниппеты

(use-package yasnippet
  :demand t
  :config
  (setq yas-snippet-dirs
        (list (expand-file-name "snippets" org-dir)
              (expand-file-name "snippets" user-emacs-directory)))
  (yas-global-mode 1))


;;;; Скобки

(use-package smartparens
  :demand t
  :config
  (require 'smartparens-config)
  (smartparens-global-mode 1)
  (show-paren-mode 1))


;;;; Воркспейсы

(use-package persp-mode
  :demand t
  :config
  (setq persp-nil-name "main"
        persp-auto-resume-time 0
        persp-auto-save-opt 1)
  (persp-mode 1))


;;;; Документация и Makefile

(use-package dash-docs
  :vc (:url "https://github.com/dash-docs-el/dash-docs.git" :rev :newest)
  :commands (dash-docs-search)
  :config
  (setq dash-docs-docsets-path (expand-file-name "~/.docsets")))

(use-package consult-dash
  :commands (consult-dash))

(use-package makefile-executor
  :vc (:url "https://github.com/Olivia5k/makefile-executor.el.git" :rev :newest)
  :commands (makefile-executor-execute-project-target))


;;;; Биндинги

(el-leader!
  "g"   '(:ignore t :which-key "git")
  "g g" '(magit-status :which-key "status")
  "g b" '(magit-blame-addition :which-key "blame")
  "g l" '(magit-log-current :which-key "log")
  "g d" '(magit-diff-buffer-file :which-key "diff file")

  "p"   '(:ignore t :which-key "project")
  "p p" '(project-switch-project :which-key "switch project")
  "p f" '(project-find-file :which-key "find file")
  "p b" '(consult-project-buffer :which-key "project buffer")
  "p d" '(project-dired :which-key "dired")
  "p c" '(project-compile :which-key "compile")
  "p k" '(project-kill-buffers :which-key "kill buffers")
  "p t" '(el-project-toggle-test :which-key "toggle impl/test")

  "f d" '(el-delete-file-and-buffer :which-key "delete file")
  "f R" '(el-rename-file-and-buffer :which-key "rename file")
  "f b" '(el-project-break-location-copy :which-key "copy break location")

  "o d" '(el-docker-find-file :which-key "docker tramp")
  "o t" '(vterm :which-key "vterm")
  "o e" '(eshell :which-key "eshell")
  "o D" '(docker :which-key "docker")

  "l"   '(:ignore t :which-key "lookup")
  "l f" '(consult-dash :which-key "docsets")
  "l p" '(dash-docs-search :which-key "docsets at point")

  "m"   '(:ignore t :which-key "make")
  "m p" '(makefile-executor-execute-project-target :which-key "project target")

  "b l" '(list-bookmarks :which-key "list bookmarks")
  "b d" '(bookmark-delete :which-key "delete bookmark")
  "b s" '(bookmark-set :which-key "set bookmark")

  "TAB"   '(:ignore t :which-key "workspace")
  "TAB n" '(persp-add-new :which-key "new")
  "TAB d" '(persp-kill :which-key "kill")
  "TAB ." '(persp-switch :which-key "switch"))

(provide 'el-tools)
;;; el-tools.el ends here
```

- [ ] **Step 10: Проверить загрузку модуля**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (dolist (fn (quote (el-project-toggle-test el-docker-find-file el-delete-file-and-buffer el-rename-file-and-buffer el-project-break-location-copy))) (unless (commandp fn) (error "%s is not a command" fn))) (unless yas-global-mode (error "yasnippet off")) (unless smartparens-global-mode (error "smartparens off")) (unless persp-mode (error "persp off")) (unless (file-directory-p (expand-file-name "snippets" org-dir)) (error "org snippets dir missing")) (message "tools ok"))'
```

Ожидается: `tools ok`.

- [ ] **Step 11: Проверить переход impl/test на реальном файле этого репозитория**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(princ (format "%S\n" (el-project-counterparts "lib/el-clock.el")))'
```

Ожидается: список, содержащий `"lib/el-clock-test.el"` — файл, который реально существует после задачи 6.

- [ ] **Step 12: Проверить docker-кандидатов на живом докере**

```bash
docker ps --format '{{.Names}}|{{.CreatedAt}}|{{.ID}}' | head -3
```

Если контейнеры есть — в интерактивном Emacs `SPC o d` должен показать их в том же виде и открыть `/docker:NAME:/`. Если контейнеров нет, запустить любой (`docker run -d --rm --name el-test alpine sleep 300`), проверить и остановить (`docker stop el-test`).

- [ ] **Step 13: Проверить вручную**

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Проверить: `SPC g g` открывает magit; `SPC o t` — vterm; `SPC o e` — eshell, и в нём работают bash-алиасы; `SPC p p` переключает проект; в `emacs.d/lib/el-clock.el` нажать `SPC p t` — открывается тест-файл; `SPC m p` предлагает цели Makefile; `SPC l f` ищет в docsets; `SPC TAB .` переключает воркспейсы; сниппеты из `~/org/snippets` раскрываются.

- [ ] **Step 14: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/lib/el-docker.el emacs.d/lib/el-project.el emacs.d/tests/el-docker-test.el emacs.d/tests/el-project-test.el emacs.d/modules/el-tools.el && git commit -m "feat(emacs): add el-tools module with tested docker and project helpers"
```

---

## Task 11: Модуль el-apps

**Files:**
- Create: `emacs.d/modules/el-apps.el`

**Interfaces:**
- Consumes: `org-dir` из `el-core`; `el-leader!` из `el-keys`.
- Produces: `el-eww-search-current-line`.

**Главное в этой задаче — `elfeed-org`.** В `doom.d/config.el` его нет: за пользователя это делал Doom-модуль `rss +org`. Без явной настройки `rmh-elfeed-org-files` elfeed откроется пустым, хотя фиды лежат в `~/org/elfeed.org`.

`google-translate` закреплён на коммите `6f7b75b2aa1ff4e50b6f1579cafddafae5705dbd` (как в `doom.d/packages.el`), потому что рабочий хак `google-translate--search-tkk` привязан к этой версии.

- [ ] **Step 1: Убедиться, что файл с фидами на месте**

```bash
head -5 ~/org/elfeed.org && grep -c "^\*" ~/org/elfeed.org
```

Ожидается: org-структура и число заголовков больше нуля.

- [ ] **Step 2: Написать `modules/el-apps.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-apps.el --- Browser, feeds, chat, books, translation, finances, pdf

;;; Code:

(require 'el-core)
(require 'el-keys)


;;;; Браузер

(setq browse-url-browser-function #'eww-browse-url)

(defun el-eww-search-current-line ()
  "Trim the current line, select it and search the web for it with eww."
  (interactive)
  (let* ((start (line-beginning-position))
         (end (line-end-position))
         (trimmed (string-trim (buffer-substring-no-properties start end))))
    (delete-region start end)
    (insert trimmed)
    (set-mark (point))
    (goto-char start)
    (eww-search-words)))

(el-leader!
  "e"   '(:ignore t :which-key "eww")
  "e e" '(eww :which-key "eww")
  "e l" '(eww-list-buffers :which-key "list buffers")
  "e f" '(el-eww-search-current-line :which-key "search current line")
  "e s" '(eww-search-words :which-key "search words")
  "e y" '(eww-copy-page-url :which-key "copy url"))


;;;; Фиды
;; rmh-elfeed-org-files Doom задавал за нас в модуле rss +org.
;; Без него elfeed открывается пустым, хотя фиды лежат в ~/org/elfeed.org.

(use-package elfeed
  :commands (elfeed)
  :config
  (setq elfeed-search-filter "@1-month-ago +unread"
        elfeed-db-directory (expand-file-name "~/elfeed.db")))

(use-package elfeed-org
  :vc (:url "https://github.com/remyhonig/elfeed-org.git" :rev :newest)
  :after elfeed
  :demand t
  :config
  (setq rmh-elfeed-org-files (list (expand-file-name "elfeed.org" org-dir)))
  (elfeed-org))


;;;; Чат

(use-package telega
  :commands (telega)
  :config (setq telega-use-docker t))


;;;; Книги

(use-package nov
  :vc (:url "https://depp.brause.cc/nov.el.git" :rev :newest)
  :mode ("\\.epub\\'" . nov-mode))


;;;; Перевод
;; Пин на коммит из doom.d/packages.el: хак search-tkk привязан к версии.

(use-package google-translate
  :vc (:url "https://github.com/atykhonov/google-translate.git"
       :rev "6f7b75b2aa1ff4e50b6f1579cafddafae5705dbd")
  :demand t
  :bind (("C-c t" . google-translate-at-point)
         ("C-c r" . google-translate-at-point-reverse)
         ("C-c T" . google-translate-query-translate))
  :config
  (setq google-translate-default-source-language "en"
        google-translate-default-target-language "ru"
        google-translate-backend-method 'curl)
  (defun google-translate--search-tkk ()
    "Search TKK."
    (list 430675 2721866130)))


;;;; Финансы

(use-package hledger-mode
  :vc (:url "https://github.com/narendraj9/hledger-mode.git" :rev :newest)
  :mode ("\\.journal\\'" . hledger-mode)
  :config
  (setq hledger-jfile (expand-file-name "finances/ledger.journal" org-dir)))


;;;; PDF
;; pdf-tools требует собранного epdfinfo, которого под Termux нет.

(use-package pdf-tools
  :unless (el-termux-p)
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config (pdf-tools-install :no-query))


;;;; Календарь

(el-leader!
  "o c" '(calendar :which-key "calendar")
  "o r" '(elfeed :which-key "rss")
  "o g" '(telega :which-key "telegram"))

(provide 'el-apps)
;;; el-apps.el ends here
```

- [ ] **Step 3: Проверить, что фиды действительно подхватились**

Это главная проверка задачи: именно здесь ломался бы молчаливый переход.

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (require (quote elfeed)) (require (quote elfeed-org)) (unless rmh-elfeed-org-files (error "rmh-elfeed-org-files empty")) (unless (file-exists-p (car rmh-elfeed-org-files)) (error "feeds file missing: %s" (car rmh-elfeed-org-files))) (elfeed-org) (unless elfeed-feeds (error "no feeds loaded")) (message "feeds ok: %d" (length elfeed-feeds)))'
```

Ожидается: `feeds ok: N`, где N больше нуля.

- [ ] **Step 4: Проверить остальные настройки модуля**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(progn (unless (eq browse-url-browser-function (function eww-browse-url)) (error "browser=%S" browse-url-browser-function)) (unless (equal "ru" google-translate-default-target-language) (error "translate target wrong")) (unless (equal (list 430675 2721866130) (google-translate--search-tkk)) (error "tkk hack missing")) (unless (string-suffix-p "finances/ledger.journal" hledger-jfile) (error "hledger file=%s" hledger-jfile)) (unless (assoc "\\.epub\\'" auto-mode-alist) (error "epub not registered")) (message "apps ok"))'
```

Ожидается: `apps ok`.

- [ ] **Step 5: Проверить вручную**

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Проверить: `SPC o r` открывает elfeed со списком статей (не пустой); `SPC e e` открывает eww; на слове `C-c t` переводит en→ru; открыть `~/org/finances/ledger.journal` — включается hledger-mode; открыть любой pdf — pdf-view; `SPC o g` запускает telega.

- [ ] **Step 6: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/modules/el-apps.el && git commit -m "feat(emacs): add el-apps module with explicit elfeed-org wiring"
```

---

## Task 12: Платформенные модули el-desktop и el-mobile

**Files:**
- Create: `emacs.d/modules/el-desktop.el`
- Create: `emacs.d/modules/el-mobile.el`

**Interfaces:**
- Consumes: `workspace-dir` из `el-core`.
- Produces: ничего для других модулей — это последний модуль в порядке загрузки.

- [ ] **Step 1: Написать `modules/el-desktop.el`**

```elisp
;; -*- lexical-binding: t; -*-
;;; el-desktop.el --- Desktop-only settings

;;; Code:

(require 'el-core)

(use-package xclip
  :demand t
  :config (xclip-mode 1))

(provide 'el-desktop)
;;; el-desktop.el ends here
```

- [ ] **Step 2: Написать `modules/el-mobile.el`**

Из `doom.d/mobile.el` переносится всё, кроме `org-roam-node-display-template`: модуля org-roam в конфиге нет (см. «Выброшено осознанно» в спеке).

```elisp
;; -*- lexical-binding: t; -*-
;;; el-mobile.el --- Termux-only settings

;;; Commentary:
;; Грузится последним, поэтому может переопределять настройки любого
;; модуля выше.  org-mobile-mode живёт в dotfiles/lisp и нужен только здесь.

;;; Code:

(require 'el-core)
(require 'el-boot)

(add-to-list 'load-path
             (expand-file-name "lisp/org-mobile-mode" workspace-dir))
(el-require-module 'org-mobile-mode)

(when (featurep 'org-mobile-mode)
  (add-hook 'org-mode-hook #'org-mobile-mode))

;; Узкий экран: повестка без префиксов, без номеров строк.
(setq org-agenda-prefix-format '((agenda . " "))
      display-line-numbers-type nil)

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (remove-hook hook #'display-line-numbers-mode))

(provide 'el-mobile)
;;; el-mobile.el ends here
```

- [ ] **Step 3: Проверить обе ветки развилки**

```bash
cd ~/dotfiles/emacs.d && make smoke && make smoke-termux
```

Ожидается: `smoke ok` в обоих случаях. Это и есть проверка Review Focus 4: под Termux конфиг поднимается целиком, несмотря на отсутствие X11-зависимостей.

- [ ] **Step 4: Проверить, что развилка выбрала правильный модуль**

```bash
cd ~/dotfiles/emacs.d && emacs -batch --init-directory $(pwd) --eval '(princ (format "desktop=%s mobile=%s\n" (featurep (quote el-desktop)) (featurep (quote el-mobile))))' && TERMUX_VERSION=1 emacs -batch --init-directory $(pwd) --eval '(princ (format "desktop=%s mobile=%s agenda-prefix=%S\n" (featurep (quote el-desktop)) (featurep (quote el-mobile)) org-agenda-prefix-format))'
```

Ожидается: первый вызов `desktop=t mobile=nil`, второй `desktop=nil mobile=t` с `agenda-prefix=((agenda . " "))`.

- [ ] **Step 5: Коммит**

```bash
cd ~/dotfiles && git add emacs.d/modules/el-desktop.el emacs.d/modules/el-mobile.el && git commit -m "feat(emacs): add platform modules for desktop and termux"
```

---

## Task 13: Сверка полноты, документация и cutover

**Files:**
- Create: `docs/superpowers/plans/2026-10-15-vanilla-emacs-migration-audit.md`
- Modify: `README.org`

**Interfaces:**
- Consumes: всё предыдущее.
- Produces: аудит соответствия и переключённый симлинк.

- [ ] **Step 1: Выписать все настройки старого конфига**

```bash
cd ~/dotfiles && grep -nE "^\(?(setq|setq-default|defun|defmacro|defvar|use-package|use-package!|after!|map!|add-to-list|add-hook|global-set-key|require|unpin!|package!)" doom.d/*.el > /tmp/doom-inventory.txt && wc -l /tmp/doom-inventory.txt
```

- [ ] **Step 2: Составить аудит соответствия**

Создать `docs/superpowers/plans/2026-10-15-vanilla-emacs-migration-audit.md` с таблицей из трёх колонок: строка старого конфига → куда переехала (файл нового конфига) → либо отметка «выброшено осознанно» со ссылкой на соответствующую строку раздела спеки.

Пройти `/tmp/doom-inventory.txt` сверху донизу. Каждая строка обязана получить одну из двух отметок. Пустых строк в таблице быть не должно — это и есть смысл сверки.

```bash
cd ~/dotfiles && for f in emacs.d/init.el emacs.d/early-init.el emacs.d/lib/*.el emacs.d/modules/*.el; do echo "== $f"; grep -cE "^\(?(setq|defun|defmacro|defvar|use-package|el-leader!)" "$f"; done
```

- [ ] **Step 3: Закрыть обнаруженные пропуски**

Если сверка нашла настройку, которой нет ни в новом конфиге, ни в списке выброшенного — добавить её в соответствующий модуль, прогнать `make test && make smoke`, закоммитить отдельно. Если нашлась настройка, которую осознанно не переносим, но её нет в спеке — дописать строку в раздел «Выброшено осознанно» спеки.

- [ ] **Step 4: Прогнать полную проверку**

```bash
cd ~/dotfiles/emacs.d && make test && make smoke && make smoke-termux
```

Ожидается: тесты зелёные, `smoke ok` дважды.

- [ ] **Step 5: Замерить время старта**

```bash
cd ~/dotfiles/emacs.d && emacs --init-directory $(pwd) --eval '(message "startup: %s" (emacs-init-time))' --eval '(kill-emacs)'
```

Записать значение в аудит. Для сравнения — то же на Doom:

```bash
emacs --eval '(message "doom startup: %s" (emacs-init-time))' --eval '(kill-emacs)'
```

- [ ] **Step 6: Дополнить README.org**

```bash
cd ~/dotfiles && cat >> README.org <<'EOF'
* Emacs
** Параллельный запуск нового конфига
#+begin_src sh
emacs --init-directory ~/dotfiles/emacs.d
#+end_src
** Проверки
#+begin_src sh
cd ~/dotfiles/emacs.d
make test          # юнит-тесты чистой логики из lib/
make smoke         # полный старт конфигурации
make smoke-termux  # то же с развилкой под Termux
#+end_src
** Установка
~/.config/emacs отводится в сторону, а не удаляется: это git-репозиторий Doom,
через него же делается откат.
#+begin_src sh
mv ~/.config/emacs ~/.config/emacs.doom
ln -s ~/dotfiles/emacs.d ~/.config/emacs
#+end_src
** Откат на Doom
#+begin_src sh
rm ~/.config/emacs
mv ~/.config/emacs.doom ~/.config/emacs
#+end_src
EOF
```

- [ ] **Step 7: Коммит документации до переключения**

```bash
cd ~/dotfiles && git add README.org docs/superpowers/plans/2026-10-15-vanilla-emacs-migration-audit.md && git commit -m "docs(emacs): add migration audit and emacs section in README"
```

- [ ] **Step 8: Cutover**

`doom.d/` не трогается, симлинк `~/.config/doom` остаётся на месте.

```bash
mv ~/.config/emacs ~/.config/emacs.doom && ln -s ~/dotfiles/emacs.d ~/.config/emacs && ls -la ~/.config/emacs ~/.config/doom
```

Ожидается: `~/.config/emacs -> /home/azx/dotfiles/emacs.d`, `~/.config/doom -> /home/azx/dotfiles/doom.d/`.

- [ ] **Step 9: Проверить запуск без флагов**

```bash
emacs --eval '(message "failed=%S startup=%s" el-failed-modules (emacs-init-time))' --eval '(kill-emacs)'
```

Ожидается: `failed=nil`. Затем интерактивно:

```bash
emacs
```

Проверить по одному пункту из каждого модуля: `SPC n a` (повестка), `SPC d j` (журнал), `SPC a g` (gptel), `SPC g g` (magit), `SPC o r` (elfeed), `SPC o t` (vterm), `SPC x` (capture).

- [ ] **Step 10: Проверить, что откат работает**

Откат надо проверить до того, как он понадобится.

```bash
rm ~/.config/emacs && mv ~/.config/emacs.doom ~/.config/emacs && emacs --eval '(message "doom back: %s" (emacs-init-time))' --eval '(kill-emacs)'
```

Ожидается: Doom стартует. После проверки вернуть новый конфиг:

```bash
mv ~/.config/emacs ~/.config/emacs.doom && ln -s ~/dotfiles/emacs.d ~/.config/emacs
```

- [ ] **Step 11: Финальный коммит**

```bash
cd ~/dotfiles && git status --short && git add -A && git commit -m "chore(emacs): complete migration to vanilla config" && git log --oneline master..HEAD
```

---

## Отложено за пределы плана

**mu4e.** Единственный пункт, где нет исходника для переноса: `~/.mail` и индекс `~/.cache/mu/xapian` существуют, `mu` и `offlineimap` установлены, но конфигурации mu4e в `doom.d/config.el` нет — всё держалось на дефолтах модуля `mu4e +gmail` (путь к maildir, контексты, команда синхронизации, org-msg). Это отдельная работа по написанию конфига с нуля, а не миграция, поэтому она требует собственного брейншторма и плана. До тех пор `el-apps` mu4e не грузит, а Doom остаётся доступен через `~/.config/emacs.doom` для чтения почты.
