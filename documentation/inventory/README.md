# Stored Procedure Documentation & Change Tracking Toolkit

## Overview

A lightweight framework for documenting, auditing, and tracking changes in SQL Server stored procedures using structured comments embedded directly in source code.

The project focuses on transforming documentation from static comments into actionable metadata that can be queried, audited, and analyzed over time.

Compatibility target:

- SQL Server 2012+
- No CLR
- No external dependencies
- Production-friendly
- Read-only metadata extraction

---

## Problem

In many SQL Server environments, stored procedures contain valuable documentation, but that information is trapped inside comments and cannot be easily queried.

Common challenges include:

- Difficulty identifying procedure ownership
- Lack of visibility into historical changes
- No centralized inventory of documented procedures
- Limited documentation coverage metrics
- Manual effort required during audits and maintenance

---

## Solution

Extract metadata from structured comments embedded inside stored procedures.

Example XML v1 documentation:

```xml
<Author></Author>
<app>Adventure Works App</app>
<Description>Deposits in Transit - frmDepositInTransit</Description>

<ChangeLog>
    <log Date="2025-10-03" Author="snevarez">
        Added ReactivationAttempts(US 250756)
    </log>
</ChangeLog>
```

This metadata can be queried directly from:

```sql
sys.procedures
sys.sql_modules
```

without modifying existing procedures.

---

## Benefits

- Procedure inventory
- Documentation coverage analysis
- Application mapping
- Technical debt visibility
- Documentation quality auditing
- Foundation for change tracking
- Migration path toward structured XML documentation

---

## XML v1 Documentation Standard

The current version of the toolkit works with the existing documentation format already present in many stored procedures.

Recommended structure:

```xml
<Author></Author>
<app>Adventure Works App</app>

<Description>
    Deposits in Transit - frmDepositInTransit
</Description>

<USs>250756</USs>

<ChangeLog>
    <log Date="2024-03-01" Author="">
        Parameters the @OrderBy parameter was modified
    </log>

    <log Date="2025-10-03" Author="snevarez">
        Added ReactivationAttempts(US 250756)
    </log>
</ChangeLog>
```

### Mandatory Elements

- Author
- app
- Description
- ChangeLog

### Optional Elements

- USs
- Additional custom tags

---

## Inventory Scripts

Current scripts focus on inventory and documentation coverage.

### inventory-v1.sql

Provides:

- Schema name
- Procedure name
- Application
- Description
- Documentation detection
- Last modification date

### inventory-summary.sql

Provides:

- Total procedures
- Documented procedures
- Undocumented procedures
- Documentation coverage percentage

### undocumented-procedures.sql

Identifies:

- Procedures without documentation
- Candidates for documentation remediation

### procedures-by-application.sql

Provides:

- Procedure count by application
- High-level ownership mapping

---

## Metadata Mining Opportunities

Although XML v1 was originally designed for human-readable documentation, it can also be used as a source of metadata for auditing and change tracking purposes.

### Who modified what?

By extracting:

```xml
<log Date="2025-10-03" Author="snevarez">
```

it is possible to build a relationship between:

```text
Procedure
→ Change
→ Author
```

Example:

| Procedure          | Author      |
| ------------------ | ----------- |
| st_DepositReport   | snevarez    |
| st_WatchDenySearch | Jose Valdez |

---

### When was a procedure modified?

The Date attribute allows reconstruction of a historical timeline.

Example:

| Procedure        | Change Date |
| ---------------- | ----------- |
| st_DepositReport | 2024-03-01  |
| st_DepositReport | 2025-10-03  |

---

### How many documented changes does a procedure have?

Each `<log>` node can be counted.

Example:

| Procedure          | Changes |
| ------------------ | ------- |
| st_DepositReport   | 12      |
| st_WatchDenySearch | 7       |

This can help identify highly modified or potentially unstable procedures.

---

### Which procedures have the highest activity?

Aggregating ChangeLog entries allows ranking procedures by documented activity.

Example:

| Procedure           | Change Count |
| ------------------- | ------------ |
| st_WiresReport      | 42           |
| st_StatementSummary | 37           |

---

### Which developers appear most frequently?

Aggregating the Author attribute allows identification of contributors and ownership trends.

Example:

| Author        | Changes |
| ------------- | ------- |
| snevarez      | 84      |
| Jose Valdez   | 43      |
| Brenda Ortega | 29      |

---

## Limitations of XML v1

The current format stores important information inside free text.

Example:

```xml
<log Date="2025-10-03" Author="snevarez">
    Added ReactivationAttempts(US 250756)
</log>
```

From this entry we can reliably extract:

- Date
- Author
- Change description

However, we cannot reliably determine:

- Change type (US, BUG, HOTFIX, PERF, etc.)
- Ticket number
- Business impact

because those values are embedded in unstructured text.

---

## Future Improvements

### Documentation Parsing Function

Current version uses standalone scripts based on:

- CHARINDEX()
- SUBSTRING()

This approach was intentionally chosen to:

- Keep scripts self-contained
- Avoid dependencies
- Support SQL Server 2012+

Future versions may introduce:

```sql
dbo.ufn_GetDocumentationTag()
```

Benefits:

- Reusable parsing logic
- Simplified maintenance
- Reduced code duplication
- Easier migration to Documentation XML v2

---

## Design Decisions

### Why not use a scalar function?

The first release intentionally avoids custom functions.

Reasons:

- Zero deployment dependencies
- Easier adoption in production environments
- Compatibility with restricted permissions
- Simpler execution by DBAs and developers

Trade-off:

- Some parsing logic is duplicated across scripts

This trade-off was accepted in favor of portability.

---

## Roadmap

### Phase 1 - Inventory (Current)

- Procedure inventory
- Documentation coverage
- Application mapping
- Undocumented procedure detection

### Phase 2 - ChangeLog Analysis

- Change extraction from XML v1
- Author statistics
- Procedure activity metrics
- Change history reporting

### Phase 3 - XML v2

- Strict XML schema
- Structured change tracking
- Ticket classification
- Native XML parsing

### Phase 4 - Documentation Dashboard

- Technical debt metrics
- Change analytics
- Documentation quality reporting

---

## Future XML v2 Vision

Example:

```xml
<Documentation Version="2.0">

    <Metadata>
        <Author>snevarez</Author>
        <Application>Adventure Works App</Application>
        <Module>Accounting</Module>
        <Description>Deposits in Transit</Description>
    </Metadata>

    <ChangeLog>

        <Change
            Date="2025-10-03"
            Author="snevarez"
            Type="US"
            Ticket="250756">
            Added ReactivationAttempts
        </Change>

    </ChangeLog>

</Documentation>
```

XML v2 will enable:

- User Story tracking
- Bug tracking
- Change classification
- Documentation dashboards
- Native XML querying
- Improved auditing capabilities
