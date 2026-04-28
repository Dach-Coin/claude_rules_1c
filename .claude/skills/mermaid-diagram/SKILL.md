---
name: mermaid-diagram
description: Создание или починка диаграммы Mermaid с гарантией совместимости с консервативными рендерерами (VS Code preview, Git-платформы) плюс обязательный ASCII/Unicode-сайдкар. Использовать при упоминании flowchart, sequence, class, state, ER, journey, gantt, pie, quadrant, sankey, git graph, диаграмма, схема.
argument-hint: "[type]"
allowed-tools: ["Read", "Write", "Edit", "Bash"]
---

# mermaid-diagram

Скилл выдает валидный Mermaid-блок и парный ASCII/Unicode-сайдкар. Принцип: совместимость с минимальным набором рендереров (VS Code preview, GitHub/GitLab, embedded markdown viewers); экспериментальные типы (`quadrantChart`, `sankey-beta`, `requirementDiagram`, `gitGraph`) не используются - отдаются эквивалентные `graph`-фолбэки.

## Compatibility rules (read first)

- Использовать `graph LR` / `graph TB` для блок-схем; ключевое слово `flowchart` ломается в части старых рендереров.
- Лейблы со спецсимволами обязательно в кавычках: `A["Text (x|y)"]`.
- **Нельзя писать литеральный `\n` внутри лейблов** - Mermaid это не интерпретирует. Перенос строки - `<br/>`.
- Экспериментальные типы (`quadrantChart`, `sankey-beta`, `requirementDiagram`, `gitGraph`) могут быть недоступны - использовать готовые `graph`-фолбэки ниже.
- Code fence стартует с колонки 0, язык `mermaid`.

## ASCII/Unicode sidecar (обязательный)

Для удобства чтения в raw-Markdown и для агентов, которые не рендерят Mermaid, под каждым `mermaid`-блоком обязательно идет текстовый сайдкар.

Политика:

- MUST: monospace text-only диаграмма прямо под Mermaid-блоком, fenced code с языком `text`.
- MUST: Mermaid и сайдкар держим синхронными (одни и те же узлы/ребра/лейблы по возможности). При расхождении источник истины - Mermaid; обновить сайдкар.
- SHOULD: ширина <= 80 колонок (читаемость в diff и терминалах).
- SHOULD: ASCII-приоритет, Unicode box-drawing - только если окружение это поддерживает.
- MAY: однострочный заголовок над парой: `Diagram: <name> (<type>)`.

Примитивы для сайдкара:

- Боксы: `[Name]`, `(Name)`, `+-----+\n| N |\n+-----+`.
- Потоки: `-->`, решения как `{cond?}`, списки `-`.
- Sequence text: `Actor -> Actor: message` с отступами под lifeline.

Пример flowchart:

```mermaid
graph LR
  A["Start"] --> B{Auth?}
  B -->|Yes| C["Dashboard"]
  B -->|No|  D["Login"]
```

```text
Diagram: Auth flow (flowchart)
  [Start] --> {Auth?}
      {Auth?} -- Yes --> [Dashboard]
      {Auth?} -- No  --> [Login]
```

Пример sequence:

```mermaid
sequenceDiagram
  participant U as User
  participant W as WebApp
  U->>W: Open
  W-->>U: OK
```

```text
Diagram: Happy path (sequence)
  User -> WebApp : Open
  WebApp -> User : OK
```

## Working templates

### Flowchart

```mermaid
graph LR
  A["Start"] --> B{Auth?}
  B -->|Yes| C["Dashboard"]
  B -->|No|  D["Login"]
  C --> E["Settings"]
```

### Sequence

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant W as WebApp
  participant API
  U->>W: Open
  W->>API: GET /status
  API-->>W: 200
  W-->>U: OK
```

### Class

```mermaid
classDiagram
  class User {
    +String id
    +String name
    +login(): bool
  }
  class Order {
    +String id
    +Decimal total
    +submit()
  }
  User "1" o-- "*" Order
```

### State (v2)

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Loading : fetch
  Loading --> Ready : ok
  Loading --> Error : fail
  state Ready {
    [*] --> Viewing
    Viewing --> Editing : edit
    Editing --> Viewing : save
  }
  Error --> Idle : retry
```

### ER (Entity-Relationship)

```mermaid
erDiagram
  USER ||--o{ ORDER : places
  ORDER ||--|{ ORDER_LINE : contains
  PRODUCT ||--o{ ORDER_LINE : referenced
  USER {
    string id
    string email
  }
  PRODUCT {
    string id
    string name
    float price
  }
```

### Journey (user journey)

```mermaid
journey
  title Checkout UX
  section Browse
    "See product": 5: User
    "Add to cart": 4: User
  section Payment
    "Enter card": 2: User
    "3DS confirm": 2: User
  section Result
    "Success page": 5: User
```

### Gantt

```mermaid
gantt
  title Release Plan
  dateFormat  YYYY-MM-DD
  section Dev
  Spec  :done,   des1, 2025-10-01,2025-10-05
  Impl  :active, des2, 2025-10-06,2025-10-20
  Tests :        des3, 2025-10-21, 7d
  section Release
  Freeze :milestone, m1, 2025-10-28, 0d
  Deploy :crit,    des4, 2025-10-29, 1d
```

### Pie

```mermaid
pie
  title Traffic by Source
  "Direct"  : 35
  "Organic" : 45
  "Ads"     : 20
```

### Quadrant - flowchart fallback

```mermaid
graph TB
  Q1["Quick Wins<br/>High Impact - Low Effort<br/><br/>- Improve UX"]
  Q2["Major Projects<br/>High Impact - High Effort<br/><br/>- Rewrite Core"]
  Q3["Fill-ins<br/>Low Impact - Low Effort<br/><br/>- Docs polish"]
  Q4["Thankless<br/>Low Impact - High Effort<br/><br/>- Legacy migration"]

  Q1 --> Q2
  Q1 --> Q3
  Q2 --> Q4
  Q3 --> Q4
```

### Requirement - flowchart fallback

```mermaid
graph LR
  R1["Requirement: PCI-DSS compliant"]
  T1["Test: PCI checklist"]
  SVC["Service"]

  SVC -- satisfies --> R1
  T1  -- verifies  --> R1
```

### Sankey - flowchart fallback (веса на ребрах)

```mermaid
graph LR
  Checkout["Checkout"] -->|100| PSP["PSP"]
  PSP -->|60|  Settled["Settled"]
  PSP -->|40|  Declined["Declined"]
```

### Git graph - flowchart fallback (простой DAG)

```mermaid
graph LR
  A["init"] --> B["feat-A"]
  A --> C["fix-1"]
  B --> D["merge"]
  C --> D
```

## When to use which diagram

- Flowchart: общие потоки, решения, движение данных в спеках и PRD.
- Sequence: взаимодействия во времени между акторами/сервисами (API, запросы, ответы).
- Class: доменные модели и статическая структура; полезно для атрибутов сущностей и их связей.
- State: жизненный цикл сущности/компонента (idle -> loading -> ready/error, вложенные состояния).
- ER: логическая или БД-модель с кардинальностями.
- Journey: пользовательский опыт по шагам/секциям (приемочные сценарии PRD).
- Gantt: расписание, релизы, зависимости по датам.
- Pie: простые композиции/доли; для точности предпочесть таблицу.
- Quadrant (fallback): матрица приоритизации (Impact/Effort) без поддержки экспериментального chart.
- Requirement (fallback): прослеживаемость требований, тестов и элементов системы.
- Sankey (fallback): относительные объемы вдоль маршрута, когда `sankey` недоступен.
- Git graph (fallback): мелкие DAG ветвлений/мерджей, когда `gitGraph` недоступен.

## Troubleshooting

Если диаграмма не рендерится:

1. Заменить `flowchart` на `graph`, упростить формы.
2. Обернуть тексты узлов в кавычки.
3. Проверить в `https://mermaid.live`, чтобы изолировать окружение.
4. Откатиться к шаблонам выше для максимальной совместимости.
