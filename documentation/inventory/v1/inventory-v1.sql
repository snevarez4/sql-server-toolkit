/*
Descripción:
Stored Procedure Documentation Inventory

Compatibility:
SQL Server 2012+
*/

SELECT
    SchemaName =
        SCHEMA_NAME(P.schema_id),

    ProcedureName =
        P.name,

    LastModified =
        P.modify_date,

    HasDocumentation =
        CASE
            WHEN M.definition LIKE '%<Description>%'
             AND M.definition LIKE '%<ChangeLog>%'
            THEN 1
            ELSE 0
        END,

    ApplicationName =
        CASE
            WHEN CHARINDEX('<app>', M.definition) > 0
            THEN
                SUBSTRING
                (
                    M.definition,
                    CHARINDEX('<app>', M.definition) + 5,
                    CHARINDEX('</app>', M.definition)
                    - CHARINDEX('<app>', M.definition)
                    - 5
                )
        END,

    DescriptionText =
        CASE
            WHEN CHARINDEX('<Description>', M.definition) > 0
            THEN
                SUBSTRING
                (
                    M.definition,
                    CHARINDEX('<Description>', M.definition) + 13,
                    CHARINDEX('</Description>', M.definition)
                    - CHARINDEX('<Description>', M.definition)
                    - 13
                )
        END

FROM sys.procedures P
INNER JOIN sys.sql_modules M
    ON M.object_id = P.object_id

ORDER BY
    SchemaName,
    ProcedureName;