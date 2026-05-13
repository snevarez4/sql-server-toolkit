/*
Descripción:
Muestra estadísticas acumuladas de waits en SQL Server.

Uso:
- Diagnóstico de cuellos de botella
- Identificar presión de CPU, IO, locking o memory

Notas:
- Reiniciado al reiniciar SQL Server
- Filtra waits comunes no relevantes

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views
*/

SELECT TOP 20
    wait_type,
    waiting_tasks_count,
    wait_time_ms / 1000.0 AS wait_time_seconds,
    max_wait_time_ms / 1000.0 AS max_wait_seconds,
    signal_wait_time_ms / 1000.0 AS signal_wait_seconds
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'SLEEP_TASK',
    'BROKER_TASK_STOP',
    'BROKER_TO_FLUSH',
    'SQLTRACE_BUFFER_FLUSH',
    'CLR_AUTO_EVENT',
    'CLR_MANUAL_EVENT',
    'LAZYWRITER_SLEEP',
    'SLEEP_SYSTEMTASK',
    'XE_TIMER_EVENT',
    'XE_DISPATCHER_WAIT'
)
ORDER BY wait_time_ms DESC;