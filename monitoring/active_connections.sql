/*
Descripción:
Obtiene las sesiones activas en SQL Server, incluyendo información de CPU, IO,
estado, base de datos y aplicación.

Uso:
- Troubleshooting de lentitud
- Identificación de bloqueos
- Análisis de carga por aplicación/usuario

Notas:
- Reemplaza el uso de sysprocesses (deprecated) por DMV modernas
- Permite filtrar por hostname o login

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views
*/

DECLARE @hostname NVARCHAR(100) = NULL; -- Ej: 'MXNSVR000'
DECLARE @loginname NVARCHAR(100) = NULL; -- Ej: 'appDev'

SELECT
    s.session_id,
    s.status,
    s.login_name,
    s.host_name,
    s.program_name,
    s.login_time,
    r.status AS request_status,
    r.cpu_time,
    r.logical_reads,
    r.reads,
    r.writes,
    r.blocking_session_id,
    DB_NAME(r.database_id) AS database_name,
    r.command,
    r.wait_type,
    r.wait_time,
    r.last_wait_type
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r 
    ON s.session_id = r.session_id
WHERE
    (@hostname IS NULL OR s.host_name = @hostname)
    AND (@loginname IS NULL OR s.login_name = @loginname)
ORDER BY r.cpu_time DESC;