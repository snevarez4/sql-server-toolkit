/*
Descripción:
Obtiene estadísticas de ejecución de procedimientos recientes.

Uso:
- Análisis de rendimiento en caliente
- Identificar degradaciones recientes

Notas:
- Basado en cache
- Filtrar por procedimiento si es necesario

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views
*/

SELECT
    DB_NAME(database_id) AS database_name,
    OBJECT_NAME(object_id) AS object_name,
    last_execution_time,
    execution_count,
    total_worker_time / execution_count AS avg_cpu_time,
    total_elapsed_time / execution_count AS avg_elapsed_time,
    total_logical_reads / execution_count AS avg_logical_reads
FROM sys.dm_exec_procedure_stats
WHERE last_execution_time > DATEADD(DAY, -7, GETDATE())
ORDER BY last_execution_time DESC;