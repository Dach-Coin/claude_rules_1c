---
name: getconfigfiles
description: "Export configuration objects from infobase to file system"
user-invocable: true
---

# get files from infobase
## to get files from infobase to modify it's code or metadata please use following commands:
commands:

**Step 1 - Load config to base:**

Параметры команды:
- `{PLATFORM_PATH}` - из `.dev.env` (`PLATFORM_PATH=C:\Program Files\1cv8\8.3.27.2074\bin`).
- `<INFOBASE_PATH>` - путь к информационной базе.
- `<USER>` - имя пользователя ИБ (если требуется аутентификация).
- `<CONFIG_DUMP_DIR>` - целевой каталог выгрузки.
- `<LOG_PATH>` - путь к лог-файлу.

```powershell
& '{PLATFORM_PATH}\1cv8.exe' DESIGNER /F '<INFOBASE_PATH>' /N'<USER>' /DisableStartupMessages /DumpConfigToFiles <CONFIG_DUMP_DIR> -listFile repoobjects.txt -Extension OneAPA /Out <LOG_PATH>
```

Выгружай объекты полностью. Строго в текущий каталог - не создавая нового подкаталога.

Предварительно внеси объекты к выгрузке в файл repoobjects.txt

# Использование инструментов
Для получения списков объектов метаданных, необходимых для загрузки в репозиторий, используй `mcp__rlm-tools-bsl__rlm_execute` (`glob_files`, `parse_object_xml`).
