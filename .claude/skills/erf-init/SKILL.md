---
name: erf-init
description: Создать пустой внешний отчет 1С (scaffold XML-исходников)
argument-hint: <Name> [Synonym] [--with-skd]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# /erf-init - Создание нового отчета

Генерирует минимальный набор XML-исходников для внешнего отчета 1С: корневой файл метаданных и каталог отчета.

## Usage

```
/erf-init <Name> [Synonym] [SrcDir] [--with-skd]
```

| Параметр    | Обязательный | По умолчанию | Описание                              |
|-------------|:------------:|--------------|---------------------------------------|
| Name        | *            | -            | Имя отчета (латиница/кириллица)       |
| NameB64     | *            | -            | Base64(UTF-8) от имени; альтернатива `-Name` при запуске через дочерний `powershell.exe -File` с кириллицей |
| Synonym     | нет          | = Name       | Синоним (отображаемое имя)            |
| SynonymB64  | нет          | -            | Base64(UTF-8) от синонима             |
| SrcDir      | нет          | `src`        | Каталог исходников относительно CWD   |
| --WithSKD   | нет          | -            | Создать пустую СКД и привязать к MainDataCompositionSchema |

> `*` - обязательно одно из `-Name` или `-NameB64`.

## Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/erf-init/scripts/init.ps1 -Name "<Name>" [-Synonym "<Synonym>"] [-SrcDir "<SrcDir>"] [-WithSKD]
```

> Кириллица в `-Name`/`-Synonym` при вызове через `powershell.exe -NoProfile -File ...` ломается из-за cp866 дочернего процесса. Обход - base64:
>
> ```powershell
> $nameB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('МойОтчет'))
> $synB64  = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('Мой отчет'))
> powershell.exe -NoProfile -File .claude/skills/erf-init/scripts/init.ps1 -NameB64 $nameB64 -SynonymB64 $synB64 -WithSKD
> ```

## Дальнейшие шаги

- Добавить форму: `/form-add`
- Добавить макет: `/template-add`
- Добавить справку: `/help-add`
- Собрать ERF: `/erf-build`
