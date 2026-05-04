/*
Descripción:
Calcula el tamaño de cada tabla en la base de datos, incluyendo:
- Filas
- Tamaño de datos
- Tamaño de índices
- Espacio total

Uso:
- Identificar tablas más pesadas
- Planear optimización o particionamiento

Notas:
- Evita sp_MSforeachtable (no documentado)
- Usa vistas del sistema modernas

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-catalog-views
*/

SELECT
    t.name AS table_name,
    s.name AS schema_name,
    p.rows AS row_count,
    SUM(a.total_pages) * 8 AS total_kb,
    SUM(a.used_pages) * 8 AS used_kb,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS unused_kb
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY t.name, s.name, p.rows
ORDER BY total_kb DESC;