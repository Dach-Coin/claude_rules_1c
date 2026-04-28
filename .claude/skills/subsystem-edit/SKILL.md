---
name: subsystem-edit
description: Точечное редактирование подсистемы 1С. Используй когда нужно добавить или удалить объекты из подсистемы, управлять дочерними подсистемами или изменить свойства
argument-hint: "(-SubsystemPath | -SubsystemPathB64) <path/base64> [(-DefinitionFile | -DefinitionFileB64) <json-path/base64> | -Operation <op> [(-Value | -ValueB64) <value/base64>]]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
---

# /subsystem-edit - редактирование подсистемы 1С

Точечное редактирование XML подсистемы: состав, дочерние подсистемы, свойства.

## Параметры и команда

| Параметр | Описание |
|----------|----------|
| `SubsystemPath` | Путь к XML-файлу подсистемы |
| `SubsystemPathB64` | Base64(UTF-8) от пути; используй вместо `-SubsystemPath`, если запуск через дочерний `powershell.exe -File` и в пути есть кириллица |
| `DefinitionFile` | JSON-файл с массивом операций |
| `DefinitionFileB64` | Base64(UTF-8) от пути к JSON-файлу операций (при кириллице в пути) |
| `Operation` | Одна операция (альтернатива DefinitionFile) |
| `Value` | Значение для операции |
| `ValueB64` | Base64(UTF-8) от значения; используй вместо `-Value`, если запуск через дочерний `powershell.exe -File` и в значении есть кириллица |
| `NoValidate` | Пропустить авто-валидацию (иначе авто-запускается `subsystem-validate`) |

```powershell
powershell.exe -NoProfile -File '.claude/skills/subsystem-edit/scripts/subsystem-edit.ps1' -SubsystemPath '<path>' -Operation add-content -Value 'Catalog.Товары'
```

## Операции

| Операция | Значение | Описание |
|----------|----------|----------|
| `add-content` | `"Catalog.X"` или `["Catalog.X","Document.Y"]` | Добавить объекты в Content |
| `remove-content` | `"Catalog.X"` или `["Catalog.X"]` | Удалить объекты из Content |
| `add-child` | `"ИмяПодсистемы"` | Добавить дочернюю подсистему в ChildObjects |
| `remove-child` | `"ИмяПодсистемы"` | Удалить дочернюю подсистему |
| `set-property` | `{"name":"prop","value":"val"}` (JSON-строка для `-Value`; объект для `-DefinitionFile`) | Изменить свойство (Synonym, IncludeInCommandInterface, UseOneCommand, etc.) |

> Формат `set-property` в пакетном режиме: в `-DefinitionFile` допустимо как JSON-строка в `value`, так и вложенный объект (`"value": {"name":"...","value":"..."}`). Оба варианта работают идентично.
>
> Windows PowerShell при вызове `powershell.exe -NoProfile -File ...` маршаллит аргументы через cp866, поэтому кириллица в `-SubsystemPath`/`-Value`/`-DefinitionFile` может поломаться. Правило для агента:
>
> - Если в `SubsystemPath` и значении нет кириллицы - используй plain-параметры.
> - Если в пути к подсистеме есть кириллица - переводи его на `-SubsystemPathB64`. Если в значении/путях есть кириллица - используй `-ValueB64`/`-DefinitionFileB64`.
> - Авто-валидация уже внутри скрипта передает путь в `subsystem-validate` через `-SubsystemPathB64`.
>
> ```powershell
> $pathB64  = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('Subsystems/МояПодсистема.xml'))
> $valueB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"name":"IncludeInCommandInterface","value":"false"}'))
> powershell.exe -NoProfile -File '.claude/skills/subsystem-edit/scripts/subsystem-edit.ps1' `
>     -SubsystemPathB64 $pathB64 -Operation set-property -ValueB64 $valueB64
> ```

## Примеры

```powershell
# Добавить объект в состав
... -SubsystemPath Subsystems/Продажи.xml -Operation add-content -Value "Document.Заказ"

# Добавить несколько объектов
... -SubsystemPath Subsystems/Продажи.xml -Operation add-content -Value '["Catalog.Товары","Report.Продажи"]'

# Удалить объект из состава
... -SubsystemPath Subsystems/Продажи.xml -Operation remove-content -Value "Report.Старый"

# Добавить дочернюю подсистему
... -SubsystemPath Subsystems/Продажи.xml -Operation add-child -Value "НоваяДочерняя"

# Изменить свойство
... -SubsystemPath Subsystems/Продажи.xml -Operation set-property -Value '{"name":"IncludeInCommandInterface","value":"false"}'
```
