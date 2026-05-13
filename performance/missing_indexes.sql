/*
Descripción:
Identifica índices potencialmente faltantes sugeridos por SQL Server.

Uso:
- Optimización de queries
- Identificación de oportunidades de performance

Notas:
- Las sugerencias deben revisarse antes de implementarse
- No crear índices automáticamente

Referencia:
https://learn.microsoft.com/sql/relational-databases/indexes/tune-nonclustered-missing-index-suggestions
*/

SELECT
    DB_NAME(mid.database_id) AS database_name,
    OBJECT_NAME(mid.object_id, mid.database_id) AS table_name,
    migs.user_seeks,
    migs.avg_total_user_cost,
    migs.avg_user_impact,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs
    ON mig.index_group_handle = migs.group_handle
INNER JOIN sys.dm_db_missing_index_details mid
    ON mig.index_handle = mid.index_handle
ORDER BY migs.avg_user_impact DESC;