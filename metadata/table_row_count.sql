/*
Descripción:
Obtiene el número de filas por tabla sin usar COUNT(*).

Uso:
- Análisis rápido de volumen de datos
- Evitar scans costosos en tablas grandes

Notas:
- Basado en metadata (puede no ser 100% exacto en tiempo real)

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-catalog-views
*/

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY row_count DESC;