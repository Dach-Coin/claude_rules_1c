# MCP Tools and Code Review Tools Reference

<!-- Scope: this file is the single source of truth for tool selection and tool-driven workflows.
     Coding standards live in project_rules.md. Skills live in skills_instructions.md. -->

## Scope

- This file describes the tool-driven sources available in the current environment and maps engineering tasks to the right tool.
- Coding standards (queries, data access, performance, formatting) - see `project_rules.md`.
- Local skills (flat upstream set under `.claude/skills/`) - full registry and dispatch table in `.claude/skills_instructions.md`. Metadata-domain knowledge map (project-specific rules, routing) - in `.claude/1c-metadata-manage.md`.

## Overview

Three distinct sources cover all tool-driven work on a 1C codebase. **Two** are MCP servers (registered under `mcpServers` in `~/.claude.json`); **one** is a language-server plugin that runs outside the MCP channel - they are different kinds of tools, do not conflate them.

| Source | Kind | Purpose |
|---|---|---|
| **rlm-tools-bsl** | MCP server (http://127.0.0.1:9000/mcp) | Exploration of the 1C codebase (BSL modules, XML metadata, call graph, cross-references) through a Python sandbox session |
| **1c-syntax** | MCP server (stdio) | Platform reference (built-in functions, methods, objects, syntax validation, autocomplete). This is the MCP that the `1c_syntax_skills` slash-command points you to. |
| **bsl-language-server** | Plugin + local CLI (NOT an MCP server) | Diagnostics for `.bsl` / `.os` (errors, style warnings). Runs as a Claude Code plugin (`[bsl-language-server] Up to date (vX.Y.Z)` at SessionStart) and as a local CLI (`bsl-language-server.exe --analyze`). Do NOT call it with an `mcp__*` prefix - it is not exposed over MCP. |

The rule: **never use `Grep`/`find`/custom parsing on BSL code when `rlm-tools-bsl` is available**.

---

## 1. rlm-tools-bsl - code exploration

### Purpose

Token-efficient analysis of 1C configurations through a Python sandbox. No vector index is required - the tool issues targeted queries (grep, call graph, XML parsing) and returns filtered results. Typical reduction: 2000+ raw lines → 15-50 filtered lines.

### Tools

| Tool | Purpose |
|---|---|
| `mcp__rlm-tools-bsl__rlm_start` | Open an analysis session with a target depth (low/medium/high/max) and a context budget |
| `mcp__rlm-tools-bsl__rlm_execute` | Run Python helpers inside the sandbox - grep, module/procedure lookup, XML parsing |
| `mcp__rlm-tools-bsl__rlm_end` | Close the session and release resources |
| `mcp__rlm-tools-bsl__rlm_projects` | Manage the project registry (list/add/remove/rename/update), reference a project by name instead of a path |
| `mcp__rlm-tools-bsl__rlm_index` | Build/update/info/drop an SQLite index of methods and the call graph (needed on configurations with more than ~20K files) |

### Session lifecycle

1. `rlm_start` - always the first call before any exploration.
2. `rlm_execute` - any number of investigative queries.
3. `rlm_end` - always close the session at the end of the investigation.

Sessions that stay open waste server resources; do not skip `rlm_end`.

### Typical `rlm_execute` helpers

- **BSL-aware**: `find_module()`, `extract_procedures()`, `find_exports()`, `find_callers()`, `find_callers_context()`, `parse_object_xml()`, `read_procedure()`
- **Filesystem**: `glob_files()`, `grep()`, `grep_summary()`, `read_file()`, `tree()`
- **Full-text search (FTS5)** across procedures, modules, comments
- **Call graph** for tracing dependencies between procedures
- **Object synonyms** (Russian ↔ English names)

### When to use

- Looking for an existing pattern inside the configuration before writing new code
- Checking where a function/procedure is called from
- Verifying metadata existence, structure, XML composition
- Descriptive search across synonyms (partial replacement for the lost NL metadata search - see Capability boundaries)
- Locating SSL/БСП usage by module name (e.g. `ОбщегоНазначения*`)

---

## 2. 1c-syntax - platform reference

### Purpose

Platform reference built from the bundled platform help (`shcntx_ru.hbk`). Looks up functions, methods, objects by name in Russian or English; validates call syntax; offers autocomplete.

### Tools

| Tool | Purpose |
|---|---|
| `mcp__1c-syntax__search_syntax` | Search platform entries by name (supports both languages) |
| `mcp__1c-syntax__get_function_info` | Full reference for one entry - signature, parameters, return value, description, object members |
| `mcp__1c-syntax__suggest_completion` | Prefix-based autocomplete (e.g. `Стр…`) |
| `mcp__1c-syntax__validate_syntax` | Check that a call matches the documented signature |

### When to use

- Any time you are unsure about a built-in function or method - **before** writing the call
- Validating a call signature after writing code that uses an unfamiliar API
- Autocomplete while drafting expressions

### Known gaps

- Help topics and user-facing articles are not available here - accept the reduction.

---

## 3. bsl-language-server - diagnostics and navigation (plugin, not MCP)

### Purpose

BSL Language Server runs as a Claude Code plugin over the Language Server Protocol and as a standalone CLI. It binds to `.bsl` / `.os` files and provides the usual IDE-grade capabilities. **It is not registered under `mcpServers`** and must not be invoked with an `mcp__*` prefix. In older versions of this document the same component was referred to as `claude-code-bsl-lsp` (the obsolete wrapper name) - use `bsl-language-server` everywhere now.

Two ways to drive it:

- **As a plugin (LSP)** - diagnostics and navigation inside the editor session; runs automatically.
- **As a local CLI** - `bsl-language-server.exe --analyze --reporter=json --srcDir <dir> --outputDir <dir>` for batch diagnostics (e.g. for full-module or full-processor passes).

### Capabilities

- **Diagnostics** - errors and style warnings following 1C standards
- **Go to Definition** - jump to the declaration of a procedure/function/variable
- **Find References** - list all usages of a symbol across the project
- **Hover** - types and documentation on hover
- **Code Actions** - Quick Fixes
- **Symbol Navigation** - document/project symbol list
- **Formatting** - apply formatting rules
- **Rename** - rename-symbol refactor across the project

The server auto-updates in the background; a status line `[bsl-language-server] Up to date (vX.Y.Z)` is printed at session start.

### When to use

- After writing or modifying any BSL code - required diagnostics pass
- Before considering a review finished - navigate symbols, follow definitions/references
- During refactoring - use rename instead of search-and-replace

### Iteration limit

When the diagnostics pass returns style warnings (not errors), run at most **three** fix iterations on a given fragment. If style warnings persist after that, move on - do not keep looping.

---

## Task → tool mapping

Always formulate the task first, then pick the tool.

| Task | Primary | Fallback | Lost capability (if any) |
|---|---|---|---|
| Find code patterns in the current configuration | `rlm_execute` (grep, extract_procedures) | Direct `Read` on located files | Curated cross-project templates |
| Find usages of a function/procedure | `rlm_execute` (find_callers, find_callers_context) | `rlm_execute` grep | Semantic-mode code search |
| Check metadata existence / structure | `rlm_execute` (parse_object_xml, glob_files) | Read XML directly | Semantic/NL metadata lookup |
| Semantic (NL) search for metadata by description | `rlm_execute` (grep over synonyms + parse_object_xml) | - | Full NL metadata search is lost |
| Reference on a built-in function / method / object | `mcp__1c-syntax__search_syntax` → `get_function_info` | - | Help topics partial |
| Autocomplete while writing code | `mcp__1c-syntax__suggest_completion` | - | - |
| Validate a call signature | `mcp__1c-syntax__validate_syntax` | - | - |
| Find an SSL/БСП function to reuse | `rlm_execute` (grep over known BSP module names: `ОбщегоНазначения*`, `ОбщегоНазначенияКлиентСервер*`, `СтроковыеФункцииКлиентСервер*`, etc.) + `rlm_execute` (`find_exports`, `extract_procedures`) to read the signature from the module source | See SSL/БСП section in `.claude/1c-metadata-manage.md` | Semantic "which BSP function fits this task" |
| Diagnose a module after writing | `bsl-language-server` (plugin or `bsl-language-server.exe --analyze`) | - | - |
| Analyze logic / performance | Checklist: `bsl-anti-patterns` skill + `dev-standards-*.md` + `project_rules.md` + LSP diagnostics + manual review | - | Automated logic/perf analyzer |
| Open an analysis session | `mcp__rlm-tools-bsl__rlm_start` | - | - |
| Index a large configuration | `mcp__rlm-tools-bsl__rlm_index` (build/update/info/drop) | - | - |
| Manage the project registry | `mcp__rlm-tools-bsl__rlm_projects` | - | - |
| Close an analysis session | `mcp__rlm-tools-bsl__rlm_end` | - | - |

---

## Capability boundaries

The new toolset does not cover every capability of the previous one. The list below is the honest scope of what is reduced or lost. Instructions must not claim new tools cover these cases fully.

| Capability | Status | Compensation |
|---|---|---|
| Curated cross-project code templates | **Lost** | Examples inside the current configuration (`rlm_execute`) + `bsl-anti-patterns` skill + `.claude/1c-metadata-manage.md` |
| Semantic search over BSP functions | **Reduced** | `rlm_execute` grep over known BSP module names + SSL/БСП section in `.claude/1c-metadata-manage.md` |
| Natural-language search for metadata | **Reduced** | `rlm_execute` grep over synonyms and object names + `parse_object_xml`; expect multiple iterations |
| Automated logic / performance analyzer | **Lost** | Manual checklist: `bsl-anti-patterns` skill + `dev-standards-*.md` + LSP + human review |
| Help topics / user-facing articles | **Reduced** | `search_syntax` / `get_function_info` give platform reference only |
| Semantic / hybrid code search | **Reduced** | `rlm_execute` provides grep and call graph, no semantic mode |
| Cypher graph queries over metadata | **Lost** | `rlm_execute` (`parse_object_xml` + grep over XML) |

---

## Workflow scenarios

### Writing new code

1. Open a session: `rlm_start`.
2. Find existing patterns / reusable functions: `rlm_execute` (grep, find_callers, extract_procedures).
3. Verify metadata you will touch: `rlm_execute` (parse_object_xml).
4. Validate unfamiliar platform calls: `1c-syntax.search_syntax` → `get_function_info`.
5. Draft the code (see `project_rules.md`, `dev-standards-core.md`, `dev-standards-architecture.md`).
6. Diagnostics pass: `bsl-language-server`. Fix errors; at most three iterations on style warnings.
7. Close the session: `rlm_end`.

### Reviewing code

1. `rlm_start`.
2. Verify the pattern against the rest of the configuration: `rlm_execute` (find_callers, grep).
3. Metadata sanity: `rlm_execute` (parse_object_xml).
4. Platform correctness: `1c-syntax.validate_syntax`.
5. Diagnostics: `bsl-language-server`.
6. Manual checklist against `bsl-anti-patterns` skill + `dev-standards-*.md` (this replaces the former automated analyzer).
7. `rlm_end`.

### Fixing errors

1. `rlm_start`.
2. Locate the defect and its call sites: `rlm_execute` (grep, find_callers).
3. Reference for platform APIs in the failing area: `1c-syntax.search_syntax` → `get_function_info`.
4. Apply the minimal fix.
5. Diagnostics: `bsl-language-server`.
6. `rlm_end`.

### Performance optimization

1. `rlm_start`.
2. Find hot loops / query-in-loop / dot access: `rlm_execute` (grep patterns, find_callers).
3. Inspect register usage and indices via XML: `rlm_execute` (parse_object_xml).
4. Manual checklist against `bsl-anti-patterns` skill (registers, virtual tables, batching).
5. Apply rewrites.
6. Diagnostics: `bsl-language-server`.
7. `rlm_end`.

### Metadata work

- For inspection only - use `rlm-tools-bsl` tools from this file.
- For creation, compilation, validation - route through the metadata domain map in `.claude/1c-metadata-manage.md` and pick the concrete skill from the dispatch table in `.claude/skills_instructions.md`. Direct file mutations outside these skills are not supported.

---

## Rules

1. Do not use `Grep` / `find` / custom parsers on BSL code when `rlm-tools-bsl` is available.
2. Every `rlm_start` must be balanced by an `rlm_end`.
3. After writing or modifying BSL code, a `bsl-language-server` diagnostics pass is required (plugin in-session, or `bsl-language-server.exe --analyze` from the CLI).
4. Look up any unfamiliar platform function in `1c-syntax` **before** using it in code.
5. Iteration cap on LSP style warnings - three passes, then move on.
6. Pre-index large configurations with `rlm_index` ahead of work.
7. Skills (see `skills_instructions.md`) mutate the configuration; MCP tools in this file only inspect it.
