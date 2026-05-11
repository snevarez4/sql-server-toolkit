/*
Descripción:
Muestra tamaño y crecimiento de archivos de base de datos.

Uso:
- Capacity planning
- Monitoreo de crecimiento

Notas:
- Incluye data y log files

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-catalog-views
*/

SELECT
    DB_NAME(database_id) AS database_name,
    name AS logical_name,
    physical_name,
    type_desc,
    size * 8 / 1024 AS size_mb,
    growth,
    is_percent_growth
FROM sys.master_files
ORDER BY database_name, type_desc;