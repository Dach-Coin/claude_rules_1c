---
name: bsl-form-module-standards
description: Стандарты и паттерны модулей управляемых форм 1С - обязательная структура регионов, директивы компиляции (&НаКлиенте/&НаСервере/&НаСервереБезКонтекста), клиент-серверное взаимодействие, добавление обработчиков событий (с регистрацией в Form.xml), модификация типовых форм, условное оформление. Используй при написании, ревью или правке кода в модуле управляемой формы (Form.Module.bsl) и при добавлении обработчиков событий формы.
argument-hint: (no arguments)
allowed-tools: []
---

# /bsl-form-module-standards - стандарты модулей управляемых форм 1С

Объединенный справочник: структура модуля формы, правила модификации типовых форм, клиент-серверное взаимодействие, директивы компиляции, добавление обработчиков событий, условное оформление (Conditional Appearance).

Триггеры вызова:
- пишу или правлю код в `Form.Module.bsl`;
- добавляю обработчик события формы (надо не забыть прописать его в `Form.xml`);
- ревью/рефакторинг модуля формы;
- проектирование управляемой формы (стандарты компоновки - см. skill `form-patterns`, стандарты модуля - здесь).

## 1. Module Structure Templates

### Common Module

```bsl
#Region Public

#EndRegion

#Region Internal

#EndRegion

#Region Private

#EndRegion
```

### Object / Manager Module

```bsl
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#EndRegion

#Region EventHandlers

#EndRegion

#Region Private

#EndRegion

#EndIf
```

### Form Module

```bsl
#Region FormEventHandlers

#EndRegion

#Region FormHeaderItemsEventHandlers

#EndRegion

#Region FormTableItemsEventHandlers_TableName

#EndRegion

#Region FormCommandHandlers

#EndRegion

#Region Private

#EndRegion
```

> All 5 regions are **MANDATORY**, even if empty. If the form has multiple tables - create a separate region for each: `FormTableItemsEventHandlers_TableName`.
> Regions inside procedures/functions are **PROHIBITED**.

## 2. Form Modification Rules

### Programmatic Modification of Typical Forms
All typical form modifications are performed **programmatically**, not visually. Elements are created in `OnCreateAtServer` handler (or via subscription/extension).

### Placement of Added Elements
- If form has tabs - add elements to a separate tab (e.g., "Additional" or with `{PREFIX}`)
- If no tabs - create a group without title for added elements
- Typical form element names - with `{PREFIX}` prefix

### New Forms (Non-Typical Objects)
- Separate header attributes and tabular sections into distinct tabs: "Main" (header), then one tab per tabular section
- Fill "Header Data Path" property for pages with tabular sections
- Reference fields - maximum width 27 characters
- Multiline comment fields - width 79, height 3

### Fill Checking
- Use "Fill check" property on form attributes
- Before writing/posting, call `CheckFilling()`:

```bsl
If Not CheckFilling() Then
	Return;
EndIf;
```

### Form Commands
- When creating commands that modify data - enable "Modifies stored data" flag
- **Buttons are created without a picture by default.** Do not bind `<Picture><xr:Ref>StdPicture.*</xr:Ref></Picture>` from agent-generated XML. The developer attaches a suitable picture later when the form is reviewed; auto-picked pictures usually look out of place.

## 3. Conditional Appearance (Form.xml)

When writing fields into `<dcsset:field>` of a `ConditionalAppearance` rule, the path uses the **field identifier** of the form item, not the data path. The identifier is the table name and the column name **concatenated without a dot**:

```xml
<!-- Correct: form item identifier (no dot) -->
<dcsset:field>ТаблицаЗаказовКлиентаТекстОшибки</dcsset:field>
<dcsset:field>ТаблицаЗаказовКлиентаДокумент</dcsset:field>

<!-- Wrong: data path with a dot - DCS will not bind the appearance -->
<dcsset:field>ТаблицаЗаказовКлиента.ТекстОшибки</dcsset:field>
```

The dotted form (`ТаблицаЗаказовКлиента.ТекстОшибки`) is the correct shape **only** for `<DataPath>` of the form item itself and for `<dcsset:left>` / `<dcsset:right>` operands of the filter that drives the appearance condition (those are data-set paths, not item identifiers).

| Place | Format | Example |
|---|---|---|
| `<DataPath>` of a form item | dotted | `ТаблицаЗаказовКлиента.ТекстОшибки` |
| `<dcsset:left>` / `<dcsset:right>` of a `<Filter>` item | dotted | `ТаблицаЗаказовКлиента.ТекстОшибки` |
| `<dcsset:field>` (target of the appearance) | concatenated, no dot | `ТаблицаЗаказовКлиентаТекстОшибки` |

## 4. Client-Server Interaction

- Minimize client-server round trips in form modules.
- Group multiple server calls into a single call when possible.
- Avoid calling server methods in loops on the client side.

## 5. Compilation Directives

Available compilation directives for form module methods:

| Directive | Context | Use Case |
|-----------|---------|----------|
| `&НаКлиенте` | Client-side execution | UI interactions, user input handling |
| `&НаСервере` | Server-side with form context | When you need to modify form attributes/items |
| `&НаСервереБезКонтекста` | Server-side without form context | **Preferred** for data operations when form context is not needed (reduces data transfer) |
| `&НаКлиентеНаСервереБезКонтекста` | Both client and server without context | Shared utility functions |

- Prefer `&НаСервереБезКонтекста` over `&НаСервере` when form context is not required - it reduces network traffic.

## 6. Async Programming

- Prefer `Асинх` (async) methods over `ОписаниеОповещения` (notification description) when async analogues are available.
- Use `Ждать` (Await) for cleaner async code flow.
- Mixing `Асинх/Ждать` with non-async methods is prohibited - see `dev-standards-architecture.md` § «Async and Modality» for the platform-version gate (`{PLATFORM_VERSION}` in `.dev.env`).

## 7. Form Data

- Use `ДанныеФормыВЗначение()` / `ЗначениеВДанныеФормы()` to convert between form data and actual objects.
- Remember that form attributes are not the same as object attributes - they are form-specific representations.

## 8. Adding Event Handlers

**IMPORTANT:** adding a handler procedure to the form module is not enough - the event must also be registered in `Form.xml`, usually located in the parent directory of the module file.

Event hooks in XML:

```xml
<Events>
    <Event name="OnOpen">ПриОткрытии</Event>
    <Event name="BeforeWrite">ПередЗаписью</Event>
    <Event name="OnCreateAtServer">ПриСозданииНаСервере</Event>
</Events>
```

Common form events:

| XML Event Name | Russian Handler Name | Description |
|----------------|---------------------|-------------|
| `OnOpen` | ПриОткрытии | Client, when form opens |
| `OnClose` | ПриЗакрытии | Client, when form closes |
| `BeforeWrite` | ПередЗаписью | Client, before write |
| `AfterWrite` | ПослеЗаписи | Client, after write |
| `OnCreateAtServer` | ПриСозданииНаСервере | Server, form creation |
| `BeforeWriteAtServer` | ПередЗаписьюНаСервере | Server, before write |
| `AfterWriteAtServer` | ПослеЗаписиНаСервере | Server, after write |
| `OnReadAtServer` | ПриЧтенииНаСервере | Server, when reading object |

The value inside the `<Event>` tag is the name of the handler procedure in the form module.
