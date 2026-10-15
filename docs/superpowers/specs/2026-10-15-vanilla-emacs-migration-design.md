# Миграция конфигурации Doom Emacs на vanilla Emacs

Дата: 2026-10-15
Статус: дизайн согласован, реализация не начата

## Цель

Перенести рабочую конфигурацию Doom Emacs (`dotfiles/doom.d/`, 566 строк в
`config.el` плюс `init.el`, `packages.el`, `mobile.el`, `desktop.el`) на
vanilla Emacs 31.0.50. Весь новый конфиг живёт в папке
`~/dotfiles/emacs.d/`, подключаемой симлинком `~/.config/emacs`.

Успех: Emacs стартует без Doom, без ошибок загрузки модулей, и ежедневные
рабочие сценарии (org/GTD, denote, gptel, magit, elfeed, vterm) работают
так же, как до миграции.

### Критерии успеха

1. Батч-старт нового конфига завершается без ошибок и с пустым списком
   `el-failed-modules`.
2. Каждый пункт таблицы этапов (раздел «Порядок миграции») проверен
   вручную и отмечен выполненным.
3. Сверка по `grep` показывает, что каждый `setq`, `defun`, `map!` и
   `use-package` из `doom.d/` либо перенесён, либо присутствует в списке
   осознанно выброшенного (раздел «Выброшено осознанно»).
4. Doom остаётся запускаемым в любой момент миграции и после неё.

### Вне объёма

- Конфигурация mu4e (см. «Единственный пункт без исходника»).
- Переработка содержимого `~/org/` и локальных пакетов в `dotfiles/lisp/`.
- Удаление или переименование `doom.d/` — папка остаётся в репозитории
  как есть, бессрочно.

## Принятые решения

| вопрос | решение | причина |
|---|---|---|
| модальное редактирование | `evil` + `evil-collection` + `general.el` | 14 блоков `map! :leader` переносятся в `general-define-key` почти механически; мышечная память SPC-словаря сохраняется |
| менеджер пакетов | встроенный `package.el` + `use-package` + `:vc` | всё в ядре Emacs 31; `:vc` покрывает git-рецепты (`gptel` master, `nov` с depp.brause.cc, `acp`, `agent-shell`, `gptel-agent`) |
| поиск и дополнение | `vertico` + `orderless` + `marginalia` + `consult` + `embark`, `corfu` + `cape` | строится на штатном `completing-read`; уход от helm/company |
| объём переноса | только то, что реально установлено и работает | мёртвые блоки конфига не воспроизводим; история git сохраняет их |
| Doom-удобства | тема + modeline, smartparens, yasnippet, воркспейсы + zen | все четыре воспроизводим |
| проекты | встроенный `project.el` + `consult` | согласуется с vertico-стеком и с уже существующим `my-break-location`, который использует `project-current` |
| структура | тонкий `init.el` + `modules/*.el` | правки локальны, сбойный модуль не валит остальные |
| локальные пакеты | остаются в `dotfiles/lisp/` | load-path строится от `workspace-dir`, как сейчас |
| базовый SPC-словарь | ядро ~40 биндов | Doom `default +bindings` даёт ~200; воспроизводим только то, что рука ищет ежедневно |

## Структура

```
emacs.d/
  early-init.el
  init.el
  modules/
    el-core.el
    el-ui.el
    el-keys.el
    el-completion.el
    el-org.el
    el-denote.el
    el-ai.el
    el-tools.el
    el-apps.el
    el-local.el
    el-mobile.el
    el-desktop.el
  snippets/
  var/        (gitignored)
  etc/        (gitignored)
  elpa/       (gitignored)
  eln-cache/  (gitignored)
```

Каждый модуль заканчивается `(provide 'el-<name>)`. Внутри модулей
сохраняется существующая привычка разделять секции символом перевода
страницы `^L`.

## Загрузка и изоляция

### `early-init.el`

Выполняется до инициализации пакетов и до создания первого фрейма:

- `gc-cons-threshold` поднимается на время старта и возвращается в
  рабочее значение на `emacs-startup-hook` (замена Doom-овскому `gcmh`).
- toolbar/scrollbar/menubar отключаются через `default-frame-alist`, а не
  через `(tool-bar-mode -1)` — иначе фрейм успевает отрисоваться и мигнуть.
- `fullscreen . fullboth` в `default-frame-alist` вместо вызова
  `toggle-frame-fullscreen` в конце конфига.
- `package-enable-at-startup nil` — активацией управляет `init.el` явно.

### `init.el`

Только bootstrap и порядок загрузки, никакой конфигурации пакетов:

1. `package-archives`: GNU ELPA, NonGNU ELPA, MELPA; `package-initialize`.
2. `use-package-always-ensure t` — каждый `use-package` сам доставляет
   пакет; это роль, которую в Doom играл `packages.el`.
3. `modules/` добавляется в `load-path`.
4. Последовательность `require` модулей.

### Порядок загрузки

`el-core` → `el-keys` → `el-completion` → `el-ui` → `el-org` → `el-denote`
→ `el-ai` → `el-tools` → `el-apps` → `el-local` → `el-mobile` | `el-desktop`

Порядок не произвольный:

- `el-core` первым, потому что определяет `workspace-dir`, `org-dir`,
  `projects-dir` и `el-termux-p`, от которых зависят пути во всех
  остальных модулях.
- `el-keys` до предметных модулей, потому что создаёт `el-leader!`;
  без него модули не могут вешать свои биндинги.
- платформенный модуль последним, чтобы мог переопределять что угодно
  выше (именно так работает текущая развилка в конце `config.el`).

### Изоляция ошибок

Сейчас ошибка в середине `config.el` обрывает загрузку всего, что ниже.
Каждый `require` оборачивается так, что сбойный модуль:

- логируется в `*Messages*` с текстом ошибки,
- добавляется в список `el-failed-modules`,
- не препятствует загрузке остальных модулей.

Emacs всегда поднимается до рабочего состояния, а не до `--debug-init`.
`el-failed-modules` используется как критерий в батч-проверке.

### Рантайм-файлы

`no-littering` плюс `.gitignore` на `emacs.d/var/`, `emacs.d/etc/`,
`emacs.d/elpa/`, `emacs.d/eln-cache/`. Без этого симлинк
`~/.config/emacs → dotfiles/emacs.d` приведёт к записи автосейвов,
recentf, bookmarks и eln-кеша прямо в git-репозиторий dotfiles.

## Биндинги

`el-keys.el` поднимает `evil`, `evil-collection`, `evil-org`,
`evil-surround`, затем `general.el` и создаёт
`general-create-definer el-leader!` на `SPC` в normal/visual и на
`M-SPC` в insert/emacs — чтобы леадер был доступен в минибуфере и в
терминальных буферах.

Биндинги предметных модулей объявляются в этих же модулях через
`el-leader!`, рядом с настройкой пакета, а не в общей свалке — в отличие
от текущего состояния, где 14 блоков `map!` разбросаны по `config.el`.

Трансляция:

```elisp
;; было
(map! :leader :prefix "d" :desc "denote" "n" #'denote)
;; стало
(el-leader! "dn" '(denote :which-key "denote"))
```

`which-key` в Emacs 31 встроен, отдельный пакет не нужен.

### Ядро базового словаря (~40 биндов)

Воспроизводим префиксы, отсутствие которых рука заметит сразу:
`f` (файлы), `b` (буферы), `w` (окна), `g` (git/magit), `p` (проект),
`h` (help), `s` (поиск), `q` (quit), `SPC SPC`, `:` (M-x).
Остальное из Doom `default +bindings` добавляется по факту — когда рука
потянется и не найдёт.

### Исправления при переносе

Три вещи в текущих биндингах воспроизводить не следует:

1. **`SPC d n` сломан.** В denote-блоке `config.el` клавиша `"n"`
   забиндена дважды: сначала на `denote`, затем на
   `my/denote-journal-open-next-day`. Побеждает вторая, то есть `denote`
   недостижим с леадера. Решение: `SPC d n` → `denote`, а next/prev day
   → `SPC d ]` / `SPC d [`.
2. **Префикс `SPC d` делят denote и docker** (`SPC d d` →
   `my/helm-docker-containers`). Docker в «заметочном» префиксе —
   случайность истории. Решение: docker → `SPC o d`.
3. **Мёртвые биндинги выкидываем**: `SPC k ...` (5 kubernetes),
   `SPC [ ...` (5 rspec), `C-h r` (whisper). `SPC l p` / `SPC l f`
   переезжают с `helm-dash` на `dash-docs` — каталог `~/.docsets`
   существует и сохраняется.

### Замены под новый стек

| было | стало |
|---|---|
| `SPC ,` → `switch-to-buffer` | `consult-buffer` |
| `SPC p t` → `projectile-toggle-between-implementation-and-test` | `el-project-toggle-test` на `project.el` |
| `<tab>` → `company-complete` в `company-mode-map` | `corfu` (TAB по умолчанию) |

## Трансляция Doom-измов

| Doom | vanilla |
|---|---|
| `use-package!` | `use-package` |
| `after!` | `:after` / `with-eval-after-load` |
| `package!` / `unpin!` | `:ensure` / `:vc` |
| `map!` | `el-leader!` / `general-define-key` |
| `doom-theme` | `load-theme` |
| `doom-font`, `doom-variable-pitch-font` | `set-face-attribute` — **`:size 50` в `font-spec` это пиксели, а `:height` в face-attribute — десятые пункта; значение пересчитывается, а не копируется** |
| `remove-hook!` | `remove-hook` |
| `display-line-numbers-type` + авто-включение модулем | `global-display-line-numbers-mode` / хук явно |
| `emacs-dir` = `doom.d/` | `user-emacs-directory` |

## Скрытые зависимости от Doom-модулей

То, что Doom делал неявно и в vanilla должно стать явным — иначе
отвалится молча:

1. **`elfeed-org`.** В `~/org/elfeed.org` лежат фиды, но в `config.el`
   нет ни слова про `rmh-elfeed-org-files` — это делал модуль `rss +org`.
   Нужен явный `use-package elfeed-org` с указанием на этот файл, иначе
   elfeed откроется пустым.
2. **Транзитивные пакеты.** Приходили через модули и теперь требуют
   собственных `use-package`: `makefile-executor`, `dash-docs`,
   `visual-fill-column`, `yasnippet`, `smartparens`, `persp-mode`,
   `pdf-tools`, `doom-themes`, `doom-modeline`, `nerd-icons`,
   `org-pomodoro`.
3. **`/docker:` TRAMP.** Настройка `docker-tramp-use-names` относится к
   устаревшему `docker-tramp`; в Emacs 29+ метод `/docker:` встроен
   (`tramp-container`). Настройку выкидываем, функциональность остаётся.

### Единственный пункт без исходника: mu4e

`~/.mail` и индекс `~/.cache/mu/xapian` существуют, `mu` и `offlineimap`
установлены — почта реальна. При этом конфигурации mu4e в `config.el` нет
вообще: всё держалось на дефолтах модуля `mu4e +gmail` (путь к maildir,
контексты, команда синхронизации, org-msg для композа).

Это не перенос, а написание конфига с нуля. Выносится в этап 5, после
того как основное заработает. До тех пор `el-apps` mu4e не грузит.

## Распределение по модулям

| модуль | содержимое |
|---|---|
| `el-core` | `workspace-dir`, `projects-dir`, `org-dir`, `user-full-name`, `user-mail-address`, `el-termux-p`, epa/gpg + `epg-pinentry-mode 'loopback`, `auto-save-visited` для org (интервал 5 с), `global-auto-revert-mode`, `winner-mode`, `no-littering` |
| `el-ui` | `doom-themes` + `doom-monokai-pro`, `doom-modeline` + `nerd-icons`, шрифты, `display-line-numbers`, writeroom/`visual-fill-column`, `world-clock-list` |
| `el-keys` | evil, evil-collection, evil-org, evil-surround, general, `el-leader!`, ядро ~40 биндов, `x-super-keysym` под guard'ом X11 |
| `el-completion` | vertico, orderless, marginalia, consult, embark, corfu, cape, `savehist` |
| `el-org` | org + `org-habit`, agenda-файлы из `~/org/projects/`, `org-todo-keywords`, clock + persist, 4 шаблона capture, `org-drill` (sm2), `org-attach`, `hms-to-pomodoros` / `hms-to-minutes`, polybar-функции, `org-pomodoro`, `ob-async`, `org-babel-do-load-languages` с `http` и `search` |
| `el-denote` | denote, denote-journal, `denote-extras`, биндинги `SPC d` |
| `el-ai` | gptel (OpenRouter + Ollama, presets `assistant` и `english-cards`, `gptel-make-safe-tool`, тул `search_trains`, `my/gptel-rewrite-buffer`), acp, agent-shell, gptel-agent, биндинги `SPC a` |
| `el-tools` | magit, vterm, eshell + загрузка bash-алиасов, `project.el` + `el-project-toggle-test`, pass/password-store, docker через `completing-read`, makefile-executor, dired, yasnippet, dash-docs, tramp-term, `delete-file-and-buffer`, `rename-file-and-buffer`, `my-break-location` + copy, smartparens, persp-mode |
| `el-apps` | eww + `eww-search-current-line` + биндинги `SPC e`, elfeed + **elfeed-org**, telega (`telega-use-docker t`), nov, google-translate + хак `google-translate--search-tkk`, hledger-mode + `auto-mode-alist` на `.journal`, calendar, pdf-tools |
| `el-local` | load-path на `dotfiles/lisp/{org-mobile-mode,open-meteo,denote-extras,org-babel-search,logbook-table}` + require |
| `el-mobile` | `org-agenda-prefix-format` для узкого экрана, отключение номеров строк, `org-mobile-mode` в `org-mode-hook` |
| `el-desktop` | `xclip-mode` |

### Важное уточнение

`hms-to-pomodoros` и `hms-to-minutes` не вызываются из elisp, но
используются в формулах org-таблиц в `~/org/tasks/*.org` и
`~/org/snippets/org-mode/*`. Это не мусор, их нужно перенести.

## Выброшено осознанно

Список существует, чтобы «потерялось» и «выброшено осознанно» не путались
при финальной сверке.

| что | причина |
|---|---|
| `org-insert-photos` | вызывает `org--photos-list`, которая не определена ни в одном файле репозитория — функция сломана |
| блок `whisper` + `C-h r` | пакета нет в `packages.el`; подтверждено, что не нужен, хотя `~/dev/whisper.cpp` собран |
| биндинги `SPC k ...` (kubernetes) | `kubernetes-el` отсутствует в `packages.el` и в модулях — биндинги указывают на несуществующие команды |
| биндинги `SPC [ ...` (rspec) | то же |
| `multi-term-program-switches` | пакета `multi-term` нет ни в `packages.el`, ни в Doom-модулях — настройка ни на что не влияла (найдено сверкой полноты на этапе 4) |
| `ivy-re-builders-alist` | модуль `ivy` в `init.el` закомментирован |
| `helm-mode-fuzzy-match` | helm уходит вместе с переходом на vertico |
| `org-roam-node-display-template` в `mobile.el` | модуля `org-roam` в `init.el` нет |
| `(setq-local outline-regexp "^\f")` в начале `config.el` | в загружаемом файле действует на временный буфер, то есть ни на что |
| `docker-tramp-use-names` | устаревший пакет; `/docker:` встроен в Emacs 29+ |
| `~/emacs.d/mysnippets` в `yas-snippet-dirs` | каталог не существует; заменяется на `emacs.d/snippets` |
| `helm-dash` / `helm-dash-at-point` | заменяются на `dash-docs`; `~/.docsets` сохраняется |
| `my/helm-docker-containers` на helm API | переписывается на `completing-read` (двухшаговый выбор контейнера и способа доступа сохраняется) |
| `projectile`, `helm-projectile` | заменяются на `project.el` + consult |
| `toggle-frame-fullscreen` вызовом | заменяется на `default-frame-alist` |

## Порядок миграции

Весь период миграции Doom остаётся рабочим конфигом. Новый запускается
рядом, без переключения чего-либо:

```bash
emacs --init-directory ~/dotfiles/emacs.d
```

Автоматическая проверка, падающая при сбое любого модуля:

```bash
emacs --batch --init-directory ~/dotfiles/emacs.d \
  --eval '(if el-failed-modules (error "failed: %S" el-failed-modules) (message "ok"))'
```

Каждый этап — отдельный коммит с рабочим состоянием.

| этап | содержимое | критерий готовности |
|---|---|---|
| 0 | `early-init`, `init`, `el-core`, `el-keys`, `el-ui`, `el-completion` | батч-старт зелёный; `SPC f f`, `SPC b b`, `SPC :` работают; тема и modeline на месте |
| 1 | `el-org`, `el-denote`, `el-local` | agenda собирается из `~/org/projects/`; `SPC x` даёт все 4 шаблона capture; clock-persist подхватывает историю; `SPC d n` создаёт заметку; `ob-search`, `logbook-table`, `open-meteo` грузятся |
| 2 | `el-ai` | `SPC a g` открывает gptel в org-mode; ключ достаётся из `pass env/OPENROUTER_API_KEY`; presets `assistant` и `english-cards` в меню; тул `search_trains` вызывается |
| 3 | `el-tools`, `el-apps` | magit, vterm, `SPC o d` (docker через tramp), elfeed показывает фиды из `~/org/elfeed.org`, `C-c t` переводит, pdf открывается |
| 4 | cutover | симлинк переключён, Emacs стартует без флагов |
| 5 | опционально, позже | mu4e с нуля |

### Сверка полноты

В конце этапа 3: `grep` по `doom.d/*.el` на каждый `setq`, `defun`, `map!`
и `use-package`, построчная сверка с новым конфигом. Всё, что не
перенесено, обязано присутствовать в разделе «Выброшено осознанно».

### Cutover и откат

`~/.config/emacs` — это сам git-репозиторий Doom; он не удаляется, а
переименовывается:

```bash
mv ~/.config/emacs ~/.config/emacs.doom
ln -s ~/dotfiles/emacs.d ~/.config/emacs
```

Симлинк `~/.config/doom → ~/dotfiles/doom.d/` остаётся на месте, папка
`doom.d/` остаётся в репозитории как есть. Откат — обратная перестановка:

```bash
rm ~/.config/emacs
mv ~/.config/emacs.doom ~/.config/emacs
```

### Документация

`README.org` дополняется разделом про Emacs: команда симлинка, команда
параллельного запуска, команда батч-проверки.
