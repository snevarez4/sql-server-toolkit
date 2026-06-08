/*
Descripción: 
Inventory Summary

Compatibility:
SQL Server 2012+
*/

;WITH ProcedureInventory
AS
(
    SELECT
            CASE
                WHEN M.definition LIKE '%<Description>%'
                 AND M.definition LIKE '%<ChangeLog>%'
                THEN 1
                ELSE 0
            END AS HasDocumentation
    FROM sys.procedures P
    INNER JOIN sys.sql_modules M
        ON M.object_id = P.object_id
)SELECT
    TotalProcedures = COUNT(*),
    DocumentedProcedures = SUM(HasDocumentation),
    UndocumentedProcedures = COUNT(*) - SUM(HasDocumentation),
    DocumentationCoveragePercent = CAST( 100.0 * SUM(HasDocumentation) / NULLIF(COUNT(*),0) AS DECIMAL(10,2) )
FROM ProcedureInventory