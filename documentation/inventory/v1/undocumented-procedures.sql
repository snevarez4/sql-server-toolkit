/*
Descripción: 
Undocumented procedures

Compatibility:
SQL Server 2012+
*/

SELECT
    SCHEMA_NAME(P.schema_id) AS SchemaName,
    P.name AS ProcedureName,
    P.modify_date
FROM sys.procedures P
INNER JOIN sys.sql_modules M
    ON M.object_id = P.object_id
WHERE
    M.definition NOT LIKE '%<Description>%'
    OR
    M.definition NOT LIKE '%<ChangeLog>%'
ORDER BY
    P.modify_date DESC;