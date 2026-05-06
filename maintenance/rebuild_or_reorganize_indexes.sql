/*
Descripción:
Genera comandos dinámicos para REBUILD o REORGANIZE índices
según nivel de fragmentación.

Uso:
- Mantenimiento programado
- Automatización de optimización

Notas:
- No ejecuta automáticamente (seguridad)
- Revisar antes de ejecutar en producción

Referencia:
https://learn.microsoft.com/sql/relational-databases/indexes
*/

SELECT
    OBJECT_NAME(ps.object_id) AS table_name,
    i.name AS index_name,
    ps.avg_fragmentation_in_percent,
    CASE 
        WHEN ps.avg_fragmentation_in_percent < 5 THEN 'NO ACTION'
        WHEN ps.avg_fragmentation_in_percent BETWEEN 5 AND 30 
            THEN 'ALTER INDEX [' + i.name + '] ON [' + OBJECT_NAME(ps.object_id) + '] REORGANIZE'
        ELSE 
            'ALTER INDEX [' + i.name + '] ON [' + OBJECT_NAME(ps.object_id) + '] REBUILD'
    END AS command
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
INNER JOIN sys.indexes i 
    ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE ps.page_count > 1000
ORDER BY ps.avg_fragmentation_in_percent DESC;