

COLUMN backup_type format A8
COLUMN controlfile_included format A10 
COLUMN incremental_level format A10
column start_time format A21
column end_time format A21
column recid format 99999999

select inst_id, recid, set_stamp, set_count, backup_type , controlfile_included, 
      incremental_level, pieces, start_time, completion_time end_time, elapsed_seconds/60 etime_mins,
      keep_until
from gv$backup_set
where start_time > sysdate - &DAYS_AGO
order by start_time;

