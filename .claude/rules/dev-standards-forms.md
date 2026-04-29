---
paths: ["**/Form.Module.bsl", "**/Form.xml"]
---

# Development Standards -- Module Structure & Forms

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

> All 5 regions are **MANDATORY**, even if empty. If the form has multiple tables -- create a separate region for each: `FormTableItemsEventHandlers_TableName`.
> Regions inside procedures/functions are **PROHIBITED**.

## 2. Form Modification Rules

### Programmatic Modification of Typical Forms
All typical form modifications are performed **programmatically**, not visually. Elements are created in `OnCreateAtServer` handler (or via subscription/extension).

### Placement of Added Elements
- If form has tabs -- add elements to a separate tab (e.g., "Additional" or with `{PREFIX}`)
- If no tabs -- create a group without title for added elements
- Typical form element names -- with `{PREFIX}` prefix

### New Forms (Non-Typical Objects)
- Separate header attributes and tabular sections into distinct tabs: "Main" (header), then one tab per tabular section
- Fill "Header Data Path" property for pages with tabular sections
- Reference fields -- maximum width 27 characters
- Multiline comment fields -- width 79, height 3

### Fill Checking
- Use "Fill check" property on form attributes
- Before writing/posting, call `CheckFilling()`:

```bsl
If Not CheckFilling() Then
	Return;
EndIf;
```

### Form Commands
- When creating commands that modify data -- enable "Modifies stored data" flag
- **Buttons are created without a picture by default.** Do not bind `<Picture><xr:Ref>StdPicture.*</xr:Ref></Picture>` from agent-generated XML. The developer attaches a suitable picture later when the form is reviewed; auto-picked pictures usually look out of place.

## 3. Conditional Appearance (Form.xml)

When writing fields into `<dcsset:field>` of a `ConditionalAppearance` rule, the path uses the **field identifier** of the form item, not the data path. The identifier is the table name and the column name **concatenated without a dot**:

```xml
<!-- ✅ Correct: form item identifier (no dot) -->
<dcsset:field>ТаблицаЗаказовКлиентаТекстОшибки</dcsset:field>
<dcsset:field>ТаблицаЗаказовКлиентаДокумент</dcsset:field>

<!-- ❌ Wrong: data path with a dot -- DCS will not bind the appearance -->
<dcsset:field>ТаблицаЗаказовКлиента.ТекстОшибки</dcsset:field>
```

The dotted form (`ТаблицаЗаказовКлиента.ТекстОшибки`) is the correct shape **only** for `<DataPath>` of the form item itself and for `<dcsset:left>` / `<dcsset:right>` operands of the filter that drives the appearance condition (those are data-set paths, not item identifiers).

| Place | Format | Example |
|---|---|---|
| `<DataPath>` of a form item | dotted | `ТаблицаЗаказовКлиента.ТекстОшибки` |
| `<dcsset:left>` / `<dcsset:right>` of a `<Filter>` item | dotted | `ТаблицаЗаказовКлиента.ТекстОшибки` |
| `<dcsset:field>` (target of the appearance) | concatenated, no dot | `ТаблицаЗаказовКлиентаТекстОшибки` |

## 4. External processing forms: prefer `ТаблицаЗначений` over `ДинамическийСписок`

For tabular display of data inside an external processing (`.epf`), default to a `ТаблицаЗначений` form attribute, not a `ДинамическийСписок`. A dynamic list inside a non-bound external processing has registration quirks, harder testability and unstable activation behavior.

Configure the table for read-only display:

- `ReadOnly = true`, `AllowAddition = false`, `AllowDeletion = false` -- the user does not edit the table by hand.
- On every column: `FullTextSearchOnInput = false` -- otherwise row activation on click breaks.
- For every editable-looking column where editing must be blocked: `НачалоВыбора` and `Очистка` event handlers with `СтандартнаяОбработка = Ложь`.
- For a reference column: explicit `Открытие` handler -> `ПоказатьЗначение(, ТекущиеДанные.ИмяКолонкиСоСсылкой)`.
- Filters and grouping -- through DCS settings displayed in a collapsible group in the form header.

This is more predictable than a dynamic list, does not require the dynamic-list registration, and is easier to drive from automated tests.
