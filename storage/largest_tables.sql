/*
Descripción:
Lista las tablas más grandes por número de filas y tamaño estimado.

Uso:
- Capacity planning
- Identificar tablas críticas

Notas:
- Útil para archivado o particionamiento

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-catalog-views
*/

SELECT TOP 20
    s.name AS schema_name,
    t.name AS table_name,
    p.rows AS row_count,
    SUM(a.total_pages) * 8 / 1024 AS total_mb
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i
    ON t.object_id = i.object_id
INNER JOIN sys.partitions p
    ON i.object_id = p.object_id
    AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a
    ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, p.rows
ORDER BY total_mb DESC;