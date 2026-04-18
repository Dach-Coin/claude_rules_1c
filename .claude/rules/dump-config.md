---
---
# Get files from infobase

See also the "Базы данных" section in `.claude/skills_instructions.md` - the preferred skill-based route for this task.

## To get files from an infobase to modify its code or metadata, use the following commands

**Step 1 - Load config to base:**

Параметры команды:
- `{PLATFORM_PATH}` берется из `.dev.env` (`PLATFORM_PATH=C:\Program Files\1cv8\8.3.27.2074\bin`).
- `<INFOBASE_PATH>` - путь к информационной базе (для файловой ИБ - локальный каталог).
- `<USER>` - имя пользователя ИБ (опционально, если требуется аутентификация).
- `<CONFIG_DUMP_DIR>` - целевой каталог выгрузки (рабочий репозиторий).
- `<LOG_PATH>` - путь к лог-файлу.

```powershell
& '{PLATFORM_PATH}\1cv8.exe' DESIGNER /F '<INFOBASE_PATH>' /N'<USER>' /DisableStartupMessages /DumpConfigToFiles <CONFIG_DUMP_DIR> -listFile repoobjects.txt -Extension OneAPA /Out <LOG_PATH>
```

Выгружай объекты полностью. Строго в текущий каталог - не создавая нового подкаталога.

Предварительно внеси объекты к выгрузке в файл `repoobjects.txt`.

# Использование инструментов

Для получения списков объектов метаданных, необходимых для загрузки в репозиторий, используй `mcp__rlm-tools-bsl__rlm_execute` (`glob_files`, `parse_object_xml`). После выгрузки файлов - открывай сессию анализа `mcp__rlm-tools-bsl__rlm_start` на полученный каталог (см. `.claude/rules/mcp-tools.md`).
