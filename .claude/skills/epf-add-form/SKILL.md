---
name: epf-add-form
description: Добавить управляемую форму к внешней обработке 1С
argument-hint: <ProcessorName> <FormName> [Synonym]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# /epf-add-form — Добавление формы

Создает управляемую форму и регистрирует ее в корневом XML обработки.

## Usage

```
/epf-add-form <ProcessorName> <FormName> [Synonym] [--main]
```

| Параметр            | Обязательный | По умолчанию | Описание                                  |
|---------------------|:------------:|--------------|-------------------------------------------|
| ProcessorName       | *            | —            | Имя обработки (должна существовать)       |
| ProcessorNameB64    | *            | —            | Base64(UTF-8) от имени обработки; альтернатива при кириллице |
| FormName            | *            | —            | Имя формы                                 |
| FormNameB64         | *            | —            | Base64(UTF-8) от имени формы; альтернатива при кириллице |
| Synonym             | нет          | = FormName   | Синоним формы                             |
| SynonymB64          | нет          | —            | Base64(UTF-8) от синонима                 |
| --main              | нет          | авто         | Установить как форму по умолчанию (автоматически для первой формы) |
| SrcDir              | нет          | `src`        | Каталог исходников                        |

> `*` - обязательно одно из пары (`-ProcessorName` ИЛИ `-ProcessorNameB64`; `-FormName` ИЛИ `-FormNameB64`).

## Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/epf-add-form/scripts/add-form.ps1 -ProcessorName "<ProcessorName>" -FormName "<FormName>" [-Synonym "<Synonym>"] [-Main] [-SrcDir "<SrcDir>"]
```

> Кириллица в именах обработки/формы при вызове через `powershell.exe -NoProfile -File ...` ломается из-за cp866 дочернего процесса. Обход - передавать значения через `*B64`-параметры:
>
> ```powershell
> $procB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('МояОбработка'))
> $formB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('ОсновнаяФорма'))
> powershell.exe -NoProfile -File .claude/skills/epf-add-form/scripts/add-form.ps1 -ProcessorNameB64 $procB64 -FormNameB64 $formB64 -Main
> ```

## Что создается

```
<SrcDir>/<ProcessorName>/Forms/
├── <FormName>.xml                    # Метаданные формы (1 UUID)
└── <FormName>/
    └── Ext/
        ├── Form.xml                  # Описание формы (logform namespace)
        └── Form/
            └── Module.bsl           # BSL-модуль с 4 регионами
```

## Что модифицируется

- `<SrcDir>/<ProcessorName>.xml` — добавляется `<Form>` в `ChildObjects`, обновляется `DefaultForm` (автоматически если это первая форма, или явно при `--main`)

## Детали

- FormType: Managed
- UsePurposes: PlatformApplication, MobilePlatformApplication
- AutoCommandBar с id=-1
- Реквизит "Объект" с MainAttribute=true
- BSL-модуль содержит 5 регионов: ОбработчикиСобытийФормы, ОбработчикиСобытийЭлементовФормы, ОбработчикиКомандФормы, ОбработчикиОповещений, СлужебныеПроцедурыИФункции