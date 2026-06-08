/*
Descripción: 
Inventory Summary by App

Compatibility:
SQL Server 2012+
*/
WITH ProcedureInventory
AS
(
    SELECT
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
            END
    FROM sys.procedures P
    INNER JOIN sys.sql_modules M
        ON M.object_id = P.object_id
)
SELECT
    ApplicationName,
    ProcedureCount = COUNT(*)
FROM ProcedureInventory
GROUP BY ApplicationName
ORDER BY COUNT(*) DESC;