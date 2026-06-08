# Stored Procedure Documentation & Change Tracking Toolkit

Problem:
Documentation exists but cannot be queried.

Solution:
Extract metadata from structured comments embedded inside stored procedures.

Benefits:

- Procedure inventory
- Documentation coverage
- Application mapping
- Technical debt visibility

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

dbo.ufn_GetDocumentationTag()

Benefits:

- Reusable parsing logic
- Simplified maintenance
- Reduced code duplication
- Easier migration to Documentation XML v2

## Design Decisions

### Why not use a scalar function?

The first release intentionally avoids custom functions.

Reasons:

- Zero deployment dependencies
- Easier adoption in production environments
- Compatibility with restricted permissions
- Simpler execution by DBAs and developers

Trade-off:

- Some parsing logic is duplicated across scripts.

This trade-off was accepted in favor of portability.
