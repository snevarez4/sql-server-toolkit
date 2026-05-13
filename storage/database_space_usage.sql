/*
Descripción:
Muestra espacio usado y libre por base de datos.

Uso:
- Capacity planning
- Monitoreo de crecimiento
- Análisis de almacenamiento

Notas:
- Incluye tamaño total y espacio libre

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-catalog-views
*/

EXEC sp_MSforeachdb '
USE [?];

SELECT
    DB_NAME() AS database_name,
    SUM(size) * 8 / 1024 AS total_size_mb,
    SUM(FILEPROPERTY(name, ''SpaceUsed'')) * 8 / 1024 AS used_space_mb,
    (SUM(size) - SUM(FILEPROPERTY(name, ''SpaceUsed''))) * 8 / 1024 AS free_space_mb
FROM sys.database_files
GROUP BY database_id
';