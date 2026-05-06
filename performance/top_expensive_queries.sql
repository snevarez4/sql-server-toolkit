/*
Descripción:
Obtiene las queries más costosas en términos de CPU y tiempo de ejecución promedio.

Uso:
- Identificar cuellos de botella
- Priorizar optimizaciones

Notas:
- Basado en cache (se reinicia con restart)
- Ideal para análisis inicial

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views
*/

SELECT TOP 20
    qs.execution_count,
    qs.total_worker_time / qs.execution_count AS avg_cpu_time,
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2)+1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY avg_cpu_time DESC;