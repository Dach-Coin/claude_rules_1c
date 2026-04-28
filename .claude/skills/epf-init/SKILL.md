---
name: epf-init
description: Создать пустую внешнюю обработку 1С (scaffold XML-исходников)
argument-hint: <Name> [Synonym]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# /epf-init - Создание новой обработки

Генерирует минимальный набор XML-исходников для внешней обработки 1С: корневой файл метаданных и каталог обработки.

## Usage

```
/epf-init <Name> [Synonym] [SrcDir]
```

| Параметр    | Обязательный | По умолчанию | Описание                            |
|-------------|:------------:|--------------|-------------------------------------|
| Name        | *            | -            | Имя обработки (латиница/кириллица)  |
| NameB64     | *            | -            | Base64(UTF-8) от имени; альтернатива `-Name` при запуске через дочерний `powershell.exe -File` с кириллицей в имени |
| Synonym     | нет          | = Name       | Синоним (отображаемое имя)          |
| SynonymB64  | нет          | -            | Base64(UTF-8) от синонима; альтернатива `-Synonym` при кириллице |
| SrcDir      | нет          | `src`        | Каталог исходников относительно CWD |

> `*` - обязательно одно из `-Name` или `-NameB64`.

## Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/epf-init/scripts/init.ps1 -Name "<Name>" [-Synonym "<Synonym>"] [-SrcDir "<SrcDir>"]
```

> Кириллица в `-Name`/`-Synonym` при вызове через `powershell.exe -NoProfile -File ...` ломается из-за cp866 дочернего процесса. Обход - закодировать значения в base64 (UTF-8) и передать через `-NameB64`/`-SynonymB64`:
>
> ```powershell
> $nameB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('МояОбработка'))
> $synB64  = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('Моя обработка'))
> powershell.exe -NoProfile -File .claude/skills/epf-init/scripts/init.ps1 -NameB64 $nameB64 -SynonymB64 $synB64
> ```

## Дальнейшие шаги

- Добавить форму: `/epf-add-form`
- Добавить макет: `/template-add`
- Добавить справку: `/help-add`
- Собрать EPF: `/epf-build`
