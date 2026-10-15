EMACS ?= emacs
TESTS := $(wildcard tests/*-test.el)

LOAD := -l $(CURDIR)/early-init.el -l $(CURDIR)/init.el

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
	$(EMACS) -batch --init-directory $(CURDIR) $(LOAD) --eval '$(CHECK)'

## То же, но с видом на Termux: проверяет платформенную развилку.
smoke-termux:
	TERMUX_VERSION=1 $(EMACS) -batch --init-directory $(CURDIR) $(LOAD) --eval '$(CHECK)'
