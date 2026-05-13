/*
Descripción:
Muestra requests con larga duración actualmente en ejecución.

Uso:
- Troubleshooting de lentitud
- Identificar queries atoradas
- Detectar procesos problemáticos

Notas:
- Incluye tiempo, waits y query ejecutada

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views
*/

SELECT
    r.session_id,
    s.login_name,
    s.host_name,
    DB_NAME(r.database_id) AS database_name,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time / 1000 AS elapsed_seconds,
    r.wait_type,
    r.wait_time,
    st.text AS query_text
FROM sys.dm_exec_requests r
INNER JOIN sys.dm_exec_sessions s
    ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE r.session_id > 50
    AND r.total_elapsed_time > 10000
ORDER BY elapsed_seconds DESC;