---
---

# Development Standards -- Core

## 1. Project Parameters (.dev.env)

**Before starting any code task**, read the `.dev.env` file from the project root. If it does not exist -- **stop and request parameters from the user**. Guessing values is PROHIBITED.

Parameters and their effect on code generation:

| Parameter | Effect |
|---|---|
| `{PREFIX}` | Prefix for ALL new metadata objects, attributes, form elements, roles |
| `{COMPANY}` | Used in modification comment templates |
| `{DEVELOPER}` | Used in modification comment templates |
| `{PLATFORM_VERSION}` | Determines available platform features (async/await vs NotifyDescription, etc.) |
| `{COMMENT_OPEN}` | Opening modification comment template with placeholders `{COMPANY}`, `{DEVELOPER}`, `{DATE}`, `{TASK}` |
| `{COMMENT_CLOSE}` | Closing modification comment template |
| `{NEW_OBJECTS_IN}` | Where to place new objects: `main_configuration` (default) or `extension` |

Task number `{TASK}` is specified with each change -- ask user if not provided.

> For tasks without code generation (review, analysis, documentation) -- parameters are not blocking.

See `.dev.env.example` for template.

## 2. Code Style (extends project_rules.md)

### Formatting
- **Indentation:** TAB only (not spaces)
- **One statement per line.** Single-line constructs with complex logic are prohibited

### Alignment
- For groups of similar assignments **into local variables** -- align `=` with spaces
- **DO NOT** align when setting object properties via dot notation -- use single space around `=`

### Quality Metrics

| Metric | Limit | Strictness |
|---|---|---|
| Method length | <= 200 lines (exception: query texts) | hard limit |
| Method length | > 100 lines -- candidate for decomposition | review trigger |
| Control structure nesting | < 5 levels | hard limit |
| Cognitive complexity | < 15 | review trigger |
| Method parameters | <= 5 (additional via Structure as 6th) | hard limit |

### String Building
Use `СтрШаблон(...)` for composing strings, **NOT** concatenation via `+`. Single project-wide templating helper -- do not mix in alternative SSL helper-wrappers (see `dev-standards-architecture.md` § Error Handling).
Exception: simple `Префикс + Суффикс` is acceptable when it reads better.

### Naming (extends project_rules.md)
- **Variable names MUST be self-explanatory and use 1C-native Russian terms** (e.g., `Счета`, `ПараметрыПодключения`). Do NOT add type-suffixes that duplicate what the value already implies -- that is Hungarian notation, forbidden by `project_rules.md`.
- **Boolean variables -- positive names only** (`ПроверкаПройдена`, not `ПроверкаНеПройдена`)
- **"Magic numbers" are PROHIBITED** -- extract into named variables
- **String value enumerations** -- in alphabetical order
- **Yoda syntax is PROHIBITED** (`Если Сумма = 0`, not `Если 0 = Сумма`)
- **One- and two-letter names are PROHIBITED** outside of `Для Сч = ...` loop counters. No `Q`, `U`, `N`, `i`, `j` as standalone identifiers.
- **Mixed-alphabet identifiers are PROHIBITED** (`SumQ`, `tmpСумма`). Stay in one alphabet -- Russian for business identifiers.
- **No programmer-jargon calques** -- replace with business terms in 1C terminology:
   - `split` / `сплит` -> `Разделение`
   - `lookup` / `лукап` -> `Поиск` / `ПроверкаПринадлежности`
   - `план обработки` / `элемент плана` -> `Кандидат` / `СтрокаКРаспределению` (the word "план" is programmer mindset, not business domain)

### No anglicisms in BSL identifiers, comments, user-facing strings

Live 1C developers do not write in mixed Russian-English jargon. Identifiers, comments and `НСтр("ru = '...'")` strings use native 1C/Russian terms. Replace the loanword with its 1C equivalent before committing the module.

| Anglicism | 1C equivalent |
|---|---|
| дебаунс | отложенное обновление / задержка обновления |
| UI | форма / интерфейс / состояние формы |
| батч-запрос | пакетный запрос |
| триггерить | запускать / вызывать |
| коммит | фиксация транзакции |
| воркфлоу | процесс / сценарий |
| фолбэк | запасной вариант / ветка отката |
| тоггл | переключатель / переключение |
| мердж | объединение / слияние |
| деплой | развертывание / публикация |

**Industry abbreviations actually used in standard 1C configurations** (`FIFO`, `FEFO`, `RLS`, `БСП`, etc.) are allowed -- do not rewrite them. The rule targets imported jargon from other stacks (web, mobile, devops), not domain abbreviations established in 1C practice.

### Conditions
- Simple conditions -- ternary operator `?()` is allowed
- Nested ternary operators -- **PROHIBITED**
- Complex conditions (3+ constructs) -- extract into a separate method

### Function Parameters
- Function parameter MUST NOT be used as additional output -- all output via return value
- For additional parameters -- use constructor function pattern:

```bsl
Функция ПараметрыЗаполнения() Экспорт
	Параметры = Новый Структура;
	Параметры.Вставить("Дата");
	Параметры.Вставить("Валюта");
	Параметры.Вставить("ПересчитатьСумму", Истина);
	Возврат Параметры;
КонецФункции
```

## 3. Modification Comments

Modification markers are used **only when modifying typical (standard) code** in typical configuration modules.

### Format
- Opening comment: value of `{COMMENT_OPEN}` from `.dev.env`
- Closing comment: value of `{COMMENT_CLOSE}` from `.dev.env`
- A space is mandatory after `//`

### Typical Code Modification
Removed typical code -- **comment out, DO NOT delete**:

```bsl
// {COMMENT_OPEN}
НоваяПеременная = {PREFIX}ПреобразоватьЗначение(Значение1);
//ТиповаяПроцедура(Значение1, Значение2);
ТиповаяПроцедура(НоваяПеременная, Значение2);
// {COMMENT_CLOSE}
```

### New Procedures in Typical Modules
Comment is placed **inside** the procedure, after the header:

```bsl
Функция НоваяФункция(Параметр) Экспорт
	// {COMMENT_OPEN}
	// ... код ...
	Возврат Результат;
	// {COMMENT_CLOSE}
КонецФункции
```

### Entirely New (Non-Typical) Objects
In modules of new objects (with `{PREFIX}`) -- markers per method are **NOT NEEDED**. Instead -- **a single block at the module header** describing the object.

### General Rules
- `TODO` / `FIXME` must contain a task reference: `// TODO No.14752: description`
- **Pseudo-regions via comments are PROHIBITED** -- use only `#Region` / `#EndRegion`

### References to other code in comments
When pointing to a sample/source procedure, use **1C metadata notation**, not filesystem paths or line numbers. Configurator users navigate by metadata names; paths and line numbers rot on every refactor.

| OK / NOT OK | Form |
|---|---|
| ✅ OK | `// Взято по образцу Обработка.ФормированиеПеремещенийПоЗаказамНаПроизводство.ЗаполнитьИПровестиДокумент()` |
| ✅ OK | `// См. ОбщийМодуль.ОбеспечениеВДокументахСервер.ЗаполнитьВариантОбеспечения...` |
| ✅ OK | `// См. Документ.ЗаказКлиента.МодульОбъекта.ПередЗаписью` |
| ❌ NOT OK | `// DataProcessors/ФормированиеПеремещенийПоЗаказамНаПроизводство/Ext/ManagerModule.bsl:399` |
| ❌ NOT OK | `// см. CommonModules/ОбеспечениеВДокументахСервер/Ext/Module.bsl` |
| ❌ NOT OK | `// строка 4030 в модуле ОбеспечениеВДокументахСервер` |

The same applies to git/PR descriptions inside the codebase, agent reports written to BSL comments, and `// TODO` references - always 1C-metadata notation, no `*.bsl:NNN`.

## 4. Metadata Naming

| Element | Rule |
|---|---|
| New metadata objects | Prefix `{PREFIX}` in name (e.g., `{PREFIX}СуммаДоговора`) |
| Object synonyms | No prefix. If conflicts -- add `({COMPANY})` |
| New roles | Prefix `{PREFIX}` |
| Subsystems | `{PREFIX}ДобавленныеОбъекты` and `{PREFIX}ИзмененныеОбъекты` |
| Attributes of typical objects | Prefix `{PREFIX}` |
| Form elements on typical forms | Prefix `{PREFIX}` |

**Inside non-typical (new) objects** (name already has `{PREFIX}`):
- Attributes, tabular sections, form elements, commands, procedures -- **WITHOUT prefix**

- Place all new objects into subsystems
- Composite types used repeatedly -- via `DefinedType`

### Object Type Selection

| Task | Object Type |
|---|---|
| Reference data | `Catalog` |
| Business transactions | `Document` |
| Quantity/amount accumulation | `AccumulationRegister` |
| Arbitrary data with dimensions | `InformationRegister` |
| User reports | `Report` (with DCS) |
| Data processing | `DataProcessor` |
| Fixed set of values | `Enum` |

## 5. Procedure/Function Documentation

Mandatory for all `Экспорт` procedures/functions (except predefined handlers):

```bsl
// Возвращает спецодежду для должности, действующую на указанную дату.
//
// Параметры:
//  ДатаДействия - Дата
//  Должность - СправочникСсылка.Должности
//
// Возвращаемое значение:
//  СправочникСсылка.{PREFIX}СпецодеждаДляДолжностей
//
Функция АктуальнаяСпецодеждаДляДолжности(ДатаДействия, Должность) Экспорт
```

- Description starts with a Russian verb: "Возвращает...", "Проверяет...", "Рассчитывает..."
- DO NOT start with "Процедура...", "Функция..." or the function name
- For `Структура` parameters -- describe keys via `*`
- For `Массив` -- specify element type

## 6. Repository Typography

See `.claude/rules/typography.md` (auto-loaded).
