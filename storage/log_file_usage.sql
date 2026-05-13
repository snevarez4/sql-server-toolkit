/*
Descripción:
Muestra uso de archivos de log por base de datos.

Uso:
- Diagnóstico de crecimiento de logs
- Monitoreo de recovery model
- Troubleshooting de espacio

Notas:
- Muy útil en ambientes con transacciones pesadas

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views
*/

DBCC SQLPERF(LOGSPACE);