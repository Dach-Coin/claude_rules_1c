# Coding standards (1C / BSL)

<!-- Scope: coding standards, query rules, data access, performance.
     Persona, tool selection, workflow and skill dispatch live elsewhere:
     - CLAUDE.md — persona, project parameters, workflow
     - .claude/rules/mcp-tools.md — tool selection, task-to-tool mapping
     - .claude/skills_instructions.md — skill dispatch -->

## Scope

This file documents BSL coding standards only. For tool selection, workflow and orchestration, see the links above.

## Coding Guidelines

- Follow `bsl-language-server` recommendations surfaced by `claude-code-bsl-lsp`.
- Do not use `Попытка...Исключение` (Try/Except) for reading from or writing to the database unless there is a specific, well-justified reason for transaction control.
- Do not call `ЗаписьЖурналаРегистрации()` unless explicitly asked.
- Do not use `Сообщить()` to report messages to the user. Use `ОбщегоНазначения.СообщитьПользователю` (server-side) or `ОбщегоНазначенияКлиент.СообщитьПользователю` (client-side) instead.
- Avoid boolean comparisons to `Истина`/`Ложь`; use boolean expressions directly.
- Simple ternary operators `?(Condition, TrueValue, FalseValue)` are allowed. Nested ternary operators are **PROHIBITED**.
- Do not use Hungarian notation for variable names (e.g., use `Контрагенты` instead of `МассивКонтрагентов`).
- Do not use names from the 1C global context for variables (e.g., `Документы`, `Справочники`, `Пользователи`, `Регистры`, `Метаданные`, `Константы`) — they create collisions and hurt readability.

## Comments

- Prefer self-documenting code over comments. Avoid comments that simply repeat what the code does.
- Comments are appropriate only when they add value: explaining motivation/reasoning, describing a non-trivial algorithm, documenting constraints/side effects, marking technical debt, or providing context that cannot be expressed clearly in code.

## Code Review

- After any code edit, perform an internal code review (style, readability, correctness, edge cases, security, concurrency, best-practice compliance). If issues are found, fix them and repeat the review cycle until the code is clean, correct and stable.
- Check for concurrency issues and correct use of locks/transactions. Always consider whether an outer transaction exists (e.g. the object-write transaction).

## Module Regions

- Use regions with the following purposes:
  - `ПрограммныйИнтерфейс` — public interface
  - `СлужебныйПрограммныйИнтерфейс` — internal/private interface
  - `СлужебныеПроцедурыИФункции` — helper procedures and functions

## Code Reuse

- Before writing code, inspect common modules and manager modules for existing export methods that can be reused to avoid duplication. Use `mcp__rlm-tools-bsl__rlm_execute` (grep, find_exports, extract_procedures) to find reusable implementations.

# Code Formatting

- Limit lines to 120 characters when a line can be wrapped correctly.
- Do not introduce a line break that would leave a single variable alone on the next line.
- In conditions and loops, add blank lines before and after the code inside the block for better readability.

# Query Guidelines

- When writing queries, verify metadata attributes (existence, names, types) via `mcp__rlm-tools-bsl__rlm_execute` (`parse_object_xml`, `glob_files`).
- Use the following formatting for queries (query text on a new line at the same indentation level as the variable declaration):

```bsl
Запрос = Новый Запрос;
Запрос.Текст =
"ВЫБРАТЬ
|	Контрагенты.Ссылка КАК Ссылка,
|	Контрагенты.ИНН КАК ИНН
|ИЗ
|	Справочник.Контрагенты КАК Контрагенты";
```

- Always use an intermediate variable for the query result. Do not chain methods directly:
  - Correct: `РезультатЗапроса = Запрос.Выполнить();`
  - Incorrect: `Запрос.Выполнить().Выгрузить()` or `Запрос.Выполнить().Выбрать()`
- Always use aliases for query fields with `КАК`, e.g. `Контрагенты.ИНН КАК ИНН`.
- Avoid queries inside loops. Use batch queries and temporary tables instead.
- Use query parameters (`Запрос.УстановитьПараметр()`) instead of string concatenation to prevent SQL injection and improve performance.
- For complex data retrieval, prefer batch queries with temporary tables over multiple separate queries.

# Data Access Guidelines

## Reference Attribute Access

Do not access reference attributes via dot notation (e.g. `Контрагент.ИНН`) — it fetches the entire object from the database. Use the dedicated BSP (`ОбщегоНазначения`) helpers instead:

| Method | Purpose | Example |
|---|---|---|
| `ОбщегоНазначения.ЗначениеРеквизитаОбъекта` | Single attribute from one ref | `ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Контрагент, "ИНН")` |
| `ОбщегоНазначения.ЗначенияРеквизитовОбъекта` | Multiple attributes from one ref | `ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Контрагент, "ИНН, Наименование")` |
| `ОбщегоНазначения.ЗначениеРеквизитаОбъектов` | Same attribute from multiple refs | `ОбщегоНазначения.ЗначениеРеквизитаОбъектов(МассивКонтрагентов, "ИНН")` |

BSP function reference: read signatures directly from BSP modules via `mcp__rlm-tools-bsl__rlm_execute` (`find_exports`, `extract_procedures`); see `.claude/skills/1c-metadata-manage/docs/ssl-patterns.md` for the search workflow. `1c-syntax` does not cover BSP modules — it only documents platform built-ins.

## Caching in Loops

Use caching with `Соответствие` (Map) for repeated calculations in loops:

```bsl
КэшИНН = Новый Соответствие;

Для Каждого Строка Из ТаблицаДанных Цикл

    ИНН = КэшИНН.Получить(Строка.Контрагент);
    Если ИНН = Неопределено Тогда
        ИНН = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Строка.Контрагент, "ИНН");
        КэшИНН.Вставить(Строка.Контрагент, ИНН);
    КонецЕсли;

    // Use ИНН...

КонецЦикла;
```

Caching is appropriate for:
- Catalog lookups
- Attribute retrieval
- Repeated algorithm computations
- Any expensive operation called multiple times with the same parameters

## Batch Data Retrieval

- When you need data for multiple references, prefer batch retrieval over individual calls.
- Use queries with `В (&МассивСсылок)` instead of looping through references.

# Performance & Optimization Guidelines

Logic and performance review is manual in the current toolset — follow the checklists in `.claude/rules/anti-patterns.md` plus diagnostics from `claude-code-bsl-lsp`. See Capability boundaries in `.claude/rules/mcp-tools.md`.

## Server Context

- Use server context for bulk operations.
- Avoid client-server round trips inside loops.
- Prefer `&НаСервереБезКонтекста` when form context is not needed.

## Query Optimization

- Prefer queries over manual iteration for data retrieval from collections.
- Index frequently queried fields in configuration metadata.
- Avoid queries inside loops — use batch queries with temporary tables.
- Use `ПЕРВЫЕ N` (TOP N) when only a subset of records is needed.

## Privileged Mode

- Use `УстановитьПривилегированныйРежим(Истина)` sparingly and only when necessary.
- Always disable it after the privileged operation: `УстановитьПривилегированныйРежим(Ложь)`.
- Use `ПривилегированныйРежим()` to check the current state.
- Verify signatures of privileged-mode helpers in `mcp__1c-syntax__search_syntax`.

## Caching Strategies

- Cache expensive calculations using:
  - `Соответствие` (Map) for in-memory caching within a single operation
  - Session parameters for session-scoped caching
  - Information registers for persistent caching across sessions
- Combine `ОбщегоНазначения.ЗначенияРеквизитовОбъекта` with caching for repeated attribute access.

## Collection Operations

- Prefer `ЗаполнитьЗначенияСвойств()` for bulk property assignment.
- Use `НайтиПоЗначению()` / `Найти()` for collection searches instead of manual loops.
- For large collections, consider `Соответствие` for O(1) lookups instead of O(n) array searches.

## Transaction Management

- Keep transactions as short as possible.
- Avoid user interaction inside transactions.
- Be aware of implicit transactions (e.g. object writes).

# Metadata Management

Structural metadata work (creating/editing/validating objects, forms, reports, layouts, roles, extensions, databases) is delegated to the `1c-metadata-manage` skill — see `.claude/skills_instructions.md`. For multi-step or multi-domain metadata work, invoke the `metadata-manager` agent. For a single lookup, inspect the configuration directly via `mcp__rlm-tools-bsl__rlm_execute` (parse_object_xml).

# Documentation

- Document public procedures/functions with purpose, parameters and return values.
- Use `//BSLLS:` comments for targeted bsl-language-server suppressions.
