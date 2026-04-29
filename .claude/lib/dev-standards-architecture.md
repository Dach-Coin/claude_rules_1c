---
---

# Development Standards -- Architecture & Platform

## 1. Architecture Patterns (extends project_rules.md)

### Code Placement
- Business logic -- **in common modules**, not in form modules
- Server common modules -- suffixes: `*ServerCall`, `*ObjectModule`, `*ManagerModule`
- Client common modules -- suffix: `*Client`
- Form-related modules -- suffix: `*Forms`
- Server object modules -- mandatory preprocessor: `#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then`

### "Result-Structure" Pattern
Return compound results via `Структура`:

```bsl
Результат = Новый Структура;
Результат.Вставить("ПроверкаПройдена", РезультатПроверки);
Результат.Вставить("ТекстОшибки", ТекстОшибки);
Возврат Результат;
```

### "Early Return" Pattern
Reduce nesting by returning early on precondition failures:

```bsl
Если Отказ Тогда
	Возврат;
КонецЕсли;

Если НЕ ЗначениеЗаполнено(ДатаДействия) Тогда
	Возврат ЗначениеПоУмолчанию;
КонецЕсли;
```

### "Value Table Search" Pattern

```bsl
ПараметрыПоиска = Новый Структура("ТипСпецодежды", ТекущаяСтрока.ТипСпецодежды);
НайденныеСтроки = ТаблицаДанных.НайтиСтроки(ПараметрыПоиска);
Если НайденныеСтроки.Количество() = 0 Тогда
	Продолжить;
КонецЕсли;
```

### Event Subscriptions
Preferable over modifying typical modules. All subscription methods -- via common module `{PREFIX}EventSubscriptions`.

### New Metadata Objects Placement
Determined by `{NEW_OBJECTS_IN}` parameter from `.dev.env`:

| `{NEW_OBJECTS_IN}` | Behavior |
|---|---|
| `main_configuration` | New objects go into main configuration. Extension -- only for event interception |
| `extension` | New objects may be placed in extension. Main configuration not modified without explicit instruction |

Default: `main_configuration`.

### Background Jobs
Operations taking > 10 seconds -- move to background jobs with progress indication. Do not block UI.

### Defensive Type Checking
BSL has no strict typing. Check type at function entry **only when the type really can vary on the module boundary** -- typical case is a public API that accepts `Array` or a single value and must normalise to one collection. This is not a routine measure to be applied to every parameter.

```bsl
Если ТипЗнч(ДокументыИлиСсылка) <> Тип("Массив") Тогда
	МассивДокументов = Новый Массив;
	МассивДокументов.Добавить(ДокументыИлиСсылка);
Иначе
	МассивДокументов = ДокументыИлиСсылка;
КонецЕсли;
```

### Defensive code: real scenarios only
Defensive code is justified only for scenarios that can actually occur in the real call flow. Paranoid guards add dead code and hide bugs.

- **Do NOT write checks for scenarios that cannot happen.** Guards like `Если Параметр = Неопределено Тогда Возврат; КонецЕсли;` over a guaranteed-non-empty source are dead code -- rely on the actual call flow, not on "what if".
- **Do NOT silently fix business-rule violations on behalf of the user.** If input data violates a business invariant, that is not the agent's job to quietly repair. Let the platform raise the standard error with a clear message.
- **Throw exceptions upward instead of silent `Возврат`.** When a branch condition equals a data anomaly, raise `ВызватьИсключение СтрШаблон(НСтр("ru = '...'"), ИдентификаторСлучая)` with concrete context. The transaction picks it up and writes it to the journal / `ТекстОшибки` field.

A silent `Возврат` on a strange situation is diagnostic noise that costs days in log-chasing later.

### Safe Structure Property Access
Always check key existence before access:

```bsl
Если ПараметрыОтчета.Свойство("ДатаНачала", ДатаНачала) Тогда
	// использовать ДатаНачала
КонецЕсли;
```

### Collection Normalization
Normalize input to a single collection type for uniform processing. For single-to-array conversion use a verified SSL helper -- look up the real signature via `mcp__rlm-tools-bsl__rlm_execute` (`find_exports` for `ОбщегоНазначенияКлиентСервер` and similar SSL utility modules) before referencing it in code; do not hard-code an SSL module name from memory.

## 2. Extensions

### Modification Priority
1. **Event subscriptions** (preferred)
2. **Extensions**
3. **Typical code modification** (last resort)

### Extension Directives
- `&Before` / `&After` -- preferred
- `&Instead` -- only for functions, with mandatory `ContinueCall()`

### Placement Rules (when `{NEW_OBJECTS_IN} = main_configuration`)
- New metadata objects -> main configuration
- New attributes of typical objects -> main configuration
- Roles -> main configuration

Regardless of `{NEW_OBJECTS_IN}`:
- Typical roles -> DO NOT modify (create new ones with `{PREFIX}`)

### Forms in Extensions
Visual form editing in extensions -- **minimize**. Changes -- programmatically through code.

## 3. Platform Standards (extends project_rules.md)

### Async and Modality
- Modal calls are **PROHIBITED**: `DoQueryBox()`, `ShowMessageBox()`, `InputNumber()`, etc.
- Approach depends on `{PLATFORM_VERSION}` from `.dev.env`:

| `{PLATFORM_VERSION}` | Approach |
|---|---|
| < 8.3.18 | `NotifyDescription` (callback) |
| >= 8.3.18 | `Async` / `Await` (preferred) |

- Inside `Async` procedures use ONLY async analogs. Mixing `Async/Await` with non-async methods is **PROHIBITED**
- Any dialog calls on the server are **PROHIBITED**

### Client-Server Interaction
- **`&AtServerNoContext` is MANDATORY** for all server methods that do not access form data. `&AtServer` only when method directly reads/writes form attributes or elements
- If a method only needs a form attribute value -- pass it as parameter and use `&AtServerNoContext`

### Security
- `Execute()` and `Eval()` -- **PROHIBITED** without extreme necessity
- **Hardcoded credentials are PROHIBITED** -- passwords, tokens, API keys in code are FORBIDDEN
- **RLS** -- design with access restriction requirements in mind
- **No "anti-spoofing" reset of form attributes on the server.** Form attribute values cannot be tampered with from the client in 1C -- the client never sees the raw transport, the platform serializes the form context. Patterns like `Если ФлагИзФормы И НЕ Пользователи.ЭтоПолноправныйПользователь() Тогда ФлагИзФормы = Ложь; КонецЕсли;` add no security and clutter the code. Restrict access at its real source: disable the control on the client (`Элементы.Флажок.Доступность = Ложь`) and let role-based / RLS / posting-time checks (e.g. period-end-closing) reject the action. If a server method must enforce a hard boundary, make the check itself authoritative -- do not pretend the form attribute is untrusted input.

### Error Handling (extends project_rules.md)
- String localization -- `НСтр("ru = '...'")` with `СтрШаблон(...)` for parameter substitution. Single templating helper across the project: stick to `СтрШаблон` (platform-native primitive) and do NOT mix in alternative SSL helper-wrappers for the same task. If you think you need an SSL templating wrapper, look up the real module signature via `mcp__rlm-tools-bsl__rlm_execute` (`find_exports`) before referencing it -- do not invent module names.
- Error collection -- into a single variable via `Символы.ПС`
- Logging -- canonical form `ОбработкаОшибок.ПодробноеПредставлениеОшибки(ИнформацияОбОшибке())`. The bare call `ПодробноеПредставлениеОшибки(ИнформацияОбОшибке())` is **deprecated since 8.3.17** and reported by BSL Language Server as `DeprecatedMethods8317`. NOT `КраткоеПредставлениеОшибки()` either way.
- Empty exception handlers are **PROHIBITED** -- always log or re-raise

### Headless processing message capture
External processings, scheduled jobs and background jobs run without a form, so anything emitted via `ОбщегоНазначения.СообщитьПользователю(...)` does not reach the user on its own. Capture it explicitly:

- At the **start of every iteration**, before `НачатьТранзакцию`, call `ПолучитьСообщенияПользователю(Истина)` to clear the buffer of foreign messages from the previous iteration.
- In the **`Исключение` block**, call `ПолучитьСообщенияПользователю(Истина)` again -- it returns a `ФиксированныйМассив` of `СообщениеПользователю` objects (read `.Текст`). Join through `Символы.ПС` and append to the canonical error text from `ОбработкаОшибок.ПодробноеПредставлениеОшибки(ИнформацияОбОшибке())`.
- The `Истина` argument is **mandatory** in both calls -- otherwise messages leak into the next iteration or to a foreign form.

Without this pattern the iteration "just fails with an unclear error", because the real diagnostics from standard procedures went to a void.

### Dates
- On server -- `CurrentSessionDate()` instead of `CurrentDate()`

### Document locking before write
- Use `ДокументОбъект.Заблокировать()` (object method) to lock a document before write/post.
- Do **NOT** use `ЗаблокироватьДанныеДляРедактирования()` -- that is a managed-form UI helper, not the right primitive for headless / object-level code.

### Verifying platform and SSL methods (split contract)
Do not invent "magical" `ДополнительныеСвойства` keys, "disable check" flags or SSL module names from memory. If a method or key is needed, look it up:

| What you are verifying | Tool |
|---|---|
| Platform built-in (functions, types, global context, language constructs) | `mcp__1c-syntax__search_syntax`, `mcp__1c-syntax__get_function_info` |
| SSL / БСП module exports (signatures, parameter names) | `mcp__rlm-tools-bsl__rlm_execute` (`find_exports`, `extract_procedures`, `grep`) |

`1c-syntax` does **not** cover SSL / БСП -- using it for SSL lookups returns nothing or wrong results. Conversely `rlm-tools-bsl` operates on configuration sources, not on platform documentation. See `project_rules.md` § "Reference Attribute Access" and `1c-metadata-manage.md` § БСП for the search workflow.

### Queries (extends project_rules.md)
- Temporary tables -- prefixed with `TT_`
- `INNER JOIN` preferred over `LEFT JOIN` when possible
- Filter by dimensions first when accessing registers
- Do not modify register movements directly -- only through posting mechanism

### Cross-Platform Compatibility
- **COM objects** (`New COMObject(...)`) are **PROHIBITED** unless explicitly specified in task
- For Excel -- use spreadsheet document or SSL, not `Excel.Application`
- File paths -- use `/` or system functions, do not hardcode `\`

### Platform Version Compatibility
- Before using any platform API method, verify it exists in `{PLATFORM_VERSION}` from `.dev.env`
- Using methods from newer versions without checking is **PROHIBITED**

## 4. Code Smells (extends anti-patterns.md)

| Smell | Signs | Fix |
|---|---|---|
| **Data Clumps** | Same 3+ parameters passed together in multiple methods | Combine into Structure via constructor function |
| **Primitive Obsession** | Strings instead of enums, numeric codes instead of references | Use `Enum`, `CatalogRef`, `DefinedType` |
| **Divergent Change** | One module constantly changed for different reasons | Split module: each handles one responsibility (SRP) |
| **Shotgun Surgery** | One business logic change requires edits in 5+ places | Consolidate related logic into one common module |
| **Feature Envy** | Form module method heavily works with data of another object | Move method to the common module of that object |
| **Variable Reuse** | One variable stores different values at different stages | Create separate variable for each value |
