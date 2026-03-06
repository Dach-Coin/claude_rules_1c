---
paths: ["**/Form.Module.bsl"]
---

# **IMPORTANT!** - don't forget to add event hook to form xml file.
File is usually named `Form.xml` in the parent directory of the module code.

Event hooks in XML look like:

```xml
<Events>
	<Event name="OnOpen">ПриОткрытии</Event>
	<Event name="BeforeWrite">ПередЗаписью</Event>
	<Event name="OnCreateAtServer">ПриСозданииНаСервере</Event>
</Events>
```

Common form events:
| XML Event Name | Russian Handler Name | Description |
|----------------|---------------------|-------------|
| `OnOpen` | ПриОткрытии | Client, when form opens |
| `OnClose` | ПриЗакрытии | Client, when form closes |
| `BeforeWrite` | ПередЗаписью | Client, before write |
| `AfterWrite` | ПослеЗаписи | Client, after write |
| `OnCreateAtServer` | ПриСозданииНаСервере | Server, form creation |
| `BeforeWriteAtServer` | ПередЗаписьюНаСервере | Server, before write |
| `AfterWriteAtServer` | ПослеЗаписиНаСервере | Server, after write |
| `OnReadAtServer` | ПриЧтенииНаСервере | Server, when reading object |

The value inside `<Event>` tag is the name of the handler procedure in the form module.
