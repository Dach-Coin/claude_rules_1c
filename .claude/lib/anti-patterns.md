---
---
# 1C Anti-Patterns and Performance Guidelines

This file consolidates all anti-patterns, performance issues, and best practice violations for 1C development. Reference this file instead of duplicating examples.

## Critical Anti-Patterns (Must Fix)

### 1. Query in Loop

**Impact:** O(n) database calls → O(1)
**Severity:** CRITICAL

```bsl
// ❌ CRITICAL: N database calls
Для Каждого Строка Из Данные Цикл
    Запрос = Новый Запрос("ВЫБРАТЬ ... ГДЕ Ссылка = &Ссылка");
    Запрос.УстановитьПараметр("Ссылка", Строка.Ссылка);
    РезультатЗапроса = Запрос.Выполнить();
КонецЦикла;

// ✅ OPTIMIZED: 1 database call
Запрос = Новый Запрос;
Запрос.Текст =
"ВЫБРАТЬ ...
|ГДЕ
|   Ссылка В (&СписокСсылок)";
Запрос.УстановитьПараметр("СписокСсылок",
    Данные.ВыгрузитьКолонку("Ссылка"));
РезультатЗапроса = Запрос.Выполнить();
```

### 2. Direct Attribute Access (Dot Notation) - in BSL code only

**Scope:** This anti-pattern applies to **BSL code** (loading attributes from a reference variable). It does **NOT** apply to query text - see "Dot notation in query text" below.

**Impact:** Loads entire object from database
**Severity:** CRITICAL

```bsl
// ❌ CRITICAL: Full object load for each attribute
ИНН = Контрагент.ИНН;
КПП = Контрагент.КПП;
Наименование = Контрагент.Наименование;

// ✅ OPTIMIZED: Single targeted query via SSL
Реквизиты = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(
    Контрагент, "ИНН, КПП, Наименование");
ИНН = Реквизиты.ИНН;
КПП = Реквизиты.КПП;
Наименование = Реквизиты.Наименование;
```

**SSL Methods Reference:** See `.claude/lib/project_rules.md` → "Reference Attribute Access" section.

#### Dot notation in query text - ALLOWED for ordinary references

In query text, dot dereference of a reference field (`Документ.Контрагент.ИНН`, `Заказ.Договор.Валюта`) is the **standard 1C way** to express an automatic LEFT JOIN; the platform optimizes it correctly. Do not flag this as the same anti-pattern.

**Restriction - composite-type fields:**
- In **JOIN conditions** (`ПО ... = ...`) and `ГДЕ` predicates - dereferencing a composite-type field through a dot is **PROHIBITED** (each branch generates a separate JOIN, plan blows up).
- In the **SELECT list** - allowed only when the field is wrapped in `ВЫРАЗИТЬ(... КАК Документ.ИмяТипа)` to fix the type.

```sql
// ✅ OK: ordinary reference, automatic JOIN
ВЫБРАТЬ Заказ.Контрагент.Наименование КАК Контрагент

// ❌ NOT OK: composite type in WHERE / JOIN ON
ГДЕ ЗП.ДокументОснование.Дата > &Дата

// ✅ OK: composite type in SELECT, wrapped in ВЫРАЗИТЬ
ВЫБРАТЬ ВЫРАЗИТЬ(ЗП.ДокументОснование КАК Документ.ЗаказКлиента).Номер КАК Номер
```

### 3. Subquery in SELECT

**Impact:** N+1 query execution
**Severity:** CRITICAL

```bsl
// ❌ CRITICAL: Subquery executed per row
"ВЫБРАТЬ
|   Заказы.Ссылка,
|   (ВЫБРАТЬ СУММА(Оплаты.Сумма)
|    ИЗ Документ.Оплата КАК Оплаты
|    ГДЕ Оплаты.Заказ = Заказы.Ссылка) КАК СуммаОплат
|ИЗ
|   Документ.Заказ КАК Заказы"

// ✅ OPTIMIZED: Single join with aggregation
"ВЫБРАТЬ
|   Заказы.Ссылка КАК Ссылка,
|   ЕСТЬNULL(Оплаты.СуммаОплат, 0) КАК СуммаОплат
|ИЗ
|   Документ.Заказ КАК Заказы
|       ЛЕВОЕ СОЕДИНЕНИЕ (
|           ВЫБРАТЬ
|               Оплаты.Заказ КАК Заказ,
|               СУММА(Оплаты.Сумма) КАК СуммаОплат
|           ИЗ
|               Документ.Оплата КАК Оплаты
|           СГРУППИРОВАТЬ ПО
|               Оплаты.Заказ) КАК Оплаты
|       ПО Заказы.Ссылка = Оплаты.Заказ"
```

## High Priority Anti-Patterns

### 4. Virtual Table Filter in WHERE

**Impact:** Full table scan instead of index usage
**Severity:** HIGH

```bsl
// ❌ HIGH: Filter after virtual table calculation
"ВЫБРАТЬ
|   Остатки.Номенклатура КАК Номенклатура,
|   Остатки.КоличествоОстаток КАК Остаток
|ИЗ
|   РегистрНакопления.ТоварыНаСкладах.Остатки() КАК Остатки
|ГДЕ
|   Остатки.Склад = &Склад"

// ✅ OPTIMIZED: Filter in virtual table parameters
"ВЫБРАТЬ
|   Остатки.Номенклатура КАК Номенклатура,
|   Остатки.КоличествоОстаток КАК Остаток
|ИЗ
|   РегистрНакопления.ТоварыНаСкладах.Остатки(, Склад = &Склад) КАК Остатки"
```

#### Virtual tables are already aggregated -- do not re-group

`.Остатки()`, `.Обороты()`, `.ОстаткиИОбороты()` already return values aggregated over the dimensions you selected. Wrapping them in `СГРУППИРОВАТЬ ПО` / `СУММА(...)` again is redundant and signals a misunderstanding of the virtual table.

#### `ГДЕ` on a virtual table is allowed only for post-aggregation predicates on resources

The narrow exception to the rule above: `ГДЕ` over a virtual-table result is fine when the predicate is on a **resource** evaluated after aggregation, e.g., `Остатки.КоличествоОстаток > 0`. Resources are computed after the VT parameters are applied, so an index-vs-scan trade-off does not arise.

| Predicate target | Where it goes |
|---|---|
| Dimension (склад, организация, номенклатура), period, regular ref filter | Virtual-table parameters (anti-pattern #4 above is in force) |
| Resource computed by the virtual table (`КоличествоОстаток > 0`, `Сумма <> 0`) | `ГДЕ` is acceptable |

### 5. Missing ПЕРВЫЕ N

**Impact:** Loads all records when only subset needed
**Severity:** HIGH

```bsl
// ❌ HIGH: Loads all records
"ВЫБРАТЬ
|   Контрагенты.Ссылка КАК Ссылка
|ИЗ
|   Справочник.Контрагенты КАК Контрагенты"

// ✅ OPTIMIZED: Limit at query level
"ВЫБРАТЬ ПЕРВЫЕ 10
|   Контрагенты.Ссылка КАК Ссылка
|ИЗ
|   Справочник.Контрагенты КАК Контрагенты"
```

### 6. Excessive Client-Server Calls

**Impact:** Network overhead, context serialization
**Severity:** HIGH

```bsl
// ❌ HIGH: Multiple server calls
&НаКлиенте
Процедура Обработать(Команда)
    Данные1 = ПолучитьДанные1НаСервере();
    Данные2 = ПолучитьДанные2НаСервере();
    Данные3 = ПолучитьДанные3НаСервере();
КонецПроцедуры

// ✅ OPTIMIZED: Single server call
&НаКлиенте
Процедура Обработать(Команда)
    ВсеДанные = ПолучитьВсеДанныеНаСервере();
КонецПроцедуры

&НаСервереБезКонтекста
Функция ПолучитьВсеДанныеНаСервере()
    Результат = Новый Структура;
    Результат.Вставить("Данные1", ПолучитьДанные1());
    Результат.Вставить("Данные2", ПолучитьДанные2());
    Результат.Вставить("Данные3", ПолучитьДанные3());
    Возврат Результат;
КонецФункции
```

### 7. Using &НаСервере Instead of &НаСервереБезКонтекста

**Impact:** Unnecessary form context transfer
**Severity:** HIGH

```bsl
// ❌ HIGH: Transfers full form context
&НаСервере
Функция ПолучитьДанныеНаСервере()
    Возврат ВыполнитьЗапрос();
КонецФункции

// ✅ OPTIMIZED: No context transfer
&НаСервереБезКонтекста
Функция ПолучитьДанныеНаСервере(Параметры)
    Возврат ВыполнитьЗапрос(Параметры);
КонецФункции
```

## Medium Priority Anti-Patterns

### 8. Missing Caching

**Impact:** Repeated expensive operations
**Severity:** MEDIUM

```bsl
// ❌ MEDIUM: Same calculation repeated
Для Каждого Строка Из ТаблицаДанных Цикл
    Курс = ПолучитьКурсВалюты(Строка.Валюта, Строка.Дата);
КонецЦикла;

// ✅ OPTIMIZED: Cache results
КэшКурсов = Новый Соответствие;

Для Каждого Строка Из ТаблицаДанных Цикл

    Ключ = Строка.Валюта + "|" + Формат(Строка.Дата, "ДФ=yyyyMMdd");
    Курс = КэшКурсов.Получить(Ключ);

    Если Курс = Неопределено Тогда
        Курс = ПолучитьКурсВалюты(Строка.Валюта, Строка.Дата);
        КэшКурсов.Вставить(Ключ, Курс);
    КонецЕсли;

КонецЦикла;
```

### 9. O(n²) Algorithm

**Impact:** Exponential performance degradation
**Severity:** MEDIUM

```bsl
// ❌ MEDIUM: O(n²) nested loop search
Для Каждого Строка1 Из Таблица1 Цикл
    Для Каждого Строка2 Из Таблица2 Цикл
        Если Строка1.Ключ = Строка2.Ключ Тогда
            // Process match
        КонецЕсли;
    КонецЦикла;
КонецЦикла;

// ✅ OPTIMIZED: O(n) with Map lookup
ИндексТаблицы2 = Новый Соответствие;
Для Каждого Строка2 Из Таблица2 Цикл
    ИндексТаблицы2.Вставить(Строка2.Ключ, Строка2);
КонецЦикла;

Для Каждого Строка1 Из Таблица1 Цикл
    Строка2 = ИндексТаблицы2.Получить(Строка1.Ключ);
    Если Строка2 <> Неопределено Тогда
        // Process match
    КонецЕсли;
КонецЦикла;
```

#### Index a `ТаблицаЗначений` before using `НайтиСтроки` in a loop

If a function returns a `ТаблицаЗначений` and the caller drives `НайтиСтроки(СтруктураПоиска)` over it inside a loop, add an index over the same column set in the producing function. Without an index, `НайтиСтроки` is a linear scan -- combined with the outer loop that becomes O(n²) on large tables.

```bsl
Результат.Индексы.Добавить("Колонка1, Колонка2, Колонка3");
Возврат Результат;
```

The column set in the index must match the keys you pass into `НайтиСтроки`. If multiple search shapes are used, add multiple indexes.

#### Function-per-column duplication

One function that returns a `ТаблицаЗначений` with all the columns you need is better than N functions, one per column. The caller can build a `Соответствие` / index from the same VT when a fast lookup is needed. Splitting the producer into one-column-per-function "for flexibility" multiplies queries against the same source and clutters the public API of the module.

### 10. Deep Nesting

**Impact:** Poor readability, hard to maintain
**Severity:** MEDIUM

```bsl
// ❌ MEDIUM: Deep nesting (>4 levels)
Если Условие1 Тогда
    Если Условие2 Тогда
        Если Условие3 Тогда
            Если Условие4 Тогда
                // Logic
            КонецЕсли;
        КонецЕсли;
    КонецЕсли;
КонецЕсли;

// ✅ OPTIMIZED: Early returns
Если НЕ Условие1 Тогда
    Возврат;
КонецЕсли;

Если НЕ Условие2 Тогда
    Возврат;
КонецЕсли;

Если НЕ Условие3 Тогда
    Возврат;
КонецЕсли;

Если НЕ Условие4 Тогда
    Возврат;
КонецЕсли;

// Logic
```

## Architectural Anti-Patterns

### Big Ball of Mud
- No clear structure
- Everything depends on everything
- **Impact**: Unmaintainable, high change risk

### God Module
- One module does everything
- Hundreds of procedures in single module
- **Impact**: Hard to understand, test, modify

### Tight Coupling
- Modules directly dependent on implementation details
- Changes cascade across modules
- **Impact**: High modification cost

### Copy-Paste Architecture
- Same code in multiple places
- No shared modules
- **Impact**: Inconsistency, maintenance burden

### Premature Optimization
- Complex caching before proving need
- Over-engineered for current scale
- **Impact**: Unnecessary complexity

## Optimized Patterns

### Batch Query with Temp Table

```bsl
МенеджерВТ = Новый МенеджерВременныхТаблиц;

Запрос = Новый Запрос;
Запрос.МенеджерВременныхТаблиц = МенеджерВТ;

// Step 1: Create temp table with input data
Запрос.Текст =
"ВЫБРАТЬ
|   Данные.Номенклатура КАК Номенклатура,
|   Данные.Склад КАК Склад
|ПОМЕСТИТЬ ВТ_Входные
|ИЗ
|   &ТаблицаДанных КАК Данные";
Запрос.УстановитьПараметр("ТаблицаДанных", ТаблицаДанных);
Запрос.Выполнить();

// Step 2: Join with register for batch result
Запрос.Текст =
"ВЫБРАТЬ
|   ВТ_Входные.Номенклатура КАК Номенклатура,
|   ВТ_Входные.Склад КАК Склад,
|   ЕСТЬNULL(Остатки.КоличествоОстаток, 0) КАК Остаток
|ИЗ
|   ВТ_Входные КАК ВТ_Входные
|       ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.ТоварыНаСкладах.Остатки(
|           ,
|           (Номенклатура, Склад) В
|               (ВЫБРАТЬ ВТ.Номенклатура, ВТ.Склад ИЗ ВТ_Входные КАК ВТ)
|       ) КАК Остатки
|       ПО ВТ_Входные.Номенклатура = Остатки.Номенклатура
|           И ВТ_Входные.Склад = Остатки.Склад";
РезультатЗапроса = Запрос.Выполнить();
```

### Bulk SSL Attribute Access

```bsl
// Instead of individual calls in loop
СписокКонтрагентов = ТаблицаДанных.ВыгрузитьКолонку("Контрагент");

// Get all attributes in single call
ТаблицаРеквизитов = ОбщегоНазначения.ЗначенияРеквизитовОбъектов(
    СписокКонтрагентов, "ИНН, КПП, Наименование");

// Build lookup map
СоответствиеРеквизитов = Новый Соответствие;
Для Каждого СтрокаРеквизитов Из ТаблицаРеквизитов Цикл
    СоответствиеРеквизитов.Вставить(
        СтрокаРеквизитов.Ссылка, СтрокаРеквизитов);
КонецЦикла;
```

## Confidence Scoring (for Reviews)

Rate findings on a scale from 0 to 100:

| Score | Description |
|-------|-------------|
| **0-25** | Low confidence - might be false positive |
| **26-50** | Moderate - worth discussing |
| **51-75** | High - likely real issue |
| **76-100** | Very high - confirmed issue with evidence |

**Report only findings with confidence ≥ 75 for code review, ≥ 50 for architecture review.**

## Quick Reference Checklist

| Anti-Pattern | Severity | Check For |
|--------------|----------|-----------|
| Query in loop | CRITICAL | `Для Каждого` followed by `Новый Запрос` |
| Dot notation in BSL code | CRITICAL | `.Реквизит` on references in code (NOT in query text - there it is allowed) |
| Subquery in SELECT | CRITICAL | Nested `ВЫБРАТЬ` in field list |
| Virtual table WHERE | HIGH | Conditions on virtual table results |
| Missing TOP N | HIGH | Large queries without `ПЕРВЫЕ` |
| Multiple server calls | HIGH | Sequential `НаСервере` calls from client |
| &НаСервере misuse | HIGH | Server call not needing form context |
| Missing cache | MEDIUM | Repeated expensive calls with same params |
| O(n²) loops | MEDIUM | Nested loops searching for matches |
| Deep nesting | MEDIUM | >4 levels of conditionals/loops |
