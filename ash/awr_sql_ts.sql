
define SQL_ID=&1
define SQL_EXEC_ID=&2

column ts_read_mb format 999,999,999,999
column ts_write_mb format 999,999,999,999

WITH 
pivot2 as
(
select         DDF.tablespace_name  ,
     sum(delta_read_io_bytes)/(1024*2014) ts_read_mb,
        sum(delta_write_io_bytes)/(1024*2014) ts_write_mb
from dba_hist_active_sess_history ash
left outer join dba_data_files DDF on DDF.file_id = ASH.current_file#
WHERE  
     session_type = 'FOREGROUND'
and     snap_id > (select min(snap_id) from dba_hist_snapshot where begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD'))
AND  dbid = (select dbid from v$database)
AND  SQL_EXEC_ID = &SQL_EXEC_ID
and  sql_id  like '&SQL_ID'
group by tablespace_name
)
select * from pivot2
order by ts_read_mb desc;

