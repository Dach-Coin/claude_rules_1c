---
name: subsystem-validate
description: Валидация подсистемы 1С. Используй после создания или модификации подсистемы для проверки корректности
argument-hint: "(-SubsystemPath | -SubsystemPathB64) <path/base64> [-Detailed] [-MaxErrors 30] [-OutFile <path>]"
allowed-tools:
  - Bash
  - Read
  - Glob
---

# /subsystem-validate - валидация подсистемы 1С

Проверяет структурную корректность XML-файла подсистемы из выгрузки конфигурации.

## Параметры

| Параметр         | Обяз. | Умолч. | Описание                                  |
|------------------|:-----:|---------|--------------------------------------------|
| SubsystemPath    | *     | -       | Путь к XML-файлу подсистемы                |
| SubsystemPathB64 | *     | -       | Base64(UTF-8) пути; используй вместо `-SubsystemPath`, если запуск идет через дочерний `powershell.exe -File` и в пути есть кириллица |
| Detailed         | нет   | -       | Подробный вывод (все проверки, включая успешные) |
| MaxErrors        | нет   | 30      | Остановиться после N ошибок                |
| OutFile          | нет   | -       | Записать результат в файл                  |

> `*` - обязательно одно из `-SubsystemPath` или `-SubsystemPathB64`.

## Команда

```powershell
powershell.exe -NoProfile -File ".claude/skills/subsystem-validate/scripts/subsystem-validate.ps1" -SubsystemPath "Subsystems/Продажи"
powershell.exe -NoProfile -File ".claude/skills/subsystem-validate/scripts/subsystem-validate.ps1" -SubsystemPath "Subsystems/Продажи.xml"
```

> Если в пути к подсистеме есть кириллица и вызов идет из внешнего раннера через `powershell.exe -NoProfile -File ...`, используй `-SubsystemPathB64`:
>
> ```powershell
> $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('Subsystems/Продажи.xml'))
> powershell.exe -NoProfile -File .claude/skills/subsystem-validate/scripts/subsystem-validate.ps1 -SubsystemPathB64 $b64
> ```
