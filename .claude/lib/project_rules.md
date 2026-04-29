# Coding standards (1C / BSL)

<!-- Scope: coding standards, query rules, data access, performance.
     Persona, tool selection, workflow and skill dispatch live elsewhere:
     - CLAUDE.md - persona, project parameters, workflow
     - .claude/lib/mcp-tools.md - tool selection, task-to-tool mapping
     - .claude/skills_instructions.md - skill dispatch -->

## Scope

This file documents BSL coding standards only. For tool selection, workflow and orchestration, see the links above.

## Coding Guidelines

- Follow `bsl-language-server` recommendations (plugin in-session, or `bsl-language-server.exe --analyze` from the CLI). It is a Claude Code plugin, not an MCP server - never call it with an `mcp__*` prefix.
- Do not use `Попытка...Исключение` (Try/Except) for reading from or writing to the database unless there is a specific, well-justified reason for transaction control.
- Do not call `ЗаписьЖурналаРегистрации()` unless explicitly asked.
- Do not use `Сообщить()` to report messages to the user. Use `ОбщегоНазначения.СообщитьПользователю` (server-side) or `ОбщегоНазначенияКлиент.СообщитьПользователю` (client-side) instead.
- Avoid boolean comparisons to `Истина`/`Ложь`; use boolean expressions directly.
- Simple ternary operators `?(Condition, TrueValue, FalseValue)` are allowed. Nested ternary operators are **PROHIBITED**.
- Do not use Hungarian notation for variable names (e.g., use `Контрагенты` instead of `МассивКонтрагентов`).
- Do not use names from the 1C global context for variables (e.g., `Документы`, `Справочники`, `Пользователи`, `Регистры`, `Метаданные`, `Константы`) - they create collisions and hurt readability.

## Comments

- Prefer self-documenting code over comments. Avoid comments that simply repeat what the code does.
- Comments are appropriate only when they add value: explaining motivation/reasoning, describing a non-trivial algorithm, documenting constraints/side effects, marking technical debt, or providing context that cannot be expressed clearly in code.

### Human-like comments

Live developers write comments rarely, briefly, and only to explain the *motive* that the code itself cannot show. Agent-generated commentary tends to over-explain. Match the human style.

**Anti-patterns - do not write:**

- **Banner separators** (`// ====================== ИНИЦИАЛИЗАЦИЯ ФОРМЫ ======================`) - regions (`#Область` / `#КонецОбласти`) handle visual structure.
- **Module-header preambles** with formal "Назначение / Автор / Версия" fields - that information lives in version control and metadata, not in source comments.
- **Restating the next line** of code (`// Устанавливаем видимость кнопки` immediately above `Кнопка.Видимость = Истина;`).
- **Lecturing tone** - "Здесь мы инициализируем...", "Важно отметить, что...", "Далее выполняется проверка...". Drop the meta-narration.
- **Apologetic / historical commentary** - "// TODO: разобраться, почему это вообще работает", "// Костыль, но платформа не дает иначе". Either fix it or describe the constraint factually.
- **Comments around obvious guards** like `Если НЕ ЗначениеЗаполнено(Ссылка) Тогда Возврат; КонецЕсли;` - the code reads itself.

**Acceptable patterns - one short line, motive only:**

- Non-obvious invariant or constraint that the reader cannot infer from the code.
- Platform-specific workaround for a specific known bug.
- Order-of-operations remark when the order is load-bearing and not visible from the call site.
- Public `Экспорт`-procedures get the formal documentation header from `dev-standards-core.md` § "Procedure/Function Documentation" - that is API documentation, not narrative inside the body.

**Rule of thumb:** if removing a comment would not confuse a future reader, the comment is noise. Prefer fewer, sharper comments over many bland ones.

**Length budget:** the default for an inline comment is 1-2 lines, the hard maximum is 3. If a comment grows to 4-5 lines, it has drifted into narration -- compress to the motive. The formal `Параметры` / `Возвращаемое значение` block is API documentation and applies **only to `Экспорт`-procedures** (see `dev-standards-core.md` § "Procedure/Function Documentation"); internal/non-exported procedures get no such block.

| Form | Comment |
|---|---|
| OK | `// Платформа теряет привязку, если перечитать набор внутри транзакции.` |
| OK | `// Порядок важен: сначала очистка движений, затем перезаполнение.` |
| OK | `// Обход бага платформы 8.3.21 с двойным вызовом ПриЗаписи.` |
| NOT OK | `// Устанавливаем флаг проведения` (over `Документ.Проведен = Истина;`) |
| NOT OK | `// =========== ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ ===========` |
| NOT OK | `// Здесь мы получаем данные из регистра и обрабатываем их` |

## Code Review

- After any code edit, perform an internal code review (style, readability, correctness, edge cases, security, concurrency, best-practice compliance). If issues are found, fix them and repeat the review cycle until the code is clean, correct and stable.
- Check for concurrency issues and correct use of locks/transactions. Always consider whether an outer transaction exists (e.g. the object-write transaction).

## Module Regions

- Use regions with the following purposes:
  - `ПрограммныйИнтерфейс` - public interface
  - `СлужебныйПрограммныйИнтерфейс` - internal/private interface
  - `СлужебныеПроцедурыИФункции` - helper procedures and functions

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

### INNER JOIN predicates -- in `ПО`, not in `ГДЕ`

For an `ВНУТРЕННЕЕ СОЕДИНЕНИЕ`, the SQL optimizer collapses both forms into the same plan. For the **reader**, one block of conditions in one place is easier to follow than predicates split between `ПО` and `ГДЕ`.

```sql
-- Bad: predicates split between ПО and ГДЕ
ВНУТРЕННЕЕ СОЕДИНЕНИЕ Документ.ЗаказКлиента.Товары КАК ЗКТовары
    ПО ПТУТовары.Номенклатура = ЗКТовары.Номенклатура
ГДЕ
    ПТУТовары.Количество > 0
    И ЗКТовары.Ссылка.Проведен

-- Good: full join condition in ПО
ВНУТРЕННЕЕ СОЕДИНЕНИЕ Документ.ЗаказКлиента.Товары КАК ЗКТовары
    ПО (ПТУТовары.Номенклатура = ЗКТовары.Номенклатура)
        И (ПТУТовары.Количество > 0)
        И (ЗКТовары.Ссылка.Проведен)
```

The example uses non-composite reference fields (`Номенклатура`) on purpose. **If the joined field is of composite type** (`ДокументОснование`, `Объект`, etc.), this rule does NOT lift the composite-type restriction below: dot dereference of a composite field is still prohibited in `ПО` and `ГДЕ` -- pin the type in a temp table via `ВЫРАЗИТЬ(...)` first, then use the mono-typed field in the join.

**This rule applies only to INNER JOIN.** For LEFT JOIN, `ПО` and `ГДЕ` have **different semantics**: a predicate in `ПО` filters only the right side (the left row stays with `NULL`s); the same predicate in `ГДЕ` drops the whole row. Do not mechanically migrate LEFT JOIN predicates from `ГДЕ` into `ПО`.

### Final selection from a temp-table reference -- via dot notation, no explicit JOIN

If a temp table already holds `Ссылка` of a document/catalog, fetch its attributes through dot notation in the final SELECT. The platform builds the JOIN automatically; an explicit join is unnecessary noise.

```sql
-- Bad: redundant explicit join
ВЫБРАТЬ Док.Ссылка, Док.Дата, Док.Номер
ИЗ Документ.X КАК Док
    ВНУТРЕННЕЕ СОЕДИНЕНИЕ ВТ_Список КАК ВТ
    ПО Док.Ссылка = ВТ.Ссылка

-- Good: dot notation from ВТ.Ссылка
ВЫБРАТЬ
    ВТ_Список.Ссылка КАК Ссылка,
    ВТ_Список.Ссылка.Дата КАК Дата,
    ВТ_Список.Ссылка.Номер КАК Номер
ИЗ ВТ_Список КАК ВТ_Список
```

Explicit `ВНУТРЕННЕЕ СОЕДИНЕНИЕ Документ.X` is justified only for virtual fields (e.g., posting flag from a register virtual table) or a non-default join type.

## Dot Notation in Query Text

Dereferencing reference fields through a dot in **query text** is the standard 1C idiom (it expands into an automatic LEFT JOIN handled by the platform). It is allowed and preferred over manual JOINs for ordinary references.

```sql
ВЫБРАТЬ
    Заказ.Контрагент.ИНН КАК ИНН,
    Заказ.Договор.Валюта КАК Валюта
ИЗ
    Документ.ЗаказКлиента КАК Заказ
```

**Composite-type fields require care:**
- In **JOIN conditions** (`ПО ... = ...`) and `ГДЕ` predicates - dot dereference of a composite-type field is **PROHIBITED** (each branch generates a separate JOIN, plan blows up). Convert via temp table or `ВЫРАЗИТЬ(...)` upfront.
- In the **SELECT list** - allowed only when the field is wrapped in `ВЫРАЗИТЬ(... КАК Документ.ИмяТипа)` to fix the type:
  ```sql
  ВЫБРАТЬ ВЫРАЗИТЬ(ЗП.ДокументОснование КАК Документ.ЗаказКлиента).Номер КАК Номер
  ```

**Two-step pattern for composite-type attributes** -- the canonical way to dereference a composite-type field through several attributes is split into two temp tables:

```sql
// VT1: pin the type via ВЫРАЗИТЬ in SELECT
ВЫБРАТЬ
    Док.Ссылка КАК Док,
    ВЫРАЗИТЬ(Док.ДокументОснование КАК Документ.ЗаказКлиента) КАК ЗаказКлиента
ПОМЕСТИТЬ ВТ_Док
ИЗ
    Документ.X КАК Док
ГДЕ
    Док.ДокументОснование ССЫЛКА Документ.ЗаказКлиента
;

// VT2: dot-dereference attributes from the now mono-typed field
ВЫБРАТЬ ... ИЗ ВТ_Док ГДЕ ЗаказКлиента.Проведен
```

In the first VT use `ВЫРАЗИТЬ(... КАК Документ.X)` in the SELECT to fix the type; in the second VT pull `.Реквизит` off the mono-typed field. **Never** dot-dereference a composite field directly in `ГДЕ` / `ПО` of the source query.

**Do not confuse with the BSL anti-pattern:** dot notation in **BSL code** (`Контрагент.ИНН` on a reference variable) loads the whole object - that is forbidden, see `.claude/lib/anti-patterns.md` and the section below.

# Data Access Guidelines

## Reference Attribute Access (in BSL code)

Do not access reference attributes via dot notation **in BSL code** (e.g. `Контрагент.ИНН` on a reference variable) - it fetches the entire object from the database. This restriction is for code, not query text (see "Dot Notation in Query Text" above). Use the dedicated BSP (`ОбщегоНазначения`) helpers instead:

| Method | Purpose | Example |
|---|---|---|
| `ОбщегоНазначения.ЗначениеРеквизитаОбъекта` | Single attribute from one ref | `ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Контрагент, "ИНН")` |
| `ОбщегоНазначения.ЗначенияРеквизитовОбъекта` | Multiple attributes from one ref | `ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Контрагент, "ИНН, Наименование")` |
| `ОбщегоНазначения.ЗначениеРеквизитаОбъектов` | Same attribute from multiple refs | `ОбщегоНазначения.ЗначениеРеквизитаОбъектов(МассивКонтрагентов, "ИНН")` |

BSP function reference: read signatures directly from BSP modules via `mcp__rlm-tools-bsl__rlm_execute` (`find_exports`, `extract_procedures`); see the SSL/БСП section in `.claude/1c-metadata-manage.md` for the search workflow. `1c-syntax` does not cover BSP modules - it only documents platform built-ins.

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

Logic and performance review is manual in the current toolset - follow the checklists in `.claude/lib/anti-patterns.md` plus diagnostics from `bsl-language-server`. See Capability boundaries in `.claude/lib/mcp-tools.md`.

## Server Context

- Use server context for bulk operations.
- Avoid client-server round trips inside loops.
- Prefer `&НаСервереБезКонтекста` when form context is not needed.

## Query Optimization

- Prefer queries over manual iteration for data retrieval from collections.
- Index frequently queried fields in configuration metadata.
- Avoid queries inside loops - use batch queries with temporary tables.
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
- **If the read must be consistent with a lock, the cache lives exactly one transaction (one unit of work) -- not longer.** A cache that survives across iterations or across the outer loop will desynchronise from the data the lock guards. For per-iteration work: rebuild the cache inside the same transaction that takes the lock.

## Collection Operations

- Prefer `ЗаполнитьЗначенияСвойств()` for bulk property assignment.
- Use `НайтиПоЗначению()` / `Найти()` for collection searches instead of manual loops.
- For large collections, consider `Соответствие` for O(1) lookups instead of O(n) array searches.

## Transaction Management

- Keep transactions as short as possible.
- Avoid user interaction inside transactions.
- Be aware of implicit transactions (e.g. object writes).

# Metadata Management

Structural metadata work (creating/editing/validating objects, forms, reports, layouts, roles, extensions, databases) is routed through `.claude/1c-metadata-manage.md` (project-specific rules and the domain -> skill table) and the dispatch table in `.claude/skills_instructions.md`. For multi-step or multi-domain metadata work, invoke the `metadata-manager` agent. For a single lookup, inspect the configuration directly via `mcp__rlm-tools-bsl__rlm_execute` (parse_object_xml).

# Documentation

- Document public procedures/functions with purpose, parameters and return values.
- For targeted bsl-language-server suppression at one call site, use `//BSLLS:<DiagnosticKey>`.
- For systemic noise that is not relevant to this project, suppress at **module level** with `// BSLLS:<DiagnosticKey>-off` placed at the file head -- one comment per diagnostic, one diagnostic per line. Typical candidates:
  - `// BSLLS:MissingParameterDescription-off`
  - `// BSLLS:MissingReturnedValueDescription-off`
  - `// BSLLS:NestedFunctionInParameters-off`
  - `// BSLLS:QueryNestedFieldsByDot-off`

  In the snippets above `<DiagnosticKey>` is a placeholder -- replace with the real diagnostic key (`MissingParameterDescription`, etc.) when applying.

  Do not abuse module-level suppression: before adding it, confirm the diagnostic is genuinely irrelevant for the project, not just noisy on the current snippet. Targeted point suppression stays the default for one-off exceptions.
