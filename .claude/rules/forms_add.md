---
---
# Use following instructions only if you need to generate or modify 1C form

> **Note**: These MCP tools provide design assistance (examples, schemas, instructions). For actual form compilation, editing, and validation - see the Формы section in `.claude/1c-metadata-manage.md` and pick the concrete skill from the dispatch table in `.claude/skills_instructions.md`.

## To generate new form:
   Step 1: use **'genterate_example_form'** tool to generate most relevant exemple of form you need. Provide full form description to tool to find and generate appropriate
   Step 2: use **'get_instructions'** tool to get instructions how to add form to configuration and generate form metadata
   Step 3: use **'get_xsd_schema'** tool, to get info about current form xsd schema
   Step 4: follow the Формы section in `.claude/1c-metadata-manage.md` to pick the right skill for compiling the form from JSON and validating the result.

## To modify existing form:
  - use **'get_xsd_schema'** and **'get_json_schema'** tools to clarify tags which you can use for form generation
  - use **'form_example_search'** if you need some examples for attributes and commands on form
  - use **'get_form_prompt'** if tools above are non enough
  - for the actual modification and validation, follow the Формы section in `.claude/1c-metadata-manage.md` and dispatch through `.claude/skills_instructions.md`.
