---
---

# Repository Typography

Two characters are banned across the whole repository - in `.bsl`, `.md`, `.ps1`, `.json`, anywhere.

## Typographic dashes (em-dash U+2014 and en-dash U+2013)

Use the plain ASCII hyphen-minus (`-`) only.

| Where | Why it matters |
|---|---|
| `.bsl` | BSL Language Server reports U+2014 (em-dash) and U+2013 (en-dash) as `InvalidCharacterInFile` (error). |
| `.ps1` | Encoding drift under Windows PowerShell - the same file rendered through cp1251 and utf-8 produces different bytes for U+2014, breaks diffs and signatures. |
| `.md` | Consistency. Markdown renderers handle `-` identically; em-dashes only add visual noise and a class of git-diff false positives. |

## Yo (U+0451 / U+0401)

The Cyrillic letters at code points `U+0451` (lowercase, HTML entity `&#1105;`) and `U+0401` (uppercase, HTML entity `&#1025;`) must not appear in any repository file. Use the regular `е` / `Е` (`U+0435` / `U+0415`) instead.

Why this matters in 1C specifically:

- The platform itself does not use these two code points in metadata - identifiers, synonyms and reserved keywords are stored with `U+0435` / `U+0415`. Writing `Отчет` and `Отчет` as if they were equivalent is a copy-paste trap; to the XDTO schema they are two different strings.
- The characters have a long history of encoding drift - some sources store them as a separate code point, some normalise, some strip them on conversion. Keeping them out of the repo removes the ambiguity entirely.
- This is a repo-hygiene rule, not a linguistic claim about the Russian language.

Runtime compatibility: skills that look up Russian type names in internal synonym dictionaries (`meta-compile`, `meta-edit`, `subsystem-compile`, `subsystem-edit`, `interface-edit`, `cfe-borrow`, `role-compile`, `web-test`) normalize `U+0451` / `U+0401` to `U+0435` / `U+0415` on the input side via a `Normalize-Yo` helper (PowerShell) or a `_YoNormDict` wrapper (Python). Legacy JSON or CLI input that still spells the key with `U+0451` keeps working; the dictionaries themselves are stored only in the sanitised form.

## Enforcement

Mechanical scan before commit (note: patterns below are Unicode-escaped to avoid embedding the forbidden characters in this document):

```powershell
# em-dash / en-dash
Select-String -Pattern "[\u2014\u2013]" -Path .\**\* -Recurse

# U+0451 / U+0401
Select-String -Pattern "[\u0451\u0401]" -Path .\**\* -Recurse
```

This file does not write the forbidden glyphs even once - the rule is also applied to itself. The forbidden characters are referred to only by code point (`U+2014`, `U+2013`, `U+0451`, `U+0401`) or HTML entity (`&#1105;`, `&#1025;`), never by writing the glyph.
