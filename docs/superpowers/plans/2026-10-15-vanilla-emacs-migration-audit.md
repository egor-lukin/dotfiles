# Аудит полноты миграции doom.d → emacs.d

Дата: 2026-10-15
Метод: `doom.d/*.el` разобраны лисп-ридером (не grep — он не видит переменные
в многострочных `setq`), получено 128 настроек; каждая сверена с
`emacs.d/{init,early-init}.el`, `emacs.d/lib/*.el`, `emacs.d/modules/*.el`.

| итог | число |
|---|---|
| перенесено под тем же именем | 89 |
| перенесено под новым именем или в другой форме | 22 |
| выброшено осознанно (раздел «Выброшено осознанно» спеки) | 15 |
| Doom-макросы, не являющиеся настройкой (`doom!`, `map!`, `after!`, `remove-hook!`) | 2 вида |
| **пропущено по недосмотру — найдено и закрыто этим аудитом** | **2** |

## Пропуски, найденные аудитом

| настройка | что было | чем закрыто |
|---|---|---|
| `projectile-project-search-path '("~/dev")` | projectile сам находил проекты в `~/dev` | `project-remember-projects-under projects-dir` в `el-tools`. Без этого `SPC p p` показывал бы пустой список вместо 173 проектов. Замер: 0.10 с на старте. Попутно `projects-dir` из `el-core` перестал быть мёртвой переменной. |
| `multi-term-program-switches "--login"` | настройка пакета `multi-term` | Ничем: пакета нет ни в `doom.d/packages.el`, ни в Doom-модулях, то есть настройка ни на что не влияла. Дописана в раздел «Выброшено осознанно» спеки. |

## Перенесено под новым именем

| doom.d | emacs.d |
|---|---|
| `polybar--default-header` | `el-org-polybar-idle-text` |
| `polybar--format-line` | `el-clock-format-line` (`lib/el-clock.el`, покрыт тестом) |
| `polybar-current-clock-line` | `el-org-polybar-clock-line` |
| `my/helm-docker-containers` | `el-docker-find-file` + `el-docker-parse-ps` (`lib/el-docker.el`, 5 тестов) |
| `my/gptel-rewrite-buffer` | `el-ai-rewrite-buffer` |
| `my-break-location`, `my-break-location-copy` | `el-project-break-string` (тест) + `el-project-break-location-copy` |
| `hms-to-minutes`, `hms-to-pomodoros` | имена сохранены — вызываются из формул org-таблиц в `~/org/tasks` |
| `doom-theme` | `load-theme 'doom-monokai-pro` |
| `doom-font`, `doom-variable-pitch-font` | `el-apply-fonts` через `set-face-attribute`, `:height 375` вместо `:size 50` (пиксели → десятые пункта) |
| `toggle-frame-fullscreen` вызовом | `(fullscreen . fullboth)` в `default-frame-alist` |
| `global-set-key` × 3 для google-translate | `:bind` в `use-package google-translate` |
| `add-to-list 'auto-mode-alist` для `.journal` | `:mode` в `use-package hledger-mode` |
| `helm-dash-docsets-path` | `dash-docs-docsets-path` |
| `projectile-toggle-between-implementation-and-test` | `el-project-toggle-test` + `el-project-counterparts` (`lib/el-project.el`, 10 тестов) |
| `eshell-load-bash-aliases` | `el-eshell-load-bash-aliases` |
| `eww-search-current-line` | `el-eww-search-current-line` |
| `delete-file-and-buffer`, `rename-file-and-buffer` | `el-delete-file-and-buffer`, `el-rename-file-and-buffer` |
| `termux-p` | `el-termux-p` |

## Добавлено, чего в doom.d не было

Не Doom-измы, а то, что Doom делал за конфиг неявно:

| что | почему |
|---|---|
| `elfeed-org` + `rmh-elfeed-org-files` | давал модуль `rss +org`; без явной настройки elfeed открывается пустым при 115 заголовках фидов в `~/org/elfeed.org` (проверено: 102 фида разбираются) |
| `use-package` для `makefile-executor`, `dash-docs`, `visual-fill-column`, `yasnippet`, `smartparens`, `persp-mode`, `pdf-tools`, `doom-themes`, `doom-modeline`, `nerd-icons`, `org-pomodoro` | приходили транзитивно через Doom-модули |
| `el-require-module` + `el-failed-modules` | в Doom сбой в середине `config.el` обрывал всё ниже |
| `no-littering` | Doom уводил рантайм в `.local/`; без этого Emacs писал бы в git-репозиторий dotfiles |
| `project-remember-projects-under` | см. раздел про пропуски |

## Исправлено при переносе

| что | было | стало |
|---|---|---|
| `SPC d n` | клавиша забиндена дважды, `denote` недостижим с леадера | `SPC d n` → `denote`, навигация по дням на `SPC d [` / `SPC d ]` |
| префикс `SPC d` | делили denote и docker | docker → `SPC o d` |
| `denote-journal` в повестке | `path-to-new-or-existing-entry` на загрузке конфига создавал запись журнала при каждом старте Emacs | advice на `org-agenda`; проверено: 3 старта, 2146 файлов без изменений |
| `hms-to-minutes "90"` | `(string-to-number nil)` → ошибка в формуле org-таблицы | 90 минут; мусор и пустая строка → 0 |
| `hms-to-pomodoros " *1:30* "` | жирное значение с пробелами молча давало 0 | 3 |
| `epa-file-enable` | предупреждение при каждом старте (`auto-encryption-mode` включён по умолчанию с Emacs 29) | вызов под guard'ом |
| `el` в правилах impl↔test | `SPC p t` на `lib/el-clock.el` открывал несуществующий `lib/el-clock-test.el` | перенос каталога `lib` ↔ `tests` |

## Время старта

Новый конфиг: 0.96 с (батч, три прогона: 0.97 / 0.95 / 0.97), 33 юнит-теста
за 0.004 с, `make smoke` и `make smoke-termux` зелёные с пустым
`el-failed-modules`.

Сравнить с Doom этим способом нельзя: его `init.el` в батче видит
`noninteractive` и пропускает загрузку модулей (0.08 с — это стоимость
загрузчика, а не конфигурации). Интерактивный замер через
`emacs-init-time` требует дисплея, недоступного из сессии, в которой
выполнялась миграция.

## Решения, принятые при исполнении

Записаны здесь, а не только в рабочем журнале, потому что журнал удаляется
вместе с workspace, а эти решения отклоняются от плана и должны быть
проверяемы потом.

| # | решение | почему | цена ошибки |
|---|---|---|---|
| 1 | Батч-проверки грузят `early-init.el` и `init.el` явно через `-l` | `--batch` выставляет `init-file-user` в `nil` и не грузит конфиг; все 22 проверки плана «проходили» бы, ничего не проверяя | проверки чуть менее точны, чем настоящий старт: `emacs-startup-hook` в батче не срабатывает |
| 2 | `epa-file-enable` под guard'ом | `auto-encryption-mode` включён по умолчанию с Emacs 29, повторный вызов печатал предупреждение при каждом старте | нет: на сборке без него guard всё равно включает режим |
| 3 | Высота шрифта выведена арифметикой, а не сверена глазами | в сессии миграции нет доступа к дисплею; X сообщает 96 dpi → `:height 375` = 37.5 pt = 50 px | единственная незакрытая проверка; сверяется глазами за секунду |
| 4 | `hms-to-*` обрезают пробелы | в `~/org/tasks` есть жирные длительности вида `\|  *0:00* \|`; с пробелами они молча давали 0 | нет: входы, которые считались верно, не затронуты |
| 5 | Ключ в `pass` проверен на существование, а не прочитан | печать ключа раскрыла бы секрет и разбудила GPG-агент | пустой или битый ключ выявится при первом запросе к модели |
| 6 | Правило impl↔test для `el` переносит `lib` ↔ `tests` | без этого `SPC p t` на `lib/el-clock.el` открывал несуществующий `lib/el-clock-test.el` при живом `tests/el-clock-test.el` | нет: вариант «в том же каталоге» остался в списке кандидатов |
| 7 | Проверки отложенных пакетов сначала грузят пакет | `elfeed-org` лишь ставит advice на команду `elfeed`, а `hledger-jfile` и прочее живут в отложенных `:config` — ранняя проверка проверяла пустоту | опечатка внутри `:config` telega или pdf-tools всплывёт при первом запуске |
| 8 | Отменена собственная находка про `package-refresh-contents` | проверка посылки: функция сама перехватывает сбой каждого архива и возвращается нормально (отказ соединения и несуществующий DNS) | если будущий Emacs заставит её сигналить, недоступный ELPA поднимет Emacs без модулей; guard — пять строк |
| 9 | Добавлен `eshell-alias-load-hook` | в `doom.d` `eshell-load-bash-aliases` была определена и никем не вызывалась; хук — её прямое назначение | +0.05 с на загрузку алиасов eshell и запуск интерактивного bashrc; снимается удалением строки |

## Что осталось человеку

1. **Cutover.** Не выполнен сознательно: на момент миграции работали
   `emacs -nw` и `emacs --fg-daemon` из `~/.config/emacs`, а переключение
   переименовывает этот каталог под ними. Команды — в разделе Emacs
   в `README.org`.
2. **Сверка шрифта глазами** (решение 3).
3. **Интерактивные проверки**, недоступные батчу: `SPC`-биндинги в живом
   фрейме, elfeed/magit/vterm/telega руками.
4. **Отложенные minor'ы**: `org-attach-directory` → `org-attach-id-dir`,
   `org-agenda-overriding-columns-format` → `org-overriding-columns-format`
   (оба — работающие алиасы, проверено), `mark-whole-buffer` в
   `el-ai-rewrite-buffer`, кавычки в docstring `el-keys.el:43`.
5. **mu4e** — вне объёма, нужен отдельный брейншторм.
