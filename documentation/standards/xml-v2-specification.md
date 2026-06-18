# XML Documentation Standard v2.0

## Purpose

Provide a standardized, queryable, and maintainable documentation format for SQL Server stored procedures.

The standard is designed to support:

- Procedure inventory
- Change tracking
- Documentation quality audits
- Ownership identification
- Historical reporting

Supported platforms:

- SQL Server 2012+
- SQL Server 2014+
- SQL Server 2016+
- SQL Server 2017+
- SQL Server 2019+
- SQL Server 2022+

---

# Root Element

```xml
<Documentation Version="2.0">
</Documentation>
```

Version is mandatory.

---

# Information Section

```xml
<Info>

    <Application />
    <Module />
    <Maintainer />
    <Description />
    <CreatedDate />

</Info>
```

## Application

Business application or system.

Examples:

```xml
<Application>Adventure Works App</Application>
```

Multiple applications may be specified using a comma-separated list.

Example:

```xml
<Application>Adventure Works App, Travel App</Application>
```

Required: Yes

---

## Module

Functional area or category.

Examples:

```xml
<Module>Accounting</Module>

<Module>Compliance</Module>

<Module>Reports</Module>
```

Required: Yes

---

## Maintainer

Current technical owner responsible for maintenance.

Example:

```xml
<Maintainer>snevarez</Maintainer>
```

Required: Yes

---

## Description

Business or technical description.

Required: Yes

---

## CreatedDate

Original creation date.

Required: No

Format:

YYYY-MM-DD

---

# Log Section

```xml
<Log>
    <Change />
</Log>
```

---

# Change Element

```xml
<Change
    Date=""
    Author=""
    Type=""
    Ticket="">
</Change>
```

## Date

Required: Yes

Format:

YYYY-MM-DD

---

## Author

Required: Yes

Person responsible for the change.

---

## Type

Required: Yes

Allowed values:

- US
- BUG
- HOTFIX
- PERF
- SEC
- REFACTOR
- DOC
- CONFIG

---

## Ticket

Required: No

Examples:

250756

BUG-259489

ADO-12541

---

## Change Description

Text contained inside the Change element.

Required: Yes

Example:

```xml
<Change
    Date="2025-10-03"
    Author="snevarez"
    Type="US"
    Ticket="250756">

    Added ReactivationAttempts

</Change>
```
