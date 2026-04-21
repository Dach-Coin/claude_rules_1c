# 1C Metadata Manage - карта знаний по домену метаданных

## Scope

Проектная карта для задач по структуре метаданных 1С на этом репо. Сюда попадают из `.claude/skills_instructions.md`, когда задача касается объектов, форм, СКД, макетов, ролей, расширений, подсистем, командного интерфейса, внешних обработок или ИБ. Файл отвечает на три вопроса:

- **Куда идти** - какие upstream-скиллы из `.claude/skills/<name>/` закрывают домен.
- **Что помнить** - проектные правила и грабли поверх upstream `SKILL.md`.
- **В каком порядке** - обязательный цикл мутации и чеклист «готово».

Здесь **нет**: параметров командной строки, DSL, примеров JSON/XML - это все в upstream `SKILL.md`. Стиля BSL, правил форм как модуля, критериев выбора MCP vs skill - это в `.claude/rules/*`. См. раздел «Что НЕ здесь» в конце.

## Домены и скиллы

Таблица - первое, что смотрит агент. Имена в бэктиках ровно совпадают с каталогами `.claude/skills/<name>/`.

| Домен | Skills | Когда |
|---|---|---|
| meta | `meta-compile`, `meta-info`, `meta-edit`, `meta-remove`, `meta-validate` | справочники, документы, регистры, перечисления, общие модули, константы |
| form | `form-compile`, `form-info`, `form-edit`, `form-validate`, `form-add`, `form-remove`, `form-patterns` | создание формы, правка элементов, обработчики, команды |
| skd | `skd-compile`, `skd-edit`, `skd-info`, `skd-validate` | отчеты на компоновке, правка запросов, настройки, варианты |
| mxl | `mxl-compile`, `mxl-decompile`, `mxl-info`, `mxl-validate`, `img-grid` | табличные документы, печатные формы, импортные шаблоны; `img-grid` - разметка пропорций колонок перед `mxl-compile` при восстановлении из скриншота |
| role | `role-compile`, `role-info`, `role-validate` | роли, права, RLS, шаблоны ограничений |
| epf | `epf-init`, `epf-add-form`, `epf-build`, `epf-dump`, `epf-validate`, `epf-bsp-init`, `epf-bsp-add-command` | внешние обработки, интеграция с БСП |
| erf | `erf-init`, `erf-build`, `erf-dump`, `erf-validate` | внешние отчеты |
| cfe | `cfe-init`, `cfe-borrow`, `cfe-patch-method`, `cfe-diff`, `cfe-validate` | расширения конфигурации, заимствование, перехватчики |
| cf | `cf-init`, `cf-info`, `cf-edit`, `cf-validate` | scaffold конфигурации, свойства, состав, роли по умолчанию |
| subsystem | `subsystem-compile`, `subsystem-info`, `subsystem-edit`, `subsystem-validate` | разделы, состав подсистем, иерархия |
| interface | `interface-edit`, `interface-validate` | командный интерфейс подсистемы, видимость и порядок команд |
| template | `template-add`, `template-remove` | макеты объектов (печатные, импортные, служебные) |
| help | `help-add` | встроенная справка объекта |
| db | `db-list`, `db-create`, `db-dump-cf`, `db-load-cf`, `db-dump-xml`, `db-load-xml`, `db-load-git`, `db-update`, `db-run` | реестр баз, создание и обновление ИБ, выгрузка-загрузка |
| web | `web-publish`, `web-info`, `web-stop`, `web-unpublish`, `web-test` | Apache, публикация ИБ, тестирование через веб-клиент |

## .dev.env: проектные параметры

Перед любой мутацией - прочитать `.dev.env`. Детали - в `.claude/rules/dev-standards-core.md`.

| Ключ | Что делает | Где всплывает |
|---|---|---|
| `PREFIX` | Префикс имен всех новых метаобъектов, реквизитов, элементов форм, ролей | `meta-compile`, `form-compile`, `role-compile`, `cfe-borrow` |
| `COMPANY`, `DEVELOPER` | Подставляются в модификационные комментарии | `cfe-patch-method`, ручная правка типовой |
| `NEW_OBJECTS_IN` | `main_configuration` (по умолчанию) или `extension`; определяет, куда идет новый объект | Все `meta-*`, `form-*`, `cfe-*` |
| `COMMENT_OPEN`, `COMMENT_CLOSE` | Открывающий и закрывающий маркеры модификаций в типовом коде | Ручные правки и `cfe-patch-method` |
| `PLATFORM_VERSION` | Гейт на допустимые фичи (Асинх/Ждать vs `ОписаниеОповещения`, новые функции платформы) | Весь BSL-код проекта |
| `PLATFORM_PATH` | Путь к `1cv8.exe`; все PS1-скрипты метадомена читают его из окружения | `db-*`, `epf-build`, `erf-build`, `web-publish` |

Если `.dev.env` отсутствует или непонятно, что выбрать - остановиться и спросить пользователя.

## CFE-first политика

Если `NEW_OBJECTS_IN=extension`:

- Никаких прямых правок XML/BSL типовой конфигурации.
- Любое изменение чужого объекта - через `cfe-borrow`, затем `cfe-patch-method` для модулей.
- Новые объекты создаются в скоупе CFE: `cfe-init` для scaffold, затем `meta-compile` с `-OutputDir` внутри расширения.
- Перед публикацией - `cfe-diff` до/после, чтобы убедиться, что заимствованы только нужные объекты и не протекли чужие.

Если `NEW_OBJECTS_IN=main_configuration` - работаем напрямую через соответствующие домены, CFE не используем.

## Цикл мутации метаданных

1. **Определить домен** по таблице выше. Для многодоменных задач - планировать по порядку (например, meta -> form -> role).
2. **Прочитать SKILL.md** выбранного скилла. DSL, аргументы, формат вывода - только там.
3. **Inspect перед edit** - для любой правки существующего объекта запускать соответствующий `*-info` (meta/form/skd/mxl/role/cfe-diff/subsystem/cf-info); это дешевле, чем читать XML целиком.
4. **Выполнить** - `*-compile` для создания с нуля из JSON или `*-edit` для точечной правки. Автоматический `*-validate` после каждого `*-edit`/`*-compile` отключать только в пакетных сценариях (`-NoValidate`).
5. **compile+validate** - если что-то осталось без автопроверки, прогнать `*-validate` явно. Для форм с контекстом `BaseForm` - `form-validate` автоматически проверяет `callType` и `ID` заимствований.
6. **BSL Language Server** - прогнать по тронутым `.bsl` модулям (см. `.claude/rules/mcp-tools.md`). Максимум три итерации по style warnings.
7. **Отчет** - список измененных файлов, использованные скиллы, нестандартные грабли (если всплыли), CFE vs main_configuration.

## Кириллица в аргументах дочерних `powershell.exe -File`

Запуск скилл-скриптов через `powershell.exe -NoProfile -File ...` проходит через Windows-аргумент-маршаллинг в cp866. В нескольких скиллах это ломает кириллические значения и JSON с кириллицей. Обход введен через base64-варианты параметров - во всех местах сохранено обратно-совместимое текстовое API, а `*B64` используется только когда нужно гарантировать UTF-8 payload в дочернем процессе.

| Скилл | Проблемные параметры | Base64-варианты |
|---|---|---|
| `subsystem-compile`  | `-Value` (инлайн JSON), `-DefinitionFile`, `-OutputDir`, `-Parent` | `-ValueB64`, `-DefinitionFileB64`, `-OutputDirB64`, `-ParentB64` |
| `subsystem-edit`     | `-SubsystemPath`, `-Value`, `-DefinitionFile` | `-SubsystemPathB64`, `-ValueB64`, `-DefinitionFileB64` |
| `subsystem-validate` | `-SubsystemPath` | `-SubsystemPathB64` |
| `epf-init`           | `-Name`, `-Synonym` | `-NameB64`, `-SynonymB64` |
| `epf-add-form`       | `-ProcessorName`, `-FormName`, `-Synonym` | `-ProcessorNameB64`, `-FormNameB64`, `-SynonymB64` |
| `erf-init`           | `-Name`, `-Synonym` | `-NameB64`, `-SynonymB64` |

Правило: если запускаешь скилл из другого PowerShell-процесса (runner, harness, внешний wrapper) и в значениях/путях есть кириллица - для `subsystem-compile`/`subsystem-edit` можно вынести JSON в `-DefinitionFile` с UTF-8 файлом, но кириллические пути (`-DefinitionFile`, `-OutputDir`, `-Parent`, `-SubsystemPath`) все равно передавай через соответствующий `*B64`-параметр. В inline-режиме из того же процесса, где задана строка, ограничений нет.

Внутренние spawn'ы авто-валидации в `subsystem-compile`/`subsystem-edit` уже автоматически передают путь в `subsystem-validate` через `-SubsystemPathB64` - кириллица в пути к подсистеме не ломает цепочку.

```powershell
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('МояПодсистема'))
powershell.exe -NoProfile -File .claude/skills/epf-init/scripts/init.ps1 -NameB64 $b64
```

## Per-домен грабли

Только то, чего нет в upstream `SKILL.md`.

### meta

- `PREFIX` скрипт сам не подставляет - добавлять в JSON вручную.
- Строгая валидация enum-значений: `SubordinationUse`, `EditType`, `Hierarchy*` и т. п. - любая опечатка в `meta-compile` заваливает `*-validate`.
- `multiLine=true` допустим только для `String` с большой длиной (типично `Description`, `Комментарий`). Для коротких строк платформа пишет предупреждение.
- Удаление объекта - только через `meta-remove` с `-FollowRefs`. Ручная правка `Configuration.xml` оставляет висящие ссылки в подсистемах, ролях и СКД.
- Порядок типов в `Configuration.xml/ChildObjects` фиксирован - `cf-validate` ругается на нарушение.

### form

- Сервер: предпочтительно `&НаСервереБезКонтекста`; `&НаСервере` - только когда нужен контекст формы целиком.
- `ValueStorage` в реквизитах формы не автовыносится - надо явно указать соответствие реквизиту объекта или хранение в реквизите формы.
- Порядок колонок таблиц: `Number`, `Date` идут первыми по конвенции типовых форм.
- Скрытие Ref-элемента от пользователя - `UserVisible=false`, не `Visible=false` (последний скрывает и от кода формы).
- Для EPF/ERF главный реквизит формы имеет тип `ExternalDataProcessorObject.<Имя>` или `ExternalReportObject.<Имя>`. DataPath - без префикса `Object.`.
- Архетипы композиции (Document, DataProcessor, List, CatalogItem, Wizard) - в `form-patterns`. Начинать выбор оттуда.
- Имена элементов формы префиксуются `PREFIX` так же, как имена реквизитов.
- Сопутствующие правила - `.claude/rules/form_module_rules.md` и `.claude/rules/dev-standards-forms.md`.

### skd

- Project-level пресеты в `presets/skills/skd/*.json`: скрипты выполняют scan-up от текущего каталога до ближайшего `.dev.env`, оттуда читают пресеты. Работает без явного пути.
- `skd-edit` идемпотентен - повторный запуск той же операции не портит схему.
- Shorthand полей в JSON: `[ПолеНабора]:Тип=Выражение#noField` - угловые скобки добавляются, тип и выражение подставляются; `#noField` скрывает поле из пользовательских настроек.
- `@autoDates` в параметрах разворачивается в пару `НачалоПериода`/`КонецПериода`.
- Ссылочные типы требуют, чтобы соответствующая конфигурация была доступна при сборке; иначе использовать `DataComposition.Field` или нейтральный тип.

### mxl

- Восстановление layout из скриншота - обязательный шаг `img-grid` для пропорций колонок; иначе `defaultWidth` и `columnWidths` уплывают.
- Имя макета печатной формы - префикс `PF_MXL_` (`PF_MXL_M11`). Это проектная конвенция для БСП-печатных форм, не путать с `PREFIX` из `.dev.env`.
- При декомпиляции (`mxl-decompile`) повторная компиляция дает тот же XML при неизменном DSL - расхождение означает, что ручная правка пропадет.
- По умолчанию `mxl-validate` режет после 20 ошибок; для массовой правки - `-MaxErrors`.

### role

- Namespace в `Rights.xml` - `http://v8.1c.ru/8.2/roles`, НЕ `8.3`.
- Гранулярные права (`View`, `Edit`) только для сегментов длиной 3 и больше: `Catalog.X.Attribute.Y`, `Document.Z.TabularSection.A.Attribute.B`.
- Родительские права обязательны: `View` на реквизит требует `View` на сам объект. `role-validate` это ловит.
- Для `Enum`, `FunctionalOption`, `DefinedType`, `CommonModule`, `CommonPicture`, `CommonTemplate` права в `Rights.xml` не пишутся - только регистрация в составе роли.
- RLS-шаблоны - по имени (в `Templates.xml`), их лучше переиспользовать из типовой, а не плодить свои.

### epf (+ bsp)

- Поток: `epf-init` -> `epf-add-form` (при необходимости) -> `epf-bsp-init` -> `epf-bsp-add-command` -> `epf-build`.
- Кириллица в `-Name`/`-Synonym`/`-ProcessorName`/`-FormName` при вызове через дочерний `powershell.exe -File` - через `-*B64` (см. «Кириллица в аргументах»).
- `epf-bsp-init` запускается ровно **один раз** на обработку - он подставляет шаблон `СведенияОВнешнейОбработке()`. Далее каждая новая команда - через `epf-bsp-add-command`.
- Плейсхолдер `{{TARGET_SECTION}}` остается только для назначаемых видов (`ObjectFilling`, `RelatedObjectCreation`, `PrintForm`, `Report`); для `AdditionalDataProcessor`/`AdditionalReport` - удалять.
- `PrintForm` требует модификатора `PrintMXL` и макет типа `SpreadsheetDocument` с именем `PF_MXL_*`.
- Обработчик команды: серверный (модуль объекта, функция `Выполнить`) - для `ObjectFilling`, `RelatedObjectCreation`, `PrintForm`; формовый - для `AdditionalDataProcessor` и `AdditionalReport`.
- `epf-build` подхватывает ссылочные типы только при наличии `-StubDb` или `PLATFORM_PATH`.

### erf

- Структурно аналогично EPF, но без БСП-интеграции как обязательной ветки.
- `erf-build` использует те же правила для ссылочных типов, что и `epf-build`.
- Кириллица в `-Name`/`-Synonym` у `erf-init` - через `-NameB64`/`-SynonymB64`.

### cfe

- Перед `cfe-patch-method` - ОБЯЗАТЕЛЬНО `cfe-borrow` для метода-донора. Перехват без заимствования платформа не принимает.
- Типы перехватчиков: `Before` (до), `After` (после), `ModificationAndControl` (полный контроль, `ПродолжитьВызов` обязателен). `Before`/`After` только для процедур, для функций - `ModificationAndControl`.
- `ModulePath` в `cfe-patch-method` - `ObjectType.ObjectName.ModuleType`, например `Document.РеализацияТоваровУслуг.ObjectModule`, `CommonModule.РаботаСФайлами.Module`.
- Тело перехвата оборачивается в маркеры `COMMENT_OPEN`/`COMMENT_CLOSE` из `.dev.env`.
- `CompatibilityMode` расширения должен совпадать с базовой конфигурацией; несовпадение ломает установку CFE.
- `cfe-diff` перед публикацией - показывает список заимствованных объектов и перехватчиков; использовать как финальный чек.

### cf

- `cf-validate` проверяет `DefaultLanguage` и наличие `Languages/<name>.xml` - при переносе объектов между конфигурациями не забывать языки.
- Порядок типов в `ChildObjects` задан платформой; `cf-edit -Operation add-childObject` ставит в корректное место, ручная правка - нет.

### subsystem

- `subsystem-edit` с `UseOneCommand=true` требует ровно одного элемента в Content; иначе команда неуникальна.
- Вложенные подсистемы - через `-Parent` в `subsystem-compile` или `add-child` в `subsystem-edit`.
- В пакетном режиме `subsystem-edit` операция `set-property` принимает `value` как JSON-строку (для `-Value`) или вложенный объект (для `-DefinitionFile`); скрипт понимает оба формата.
- Кириллица в значениях/путях при запуске через дочерний `powershell.exe -File` - через `-*B64`-варианты (включая `-SubsystemPathB64`, `-OutputDirB64`, `-ParentB64`); авто-валидация внутри compile/edit уже переведена на `-SubsystemPathB64`.

### interface

- `interface-edit` и `interface-validate` обычно идут парой; автовалидация включена, отключать `-NoValidate` только в пакетных сценариях.
- Для управления порядком команд и подсистем - операции `order`, `subsystem-order`, `group-order`, а не правка XML руками.

### template

- Для печатных форм - имя `PF_MXL_<ShortName>`. Если пользователь указал имя без префикса, но контекст БСП - префикс добавляется автоматически, об этом надо уведомить.
- `SpreadsheetDocument` тип макета -> далее `mxl-compile` для контента.
- `template-add` модифицирует корневой XML объекта (`ChildObjects`); `template-remove` удаляет и файлы, и запись.

### help

- `help-add` не регистрирует Help в `ChildObjects` - платформа находит файл по факту (`Ext/Help/<lang>.html`).
- Кнопка вызова справки - `Form.StandardCommand.Help` в `AutoCommandBar`; регистрировать команду и обработчик в модуле формы не нужно.

### db

- Канон новой ИБ: `db-create` -> `db-load-cf` или `db-load-xml` -> `db-update` (если XML правили после load) -> `db-run`.
- `db-dump-xml` режимы: `Full` (baseline), `Changes` (инкремент), `Partial` (ограниченный scope); в production-подобной ИБ использовать только в sandbox.
- `db-load-cf` ПОЛНОСТЬЮ заменяет конфигурацию - только для baseline; для инкрементов - `db-load-xml` или `db-load-git` с коммитом.
- `db-load-git` умеет partial load из коммита - единственный безопасный путь загрузить конкретный `src/Documents/...`, не трогая остальное.
- Реестр баз - `.v8-project.json`, управляется через `db-list`. Руками не править.
- Все `db-*`, `epf-build`, `erf-build`, `web-publish` уже берут `PLATFORM_PATH` из окружения; `-V8Path` нужен только для другой версии платформы.

### web

- `web-test` - Node.js 18+ и Playwright. Первичная инициализация: `cd .claude/skills/web-test/scripts && npm install` (тянет Playwright и Chromium). Запуск сценария: `node .claude/skills/web-test/scripts/run.mjs run <url> <scenario.js>`. Без установленных зависимостей скилл падает - help-флага sanity-mode у него нет.
- URL берется из `.v8-project.json` (`webUrl` или `http://localhost:8081/<id>`); база должна быть предварительно опубликована через `web-publish`.
- `web-publish` требует поднятый Apache; статус - `web-info`, остановка сервера - `web-stop`, снятие публикации - `web-unpublish` (сам Apache не трогает).

## SSL / БСП

Короткая шпаргалка поверх `.claude/rules/mcp-tools.md` и `.claude/rules/dev-standards-architecture.md`:

- Перед написанием своего кода - искать готовую подсистему БСП через `mcp__rlm-tools-bsl__rlm_execute` (`glob_files`, `parse_object_xml`, `find_callers`). Не угадывать.
- Типовые точки интеграции: `ПодключаемыеКоманды` (команды форм), `ДополнительныеОтчетыИОбработки` (EPF/ERF), `БезопасноеХранилищеСлужебныхДанных` (секреты), `РаботаСФайлами`/`ПрисоединенныеФайлы` (файлы), `УправлениеДоступом` (RLS и права), `ВерсионированиеОбъектов` (история), `ОбновлениеИнформационнойБазы` (миграции данных).
- `1c-syntax` MCP - только для platform builtins, НЕ для БСП-модулей. Для БСП - `rlm-tools-bsl` по коду типовой.

## Оптимизация запросов

Шпаргалка - подробные разборы в `.claude/rules/project_rules.md`.

- Виртуальные таблицы регистров - только с параметрами (период, измерения); отборы на уровне источника, не в `ГДЕ` над результатом.
- Составные поля разыменовываются через `ВЫРАЗИТЬ(Поле КАК Тип)`, иначе платформа строит LEFT JOIN ко всем таблицам типа.
- `ПРЕДСТАВЛЕНИЕ()` только для отображения; в условиях, группировках, сортировках - реальные поля.
- Вместо `ОБЪЕДИНИТЬ` использовать `ОБЪЕДИНИТЬ ВСЕ` везде, где не нужна явная дедупликация.
- `ИЛИ` по индексным полям - разворачивать в `ОБЪЕДИНИТЬ ВСЕ` для попадания в индекс.
- Большие подзапросы в `ВЫБРАТЬ`/`СОЕДИНЕНИЕ` выносить во временные таблицы (`ПОМЕСТИТЬ`).
- Вычисляемые поля в отборах динамических списков - запрещены (платформа падает на большом объеме); фильтр - на источнике.
- Промежуточные расчеты - во временных таблицах, а не в итоговом селекте.

## Чеклист «готово»

Перед отчетом убедиться:

- Все затронутые домены прошли `*-validate` без ошибок; warnings оценены осознанно.
- `form-validate` зеленый для форм с `BaseForm` (callType и ID заимствований).
- `cfe-diff` до/после показывает ожидаемые объекты и перехватчики (при правках CFE).
- `PREFIX` применен во всех новых именах (метаобъекты, реквизиты, элементы форм, роли).
- `COMMENT_OPEN`/`COMMENT_CLOSE` расставлены везде, где правилась типовая (вне CFE - в `cfe-patch-method`).
- Если `NEW_OBJECTS_IN=extension` - изменения типовой обернуты в CFE, прямых правок нет.
- BSL Language Server по тронутым `.bsl` - без новых критических диагностик.
- Ручная сверка по `bsl-anti-patterns` skill для затронутых модулей.
- В отчете перечислены измененные файлы, использованные скиллы и проектные грабли (если всплыли).

## Что НЕ здесь

- Аргументы, DSL, примеры JSON/XML, формат вывода конкретного скилла - в `.claude/skills/<name>/SKILL.md`.
- Полный реестр всех 67 скиллов и общая dispatch-таблица - в `.claude/skills_instructions.md`.
- Стиль BSL, комментарии модификаций, типографика, `.dev.env`-детали - в `.claude/rules/dev-standards-core.md`.
- Архитектурные паттерны, БСП-интеграция в глубину, code smells - в `.claude/rules/dev-standards-architecture.md`.
- Правила модулей форм (клиент/сервер, директивы компиляции, события) - в `.claude/rules/form_module_rules.md` и `.claude/rules/dev-standards-forms.md`.
- Выбор MCP vs skill vs bsl-language-server, capability boundaries - в `.claude/rules/mcp-tools.md`.
- Каталог анти-паттернов с уровнями severity - в `bsl-anti-patterns` skill.
- SDD-интеграции (Memory Bank, OpenSpec, Spec Kit, TaskMaster) - в `sdd-integrations` skill.
