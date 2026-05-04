/*
Descripción:
Analiza la fragmentación de índices y sugiere acción:
- REORGANIZE
- REBUILD
- NO ACTION

Uso:
- Mantenimiento de performance
- Optimización de consultas

Notas:
- Basado en thresholds comunes:
  <5%  → OK
  5–30% → REORGANIZE
  >30% → REBUILD

Referencia:
https://learn.microsoft.com/sql/relational-databases/indexes
*/

SELECT
    OBJECT_NAME(ps.object_id) AS table_name,
    i.name AS index_name,
    ps.index_type_desc,
    ps.avg_fragmentation_in_percent,
    ps.page_count,
    CASE 
        WHEN ps.avg_fragmentation_in_percent < 5 THEN 'OK'
        WHEN ps.avg_fragmentation_in_percent BETWEEN 5 AND 30 THEN 'REORGANIZE'
        ELSE 'REBUILD'
    END AS recommended_action
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
INNER JOIN sys.indexes i 
    ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE ps.page_count > 1000
ORDER BY ps.avg_fragmentation_in_percent DESC;