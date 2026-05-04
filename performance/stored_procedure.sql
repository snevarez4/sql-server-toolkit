/*
Descripción:
Muestra métricas de ejecución de procedimientos almacenados:
- Tiempo promedio
- CPU promedio
- Lecturas lógicas
- Última ejecución

Uso:
- Identificar SPs lentos
- Detectar cuellos de botella

Notas:
- Basado en cache → se reinicia con restart del servidor
- Filtrar por nombre si es necesario

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views
*/

SELECT
    DB_NAME(database_id) AS database_name,
    OBJECT_NAME(object_id) AS procedure_name,
    execution_count,
    total_elapsed_time / execution_count AS avg_elapsed_time_ms,
    total_worker_time / execution_count AS avg_cpu_time_ms,
    total_logical_reads / execution_count AS avg_logical_reads,
    last_execution_time
FROM sys.dm_exec_procedure_stats
WHERE database_id = DB_ID()
ORDER BY avg_elapsed_time_ms DESC;