/*
Descripción:
Identifica sesiones bloqueadas y la sesión que está causando el bloqueo.

Uso:
- Diagnóstico de bloqueos en producción
- Identificar procesos que afectan performance

Notas:
- Incluye query en ejecución
- Útil para troubleshooting inmediato

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views
*/

SELECT
    r.session_id AS blocked_session_id,
    r.blocking_session_id,
    s.login_name,
    s.host_name,
    DB_NAME(r.database_id) AS database_name,
    r.wait_type,
    r.wait_time,
    r.status,
    st.text AS query_text
FROM sys.dm_exec_requests r
INNER JOIN sys.dm_exec_sessions s 
    ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE r.blocking_session_id <> 0
ORDER BY r.wait_time DESC;