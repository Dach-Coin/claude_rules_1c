# Skills Instructions

<!-- Scope: this file documents how to choose and dispatch to local skills under .claude/skills/.
     MCP tool selection lives in .claude/rules/mcp-tools.md. Coding standards live in .claude/rules/project_rules.md. -->

## Scope

- How to pick a local skill and when to invoke it.
- Not a duplicate of `SKILL.md` files - only a dispatch brief.
- Covers only skills that physically exist under `.claude/skills/`. Global Claude Code plugins (e.g. `1c_syntax_skills` from the platform help plugin) are listed by Claude Code itself and are not covered here.

## MCP tools vs. skills

Decide which layer applies **before** reaching for either:

| Layer | What it does | Examples |
|---|---|---|
| **MCP servers** (`rlm-tools-bsl`, `1c-syntax`) | Read-only inspection of the configuration and the platform reference | Search for code patterns, reference a built-in function |
| **BSL Language Server** (plugin `bsl-language-server`, NOT an MCP) | Diagnostics for `.bsl` / `.os` (errors, style warnings); plugin in-session or local CLI `bsl-language-server.exe --analyze`. Never call with `mcp__*` prefix. | Diagnose a module after writing |
| **Skills** (this file) | Actions that mutate the project - create metadata, compile, deploy, export | Create a managed form, compile a role, deploy a configuration to a test infobase |

Full guidance is in `.claude/rules/mcp-tools.md`.

## Available skills

### 1c-metadata-manage

Create, edit, validate and remove configuration objects - catalogs, documents, registers, enums, managed forms, DCS/SKD, MXL layouts, roles, EPF/ERF, extensions (CFE), configurations (CF), databases, subsystems, command interface, templates.

**When to use**

- Any structural mutation of metadata (new object, new attribute, change of form layout, role DSL, MXL cell edits, scaffold of an extension or configuration)
- Compilation of artefacts that require 1C Designer (roles, forms, configurations)
- Validation of a metadata object against its schema

**Pair with**

- After mutations - a `bsl-language-server` diagnostics pass on touched modules
- After structural changes - an `rlm_execute` grep from `rlm-tools-bsl` to confirm references are consistent
- The skill ships its own `docs/` (per-domain guides) and `tools/` (references for internal helpers); do not duplicate them here

### deploy-and-test

Deploy a configuration to a test infobase and run UI tests against it through the web client (browser automation).

**When to use**

- After a change that needs end-to-end verification in the running app
- When `bsl-language-server` diagnostics cannot catch the problem (runtime behaviour, UI flows)

### getconfigfiles

Export configuration objects from an infobase into the file system (`DumpConfigToFiles` via `1cv8.exe`) so that the code and metadata can be analysed.

**When to use**

- Before investigating a configuration that is only available as an infobase
- Before running `rlm-tools-bsl` against a project that is not yet on disk

**Pair with**

- After the export, open an `rlm_start` session against the exported folder

### img-grid-analysis

Overlay a numbered grid on an image to recover column proportions. Used when reconstructing an MXL layout from a screenshot or a scanned print form.

### mermaid-diagrams

Renderer-compatible templates and guidance for diagrams in design docs, architectural proposals and user documentation.

### powershell-windows

Rules for PowerShell commands on Windows - shell, Docker, HTTP calls. Consult when emitting shell commands that must run on a Windows host (the project runs on Windows Server).

## bsl-language-server (not a skill, but mandatory)

An LSP integration over `BSL Language Server`. Not listed above because it is a platform-level plugin, not a `.claude/skills/` entry. Usage is mandatory for any BSL edit:

- Run diagnostics after writing or modifying BSL - errors must be fixed
- Use `go-to-definition`, `find-references` during review
- Use `rename` for refactoring instead of search-and-replace

Full description - in `.claude/rules/mcp-tools.md` (section "bsl-language-server").

## Invocation

Skills are invoked through the Skill tool by their exact name as listed by the current environment (e.g. `1c-metadata-manage`, `deploy-and-test`, `getconfigfiles`). `deploy-and-test` and `getconfigfiles` can also be called as slash commands (`/deploy-and-test`, `/getconfigfiles`).

## Dispatch rules

1. Any mutation of metadata - go through the `1c-metadata-manage` skill, not through direct file edits.
2. Exporting a configuration for analysis - through the `getconfigfiles` skill.
3. End-to-end UI verification - through the `deploy-and-test` skill.
4. Do not reimplement what a skill already covers; extend the skill if needed.
