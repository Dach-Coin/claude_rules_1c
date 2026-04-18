# Skills Instructions

<!-- Scope: единая точка входа для всех 67 локальных скиллов из .claude/skills/.
     Это SSOT по реестру скиллов (полный список). Доменная карта по метаданным - в .claude/1c-metadata-manage.md.
     Выбор MCP vs skill vs bsl-language-server - в .claude/rules/mcp-tools.md.
     Стандарты кодирования - в .claude/rules/project_rules.md и .claude/rules/dev-standards-*.md. -->

## Scope

- Как выбрать и вызвать локальный скилл из `.claude/skills/<name>/`.
- Этот файл - **единый источник истины (SSOT)** по всему реестру скиллов. Любое добавление, удаление или переименование скилла начинается здесь.
- Файл не дублирует `SKILL.md` конкретного скилла - только dispatch-брифы.
- Покрыты только скиллы, физически лежащие в `.claude/skills/`. Глобальные плагины Claude Code (например `1c_syntax_skills` из плагина помощи по платформе) перечисляются самим Claude Code и здесь не описываются.

## MCP tools vs. skills vs. bsl-language-server

Перед обращением к любому из слоев - решить, какой из трех применим:

| Слой | Что делает | Примеры |
|---|---|---|
| **MCP-серверы** (`rlm-tools-bsl`, `1c-syntax`) | Read-only инспекция конфигурации и справочника платформы | Найти паттерн в коде, посмотреть встроенную функцию платформы |
| **BSL Language Server** (плагин `bsl-language-server`, НЕ MCP) | Диагностика `.bsl` / `.os` (ошибки, style warnings); плагин in-session или локальный CLI `bsl-language-server.exe --analyze`. Никогда не вызывается с префиксом `mcp__*`. | Проверить модуль после правки |
| **Skills** (этот файл) | Мутации проекта - создание метаданных, сборка, развертывание, выгрузка | Создать управляемую форму, собрать роль, развернуть конфигурацию в тестовой ИБ |

Полные правила выбора - `.claude/rules/mcp-tools.md`.

## Метаданные 1С - карта знаний

Для любых задач по структуре метаданных (объекты, формы, СКД, MXL, роли, расширения, БД, печатные формы) сначала читайте `.claude/1c-metadata-manage.md`. Там собраны проектные правила и таблица «домен -> скилл». Дальше - `SKILL.md` конкретного скилла.

## Available skills - dispatch table

Реестр всех 67 upstream-скиллов, сгруппированных по доменам. Имена в бэктиках соответствуют каталогам `.claude/skills/<name>/`. Детали аргументов и DSL - в `SKILL.md` скилла.

### Метаданные

`meta-compile`, `meta-edit`, `meta-info`, `meta-remove`, `meta-validate`

Создание, правка, анализ, удаление и валидация объектов конфигурации (справочники, документы, регистры, перечисления, константы, общие модули и т. п.).

### Формы

`form-compile`, `form-info`, `form-edit`, `form-validate`, `form-add`, `form-remove`, `form-patterns`

Сборка управляемой формы с нуля, точечная правка, анализ структуры, подключение формы к объекту, библиотека композиционных паттернов.

### СКД

`skd-compile`, `skd-edit`, `skd-info`, `skd-validate`

Сборка и правка схем компоновки данных, анализ структуры отчетов, валидация СКД.

### MXL

`mxl-compile`, `mxl-decompile`, `mxl-info`, `mxl-validate`

Работа с табличными документами: сборка из JSON, обратная декомпиляция, анализ областей и параметров, валидация.

### Роли

`role-compile`, `role-info`, `role-validate`

Создание ролей из описания прав, анализ состава прав и RLS, валидация целостности.

### Конфигурация (CF)

`cf-init`, `cf-info`, `cf-edit`, `cf-validate`

Scaffold новой конфигурации, правка свойств и состава, анализ, валидация.

### Расширения (CFE)

`cfe-init`, `cfe-borrow`, `cfe-patch-method`, `cfe-validate`, `cfe-diff`

Scaffold расширения, заимствование объектов, генерация перехватчиков методов, валидация, diff до/после.

### Подсистемы и командный интерфейс

`subsystem-compile`, `subsystem-edit`, `subsystem-info`, `subsystem-validate`, `interface-edit`, `interface-validate`

Создание и правка подсистем, настройка состава и иерархии, управление видимостью и порядком команд.

### EPF / ERF

`epf-init`, `epf-add-form`, `epf-build`, `epf-dump`, `epf-validate`, `epf-bsp-init`, `epf-bsp-add-command`, `erf-init`, `erf-build`, `erf-dump`, `erf-validate`

Внешние обработки и отчеты: scaffold, сборка `.epf`/`.erf`, обратная разборка, валидация, БСП-интеграция (регистрация и команды).

### Универсальные

`template-add`, `template-remove`, `help-add`

Добавление и удаление макетов, создание встроенной HTML-справки на объекте.

### Базы данных

`db-list`, `db-create`, `db-dump-cf`, `db-load-cf`, `db-dump-xml`, `db-load-xml`, `db-update`, `db-run`, `db-load-git`

Реестр баз в `.v8-project.json`, создание ИБ, выгрузка и загрузка (`.cf`, XML, partial load из git-коммита), обновление конфигурации БД, запуск 1С:Предприятия.

### Веб-публикация и тестирование

`web-publish`, `web-info`, `web-stop`, `web-unpublish`, `web-test`

Публикация ИБ через Apache, статус и остановка веб-сервера, снятие публикации, e2e-тестирование через веб-клиент (Playwright). Каноничная связка для полного цикла: `db-update` (конфигурация БД) -> `web-publish` -> `web-test`.

### Утилиты

`img-grid`

Наложение пронумерованной сетки на изображение для разметки пропорций колонок перед `mxl-compile` (когда макет восстанавливается из скриншота или сканированной печатной формы).

## Dispatch rules

1. Любая мутация метаданных, форм, СКД, ролей, расширений - через соответствующий `*-compile` / `*-edit` / `*-validate` скилл, не через прямые правки XML.
2. Выгрузка конфигурации из ИБ в файлы - `db-dump-xml` (`Full` для baseline, `Changes` для инкремента, `Partial` для узкого scope).
3. End-to-end UI-тестирование - `web-test` поверх предварительного `web-publish` и `db-update`.
4. Создание новой ИБ - `db-create` -> `db-load-cf` или `db-load-xml` -> `db-update` -> `db-run`.
5. Изменение типового кода при `NEW_OBJECTS_IN=extension` из `.dev.env` - только через `cfe-borrow` + `cfe-patch-method`, прямые правки запрещены.
6. Восстановление MXL из скриншота - обязательно предварять `img-grid` для пропорций колонок.
7. Не переизобретать то, что уже закрыто скиллом - расширять скилл (или добавлять rule в `.claude/rules/`), если функциональности не хватает.

## bsl-language-server (not a skill, but mandatory)

LSP-интеграция над `BSL Language Server`. Не входит в список выше, потому что это platform-level плагин, а не запись в `.claude/skills/`. Использование обязательно для любой правки BSL:

- Диагностика после написания или модификации BSL - ошибки должны быть исправлены.
- `go-to-definition`, `find-references` - при ревью.
- `rename` - для рефакторинга, вместо search-and-replace.

Полное описание - в `.claude/rules/mcp-tools.md` (раздел "bsl-language-server").

## Runtime notes

- **Runtime**: PowerShell 5.1+ на Windows для большинства скиллов. Точный entrypoint - в `SKILL.md` конкретного скилла; одноимённого `scripts/<skill>.ps1` у части скиллов нет (делят общий скрипт внутри `scripts/` или вообще без PS1).
- **Исключения из PowerShell**:
  - `web-test` - Node.js 18+ и Playwright. Запуск: `node .claude/skills/web-test/scripts/run.mjs run <url> <scenario>` после первичного `npm install` в `.claude/skills/web-test/scripts/`. Флага help-sanity нет.
  - `img-grid` - Python (`.claude/skills/img-grid/scripts/overlay-grid.py`).
  - `db-list`, `form-patterns`, `erf-build`, `erf-dump`, `erf-validate` - без собственного исполняемого скрипта: это dispatcher/справка, работа по `SKILL.md`.
- **Python-порты**: у ряда скиллов рядом с `.ps1` лежит `.py`; в проекте используется PowerShell-ветка, Python-порты не активируются.
- **Путь к платформе**: `$env:PLATFORM_PATH` из `.dev.env` имеет приоритет над upstream-автодетектом. Список скриптов, где эта логика наложена (11 шт.): `db-create`, `db-dump-cf`, `db-dump-xml`, `db-load-cf`, `db-load-git`, `db-load-xml`, `db-run`, `db-update`, `epf-build`, `epf-dump`, `web-publish`. Fallback на автодетект `C:\Program Files\1cv8\*\bin\1cv8.exe` сохраняется.
