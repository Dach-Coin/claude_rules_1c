---
name: subsystem-compile
description: Создать подсистему 1С — XML-исходники из JSON-определения. Используй когда пользователь просит добавить подсистему (раздел) в конфигурацию
argument-hint: "[(-DefinitionFile | -DefinitionFileB64) <json-path/base64> | (-Value | -ValueB64) <json/base64>] (-OutputDir | -OutputDirB64) <path/base64> [(-Parent | -ParentB64) <path/base64>]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
---

# /subsystem-compile — генерация подсистемы из JSON

Принимает JSON-определение подсистемы → генерирует XML + файловую структуру + регистрирует в родителе (Configuration.xml или родительская подсистема).

## Параметры и команда

| Параметр | Описание |
|----------|----------|
| `DefinitionFile` | Путь к JSON-файлу определения |
| `Value` | Инлайн JSON-строка (альтернатива DefinitionFile) |
| `ValueB64` | Base64(UTF-8) от JSON-строки; используй вместо `-Value`, если запуск идет через дочерний `powershell.exe -File` и в JSON есть кириллица |
| `DefinitionFileB64` | Base64(UTF-8) от пути к файлу определения; аналог для `-DefinitionFile` при кириллице в пути |
| `OutputDir` | Корень выгрузки (где `Subsystems/`, `Configuration.xml`) |
| `OutputDirB64` | Base64(UTF-8) от `OutputDir`; используй при кириллице в пути |
| `Parent` | Путь к XML родительской подсистемы (для вложенных) |
| `ParentB64` | Base64(UTF-8) от `Parent`; используй при кириллице в пути родителя |
| `NoValidate` | Пропустить авто-валидацию (иначе авто-запускается `subsystem-validate`) |

```powershell
powershell.exe -NoProfile -File '.claude/skills/subsystem-compile/scripts/subsystem-compile.ps1' -Value '<json>' -OutputDir '<ConfigDir>'
```

> Windows PowerShell при вызове `powershell.exe -NoProfile -File ...` маршаллит аргументы через cp866, поэтому кириллица в `-Value`/`-OutputDir`/`-Parent`/`-DefinitionFile` может поломаться. Базовое правило для агента:
>
> - Если значения и все пути на латинице - используй plain-параметры (пример выше).
> - Если в значении/пути есть кириллица - переводи его на `*B64`-вариант; текстовый и B64-параметр взаимоисключающие.
> - Авто-валидация уже внутри скрипта передает путь в `subsystem-validate` через `-SubsystemPathB64` - дополнительных действий не требуется.
>
> ```powershell
> $valB64    = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"name":"Дочерняя"}'))
> $outB64    = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('src/Отдел продаж'))
> $parentB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('src/Отдел продаж/Subsystems/Продажи.xml'))
> powershell.exe -NoProfile -File '.claude/skills/subsystem-compile/scripts/subsystem-compile.ps1' `
>     -ValueB64 $valB64 -OutputDirB64 $outB64 -ParentB64 $parentB64
> ```

## JSON-определение

```json
{
  "name": "МояПодсистема",
  "synonym": "Моя подсистема",
  "comment": "",
  "includeInCommandInterface": true,
  "useOneCommand": false,
  "explanation": "Описание раздела",
  "picture": "CommonPicture.МояКартинка",
  "content": ["Catalog.Товары", "Document.Заказ"]
}
```

Минимально: только `name`. Остальное — дефолты.

## Примеры

```powershell
# Минимальная подсистема
... -Value '{"name":"Тест"}' -OutputDir config/

# С составом и картинкой
... -Value '{"name":"Продажи","content":["Catalog.Товары","Report.Продажи"],"picture":"CommonPicture.Продажи"}' -OutputDir config/

# Вложенная подсистема
... -Value '{"name":"Дочерняя"}' -OutputDir config/ -Parent config/Subsystems/Продажи.xml
```

