---
name: deploy-and-test
description: "Deploy configuration to test infobase and run tests via web client"
user-invocable: true
---

# installation
**IMPORTANT** if file infobasesettings.md does not exists - create it with following info:
1) Ask connection for infobase (file path or server connection string).
2) Ask infobase publish URL (for example `http://localhost/TestForms/ru/`).


# settings usage

Параметры команд:
- `{PLATFORM_PATH}` - из `.dev.env` (`PLATFORM_PATH=C:\Program Files\1cv8\8.3.27.2074\bin`).
- `<INFOBASE_PATH>` - путь к ИБ из `infobasesettings.md`. Использовать `/S` для серверной ИБ, `/F` для файловой.
- `<PROJECT_ROOT>` - корневой каталог текущего проекта (исходники конфигурации).
- `<LOG_PATH>` - путь к лог-файлу.
- URL публикации - из `infobasesettings.md`. Если URL не задан, тестирование пропускается.


# testing and deployment
## to update infobase before testing use following commands:
**Step 1 - Load config to base:**

```powershell
& '{PLATFORM_PATH}\1cv8.exe' DESIGNER /F '<INFOBASE_PATH>' /DisableStartupMessages /LoadConfigFromFiles <PROJECT_ROOT> /Out <LOG_PATH>
```

Read `<LOG_PATH>` to confirm success.

Wait 5-10 seconds

**Step 2 - Update database structure:**

```powershell
& '{PLATFORM_PATH}\1cv8.exe' DESIGNER /F '<INFOBASE_PATH>' /DisableStartupMessages /UpdateDBCfg -Dynamic+ -SessionTerminate force /Out <LOG_PATH>
```

Read `<LOG_PATH>` to confirm success.

## to test infobase use following URL and rules:

URL берется из `infobasesettings.md` (например, `http://localhost/TestForms/ru/`).

**IMPORTANT** ALWAYS USE **human-like typing** simulation with **DELAY** to fill values during testing
you can use TAB to select form field
