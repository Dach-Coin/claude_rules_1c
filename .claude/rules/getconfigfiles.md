---
---
# Get files from infobase

See also the `getconfigfiles` skill (`.claude/skills_instructions.md`) — it's the preferred user-invocable dispatcher for this task.

## To get files from an infobase to modify its code or metadata, use the following commands

**Step 1 - Load config to base:**

```powershell
& 'C:\Program Files\1cv8\8.3.23.1997\bin\1cv8.exe' DESIGNER /F 'C:\Users\filippov.o\Documents\1C\DemoHRMCorp1' /N'Савинская З.Ю. (Системный программист)' /DisableStartupMessages /DumpConfigToFiles E:\AgenticTest -listFile repoobjects.txt -Extension OneAPA /Out E:\Temp\Update.log
```

Выгружай объекты полностью. Строго в текущий каталог — не создавая нового подкаталога.

Предварительно внеси объекты к выгрузке в файл `repoobjects.txt`.

# Использование инструментов

Для получения списков объектов метаданных, необходимых для загрузки в репозиторий, используй `mcp__rlm-tools-bsl__rlm_execute` (`glob_files`, `parse_object_xml`). После выгрузки файлов — открывай сессию анализа `mcp__rlm-tools-bsl__rlm_start` на полученный каталог (см. `.claude/rules/mcp-tools.md`).
