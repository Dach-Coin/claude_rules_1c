# 1C SSL/БСП Subsystems Reference

This guide helps discover and reuse SSL/БСП subsystems. The current toolset does not provide a dedicated semantic SSL search - see Capability boundaries in `.claude/rules/mcp-tools.md`. Use the combined approach below instead.

For basic SSL usage (attribute access, user messages) - see `.claude/rules/project_rules.md`.

## When to Use

Invoke this guide when:
- Working with users and access rights
- Working with files and attachments
- Implementing print forms
- Managing background jobs
- Working with object versioning
- Sending emails
- You need common utility functions (arrays, structures, strings)

## Core Principle

**ALWAYS check whether SSL already has a solution before writing custom code.**

## SSL Search Workflow

When implementing new functionality:

1. **Identify the relevant BSP subsystem by name.** The key modules are listed below. Map your need (e.g. "background job with progress") to a module name (e.g. `ДлительныеОперации`).

2. **Locate the module inside the current configuration.**
   - `mcp__rlm-tools-bsl__rlm_execute` with `glob_files` for `CommonModules/<ModuleName>/Ext/Module.bsl`
   - `mcp__rlm-tools-bsl__rlm_execute` with `find_exports('<ModuleName>')` to list exported procedures
   - `mcp__rlm-tools-bsl__rlm_execute` with `extract_procedures('<ModuleName>', '<ProcedureName>')` to read a specific procedure

3. **Validate the call signature before using it.**
   - For BSP/SSL procedures - read the signature directly from the module source via `rlm_execute` (`extract_procedures`). `1c-syntax` does NOT cover BSP modules - it only documents platform built-ins.
   - `mcp__1c-syntax__get_function_info` is appropriate only for platform-level built-ins that may be referenced from the same code path (e.g. `СтрДлина`, `ТекущаяДата`).
   - `mcp__1c-syntax__validate_syntax` - also only for platform built-ins.

4. **Find existing usage patterns in the codebase.**
   - `mcp__rlm-tools-bsl__rlm_execute` with `find_callers('<ModuleName>.<ProcedureName>')`
   - `mcp__rlm-tools-bsl__rlm_execute` with `find_callers_context(...)` to see how the helper is actually invoked

5. **Use SSL if available** - it's tested, optimized and maintained.

6. **Only then write custom code** - and document why SSL wasn't suitable.

## Key SSL Modules

- **Пользователи** - users, roles, access rights
- **РаботаСФайлами** - file storage and attachments
- **УправлениеПечатью** - print forms
- **ДлительныеОперации** - background jobs with progress
- **ВерсионированиеОбъектов** - object history
- **РаботаСПочтовымиСообщениями** - email sending
- **ОбщегоНазначения** / **ОбщегоНазначенияКлиентСервер** - common utilities
- **СтроковыеФункцииКлиентСервер** - string functions

---

**Remember**: SSL is your first stop for common functionality. Writing custom code when SSL has a solution is technical debt.
