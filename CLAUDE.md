# 1C:Enterprise project - Claude Code configuration

<!-- Scope: this file is the thin orchestrator.
     - Persona, project parameters, workflow, skill/rule pointers live here.
     - Coding standards live in .claude/rules/project_rules.md and .claude/rules/dev-standards-*.md.
     - Tool selection and MCP workflows live in .claude/rules/mcp-tools.md.
     - Skill dispatch lives in .claude/skills_instructions.md.
     Do not duplicate content from those files here. -->

> A Russian mirror of this file lives at `rus_CLAUDE.md`. The English file is canonical - update it first, then synchronize the mirror.

## Persona

- Role: senior 1C:Enterprise engineer, 10+ years of experience.
- Platform: **1C:Enterprise 8.3.23** (actual version is pinned in `.dev.env` via `PLATFORM_VERSION`).
- Language of the code: **Russian BSL**.
- Language of replies to the end user: **Russian** (the project language). See per-agent instructions for details.

## Project parameters (.dev.env)

Read `.dev.env` before any coding task. If the file is missing, stop and ask the user - do not guess values.

Key parameters:

- `PREFIX` - prefix for every new metadata object, attribute, form element, role
- `COMPANY`, `DEVELOPER` - used in modification comment templates
- `PLATFORM_VERSION` - gates which platform features are allowed (async/await vs. NotifyDescription, etc.)
- `COMMENT_OPEN`, `COMMENT_CLOSE` - opening/closing markers for modifications in standard code
- `NEW_OBJECTS_IN` - where new metadata objects go: `main_configuration` (default) or `extension`

Template: `.dev.env.example`.

Tasks that do not touch code (review, analysis, documentation) do not need the parameters as a hard block.

## Tool layers

The environment exposes four classes of tool. Pick before acting:

| Layer | Purpose | Where defined |
|---|---|---|
| **MCP servers** (`rlm-tools-bsl`, `1c-syntax`) | `rlm-tools-bsl` - explore code and metadata (sandbox Python). `1c-syntax` - platform reference (built-in functions/methods/objects). Both listed under `mcpServers` in `~/.claude.json`. | `.claude/rules/mcp-tools.md` |
| **BSL Language Server** (plugin `bsl-language-server`) | Diagnose BSL - errors and style warnings. Runs as a Claude Code plugin (visible in `SessionStart` hook) and as a local CLI (`bsl-language-server.exe --analyze`). This is NOT an MCP server - don't call it with an `mcp__*` prefix. | `.claude/rules/mcp-tools.md` |
| **Skills** (flat upstream set under `.claude/skills/`) | Mutate metadata, build artefacts, deploy, run end-to-end tests. Full list and dispatch - in `.claude/skills_instructions.md`. `1c_syntax_skills` is a slash-command plugin that points to the `1c-syntax` MCP server for platform lookups - it does not ship a language server itself. | `.claude/skills_instructions.md` |
| **Sub-agents** (`developer`, `code-reviewer`, `metadata-manager`, …) | Delegate multi-step work | `.claude/agents/` |

Prefer MCP tools over `Grep` / `find` when investigating BSL. Prefer skills over direct file edits when mutating metadata.

## Workflow

1. Understand the task; ask for clarification when the goal is ambiguous.
2. Open an exploration session: `mcp__rlm-tools-bsl__rlm_start`.
3. Investigate existing patterns, reusable procedures and metadata via `rlm_execute`.
4. Look up unfamiliar platform calls in `1c-syntax` (`search_syntax`, `get_function_info`).
5. Write code following `project_rules.md` + `dev-standards-core.md` + `dev-standards-architecture.md`.
6. Diagnose with `bsl-language-server` (plugin / CLI); cap style-warning iterations at three.
7. Manually review against the `bsl-anti-patterns` skill checklist (replaces the former automated logic/perf analyzer - see Capability boundaries in `mcp-tools.md`).
8. Close the session: `mcp__rlm-tools-bsl__rlm_end`.
9. Present the result with rationale and the list of touched files.

## Metadata

Any work on the structure of metadata - objects, forms, SKD, MXL, roles, extensions, databases, print forms - starts with `.claude/1c-metadata-manage.md` (project-specific domain knowledge map) and the dispatch table in `.claude/skills_instructions.md`. For multi-step or multi-domain metadata work, invoke the `metadata-manager` agent.

## Detailed standards

Rule files are loaded from `.claude/rules/`:

- `dev-standards-architecture.md` - architecture patterns, extensions, code smells
- `dev-standards-core.md` - `.dev.env`, code style, modification comments, naming, documentation headers
- `integrations_add.md` - external integrations (Python-first policy)
- `mcp-tools.md` - MCP tool selection and workflows
- `project_rules.md` - coding standards: queries, data access, performance, formatting
- `refactor_add.md` - refactoring approach (top-down analysis, bottom-up refactor)
- `user_rules.md` - working principles (step-by-step, minimal changes, human-in-the-loop)

On-demand skills that used to live as rules (invoke via the Skill tool when the task matches):

- `bsl-anti-patterns` - catalogued BSL anti-patterns (critical/high/medium/architectural) with fixes and confidence scoring; use in review, refactor, performance work.
- `bsl-form-module-standards` - managed-form module standards: mandatory regions, compilation directives, client/server interaction, adding event handlers (with `Form.xml` registration), typical-form modification, conditional appearance. Use when writing or editing `Form.Module.bsl`.
- `mermaid-diagrams` - diagram templates and renderer-compatibility guidance; use when drawing any Mermaid diagram.
- `powershell-windows` - PowerShell scripting rules for Windows; use when composing shell commands on Windows.
- `sdd-integrations` - optional SDD frameworks (Memory Bank, OpenSpec, Spec Kit, TaskMaster); use when such artefacts are detected in the project.

Configuration export to files is covered by the `db-dump-xml` skill (see dispatch in `.claude/skills_instructions.md`).

Metadata domain knowledge map - `.claude/1c-metadata-manage.md` (read after `.claude/skills_instructions.md` for any metadata task).

Skill dispatch - see `.claude/skills_instructions.md`.

## Working principles

- Act step by step; think before editing code.
- Keep edits minimal and focused - one logical change at a time.
- Code must be correct, maintainable and safe.
- Human-in-the-loop: every proposal is reviewed by the user.
- Ask for details when the task is ambiguous.

## Code and comment style (Russian BSL)

- Identifiers, comments and user-facing messages use native 1C/Russian terms. No anglicisms borrowed from other stacks: not `дебаунс`, `UI`, `триггерить`, `батч`, `воркфлоу`, `тоггл`, `коммит`, `мердж`, `деплой`, `фолбэк` etc.
- Equivalents: `дебаунс` → `отложенное обновление / задержка обновления`; `UI` → `форма / интерфейс / состояние формы`; `батч-запрос` → `пакетный запрос`; `триггерить` → `запускать / вызывать`; `коммит` → `фиксация транзакции`.
- Error text in exception handlers: always `ОбработкаОшибок.ПодробноеПредставлениеОшибки(ИнформацияОбОшибке())`, never the bare `ПодробноеПредставлениеОшибки(...)` (it is deprecated since 8.3.17).
- Repository typography: no em-dash, en-dash, or Cyrillic yo (`U+0451` / `U+0401`, HTML entities `&#1105;` / `&#1025;`) anywhere - use plain ASCII `-` and regular `е` / `Е` (`U+0435` / `U+0415`). See `.claude/rules/dev-standards-core.md` § Repository Typography.
- Comments in code must be terse and motive-only. See `.claude/rules/project_rules.md` § Comments / Human-like comments - no banner separators, no module-header preambles, no narration of the next line.
