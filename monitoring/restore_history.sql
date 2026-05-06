/*
Descripción:
Consulta el historial de restauraciones de bases de datos.

Uso:
- Auditoría de restores
- Validar cuándo y desde dónde se restauró una BD

Notas:
- Útil en ambientes con múltiples restores (QA / DR)

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-tables
*/

SELECT
    rh.destination_database_name AS database_name,
    rh.restore_date,
    bs.database_name AS source_database,
    bmf.physical_device_name AS backup_file,
    bs.user_name,
    bs.machine_name
FROM msdb.dbo.restorehistory rh
INNER JOIN msdb.dbo.backupset bs 
    ON rh.backup_set_id = bs.backup_set_id
INNER JOIN msdb.dbo.backupmediafamily bmf 
    ON bs.media_set_id = bmf.media_set_id
ORDER BY rh.restore_date DESC;