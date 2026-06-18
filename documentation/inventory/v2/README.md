# SQL Server Documentation Inventory (XML v2)

## Overview

XML v2 transforms stored procedure documentation from static comments into structured, queryable metadata.

The goal is to enable inventory, governance, change tracking, and documentation quality analysis directly from SQL Server using T-SQL only.

The toolkit is designed for:

- SQL Server 2012+
- Production environments
- Restricted permissions
- No CLR dependencies
- No permanent database objects

---

## Why XML v2?

Traditional documentation blocks provide useful information for developers, but they are difficult to query and validate consistently.

XML v2 introduces a structured format that allows:

- Documentation validation
- Inventory generation
- Change tracking
- Author activity analysis
- Change type analysis
- Documentation health metrics
- Executive reporting

---

## XML v1 vs XML v2

| Metrics / Indicators                     |   XML v1   | XML v2 |
| ---------------------------------------- | :--------: | :----: |
| Stored Procedure Documentation Inventory |     ✅     |   ✅   |
| Undocumented Procedures Detection        |     ✅     |   ✅   |
| Inventory Summary by Application         |     ❌     |   ✅   |
| Inventory Summary by Module              |     ❌     |   ✅   |
| Inventory Summary by Maintainer          |     ❌     |   ✅   |
| Documentation Coverage Metrics           |     ❌     |   ✅   |
| Structured Documentation Validation      |     ❌     |   ✅   |
| Documentation Version Control            |     ❌     |   ✅   |
| Change History Tracking                  | ⚠️ Partial |   ✅   |
| Change History by Author                 |     ❌     |   ✅   |
| Change History by Change Type            |     ❌     |   ✅   |
| Change History by Ticket                 |     ❌     |   ✅   |
| Total Changes per Procedure              |     ❌     |   ✅   |
| Most Active Procedures                   |     ❌     |   ✅   |
| Top Contributors                         |     ❌     |   ✅   |
| User Story Metrics (US)                  |     ❌     |   ✅   |
| Bug Metrics (BUG)                        |     ❌     |   ✅   |
| Refactoring Metrics (REF)                |     ❌     |   ✅   |
| Performance Metrics (PERF)               |     ❌     |   ✅   |
| Security Metrics (SEC)                   |     ❌     |   ✅   |
| Documentation Health Dashboard           |     ❌     |   ✅   |
| Machine Readable Metadata                |     ❌     |   ✅   |
| Executive Dashboard Reporting            |     ❌     |   ✅   |

Legend:

- ✅ Supported
- ⚠️ Partial / Manual Analysis
- ❌ Not Supported

---

## XML v2 Structure

```xml
<Documentation Version="2.0">
    <Info>
        <Application>GLOBAL CASH</Application>
        <Module>Accounting</Module>
        <Maintainer>snevarez</Maintainer>
        <Description>
            Deposits in Transit
        </Description>
    </Info>

    <Log>
        <Change
            Date="2025-10-03"
            Author="snevarez"
            Type="US"
            Ticket="250756">
            Added ReactivationAttempts
        </Change>
    </Log>
</Documentation>
```

---

## Supported Change Types

| Type | Description   |
| ---- | ------------- |
| US   | User Story    |
| BUG  | Bug Fix       |
| FIX  | Correction    |
| REF  | Refactoring   |
| DOC  | Documentation |
| PERF | Performance   |
| SEC  | Security      |

---

## Repository Structure

```text
documentation
│
├── inventory
│   ├── v1
│   └── v2
│
├── standards
│
└── samples
```

---

## Architecture

The XML v2 toolkit is composed of independent scripts.

Workflow:

validation.sql
↓
inventory-v2.sql
↓
changes-by-author.sql
↓
changes-by-type.sql
↓
dashboard-summary.sql

Each script contains its own Documentation Extraction section and can be executed independently.

This design favors portability and production compatibility over code reuse.

---

## Available Scripts

### validation.sql

Validates XML v2 compliance.

Detects:

- Missing Documentation node
- Invalid Version
- Missing Application
- Missing Module
- Missing Maintainer
- Missing Description
- Missing Log
- Missing Change
- Invalid Change Type
- Multiple Documentation nodes

---

### inventory-v2.sql

Builds a complete inventory of documented procedures.

Provides:

- Application
- Module
- Maintainer
- Description
- Documentation Version
- Change Count

---

### changes-by-author.sql

Analyzes change history by contributor.

Provides:

- Total changes per author
- Procedures affected
- First change date
- Last change date

---

### changes-by-type.sql

Analyzes change history by change classification.

Provides:

- Total changes by type
- Procedures affected
- Authors involved
- First occurrence
- Last occurrence

---

### dashboard-summary.sql

Executive summary built from XML v2 metadata.

Provides:

- Inventory metrics
- Documentation coverage
- Change metrics
- Top authors
- Top change types
- Most active procedures
- Documentation health indicators

---

## Available Metrics

### Inventory Metrics

- Total Procedures
- XML v2 Coverage
- XML v1 Coverage
- Undocumented Procedures
- Procedures by Application
- Procedures by Module
- Procedures by Maintainer

### Change Metrics

- Total Changes
- Changes by Author
- Changes by Type
- Changes by Ticket
- Changes by Date
- Procedures Changed

### Quality Metrics

- Validation Errors
- Validation Warnings
- Invalid Change Types
- Missing Metadata
- Documentation Health Indicators

### Executive Metrics

- Top Authors
- Top Change Types
- Most Active Procedures
- Documentation Coverage
- Documentation Health Dashboard

---

## Documentation Extraction

All scripts use a shared extraction strategy based on locating the first Documentation node found before the CREATE/ALTER statement.

Current implementation uses native T-SQL functions such as:

- CHARINDEX
- SUBSTRING
- TRY_CAST(XML)

Future improvement:

A reusable function such as:

```sql
dbo.ufn_GetDocumentationTag()
```

could centralize extraction logic and simplify maintenance.

---

## Use Cases

XML v2 was designed for teams maintaining large SQL Server codebases.

Typical use cases include:

- Inventorying hundreds of stored procedures
- Identifying undocumented procedures
- Tracking procedure modifications over time
- Measuring development activity by author
- Measuring work distribution by change type
- Identifying procedures with the highest maintenance activity
- Monitoring documentation quality
- Generating technical governance reports
- Supporting modernization initiatives
- Building engineering dashboards directly from SQL metadata

The toolkit is particularly useful in environments where source control history is incomplete, unavailable, or difficult to access.

## Future Improvements

### Documentation Extraction Function

The XML extraction logic is intentionally embedded within each script to keep all scripts fully independent and compatible with restricted production environments.

Future versions may introduce a reusable function such as:

```sql
dbo.ufn_GetDocumentationXml()
```

Benefits:

- Eliminate duplicated extraction logic
- Centralize XML parsing rules
- Simplify maintenance
- Improve consistency across inventory and reporting scripts

Current design favors script portability over code reuse.
