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
Use `StrTemplate()` / `StrShablon()` for composing strings, **NOT** concatenation via `+`.
Exception: simple `Prefix + Suffix` is acceptable when it reads better.

### Naming (extends project_rules.md)
- **Variable names MUST semantically reflect data type** (e.g., `InvoicesArray`, `ConnectionParametersStructure`)
- **Boolean variables -- positive names only** (`CheckPassed`, not `CheckNotPassed`)
- **"Magic numbers" are PROHIBITED** -- extract into named variables
- **String value enumerations** -- in alphabetical order
- **Yoda syntax is PROHIBITED** (`If Amount = 0`, not `If 0 = Amount`)

### Conditions
- Simple conditions -- ternary operator `?()` is allowed
- Nested ternary operators -- **PROHIBITED**
- Complex conditions (3+ constructs) -- extract into a separate method

### Function Parameters
- Function parameter MUST NOT be used as additional output -- all output via return value
- For additional parameters -- use constructor function pattern:

```bsl
Function FillingParameters() Export
	Parameters = New Structure;
	Parameters.Insert("Date");
	Parameters.Insert("Currency");
	Parameters.Insert("RecalculateAmount", True);
	Return Parameters;
EndFunction
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
NewVariable = {PREFIX}ConvertValue(Value1);
//TypicalCodeProcedure(Value1, Value2);
TypicalCodeProcedure(NewVariable, Value2);
// {COMMENT_CLOSE}
```

### New Procedures in Typical Modules
Comment is placed **inside** the procedure, after the header:

```bsl
Function NewFunction(Parameter) Export
	// {COMMENT_OPEN}
	// ... code ...
	Return Result;
	// {COMMENT_CLOSE}
EndFunction
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
| New metadata objects | Prefix `{PREFIX}` in name (e.g., `{PREFIX}ContractAmount`) |
| Object synonyms | No prefix. If conflicts -- add `({COMPANY})` |
| New roles | Prefix `{PREFIX}` |
| Subsystems | `{PREFIX}AddedObjects` and `{PREFIX}ModifiedObjects` |
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

Mandatory for all `Export` procedures/functions (except predefined handlers):

```bsl
// Returns workwear for position effective on the specified date
//
// Parameters:
//  ActionDate - Date
//  Position - CatalogRef.Positions
//
// Returns:
//  CatalogRef.{PREFIX}WorkwearForPositions
//
Function ActualWorkwearForPosition(ActionDate, Position) Export
```

- Description starts with a verb: "Returns...", "Checks...", "Calculates..."
- DO NOT start with "Procedure...", "Function..." or the function name
- For structure parameters -- describe keys via `*`
- For arrays -- specify element type

## 6. Repository Typography

Two characters are banned across the whole repository - in `.bsl`, `.md`, `.ps1`, `.json`, anywhere.

### Typographic dashes (em-dash U+2014 and en-dash U+2013)

Use the plain ASCII hyphen-minus (`-`) only.

| Where | Why it matters |
|---|---|
| `.bsl` | BSL Language Server reports `—` and `–` as `InvalidCharacterInFile` (error). |
| `.ps1` | Encoding drift under Windows PowerShell - the same file rendered through cp1251 and utf-8 produces different bytes for `—`, breaks diffs and signatures. |
| `.md` | Consistency. Markdown renderers handle `-` identically; em-dashes only add visual noise and a class of git-diff false positives. |

### Yo (U+0451 / U+0401)

The Cyrillic letters at code points `U+0451` (lowercase, HTML entity `&#1105;`) and `U+0401` (uppercase, HTML entity `&#1025;`) must not appear in any repository file. Use the regular `е` / `Е` (`U+0435` / `U+0415`) instead.

Why this matters in 1C specifically:

- The platform itself does not use these two code points in metadata - identifiers, synonyms and reserved keywords are stored with `U+0435` / `U+0415`. Writing `Отчет` and `Отчет` as if they were equivalent is a copy-paste trap; to the XDTO schema they are two different strings.
- The characters have a long history of encoding drift - some sources store them as a separate code point, some normalise, some strip them on conversion. Keeping them out of the repo removes the ambiguity entirely.
- This is a repo-hygiene rule, not a linguistic claim about the Russian language.

Runtime compatibility: skills that look up Russian type names in internal synonym dictionaries (`meta-compile`, `meta-edit`, `subsystem-compile`, `subsystem-edit`, `interface-edit`, `cfe-borrow`, `role-compile`, `web-test`) normalize `U+0451` / `U+0401` to `U+0435` / `U+0415` on the input side via a `Normalize-Yo` helper (PowerShell) or a `_YoNormDict` wrapper (Python). Legacy JSON or CLI input that still spells the key with `U+0451` keeps working; the dictionaries themselves are stored only in the sanitised form.

### Enforcement

Mechanical scan before commit (note: patterns below are Unicode-escaped to avoid embedding the forbidden characters in this document):

```powershell
# em-dash / en-dash
Select-String -Pattern "[\u2014\u2013]" -Path .\**\* -Recurse

# U+0451 / U+0401
Select-String -Pattern "[\u0451\u0401]" -Path .\**\* -Recurse
```

The only legitimate occurrence of these characters in the repo is inside this very section, where they *cannot* be cited. We cite them by code point (`U+0451`, `U+0401`) or HTML entity (`&#1105;`, `&#1025;`), never by writing the glyph itself.
