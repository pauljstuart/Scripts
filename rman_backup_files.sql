

column fname format A50;
column file_type format A10;
column device_type format A10;
column backup_type format A10;
column status format A5;

select backup_type, file_type, status, fname, stamp, device_type, completion_time, round(bytes/(1024*1024))  "Mbytes"
from v$backup_files
where  file_type = 'PIECE'
order by stamp;

