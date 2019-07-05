
define SQL_ID=&1


COLUMN AVG_ETIME_SECS  format 999,999,999
column avg_cpu_time  format 999,999,999
column avg_rows_processed  format 999,999,999
column avg_buffer_gets  format 999,999,999
column avg_disk_reads  format 999,999,999
column end_time format A21


select snap_id, 
   (select distinct end_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) end_time , 
    sql_id, 
   plan_hash_value,
    sum(AWR.executions_delta) executions,
    decode(sum(AWR.executions_delta),0,0,sum(AWR.elapsed_time_delta)/1000000/sum(AWR.executions_delta)  ) AVG_ETIME_SECS,
    sum(AWR.cpu_time_delta)/1000000/decode(sum(AWR.executions_delta),0,null,sum(AWR.executions_delta)) avg_cpu_time,
    sum(AWR.rows_processed_delta)/decode(sum(AWR.executions_delta),0,null,sum(AWR.executions_delta)) avg_rows_processed,
    sum(AWR.buffer_gets_delta)/decode(sum(AWR.executions_delta),0,null,sum(AWR.executions_delta)) avg_buffer_gets,
    sum(AWR.disk_reads_delta)/decode(sum(AWR.executions_delta),0,null,sum(AWR.executions_delta)) avg_disk_reads
from dba_hist_sqlstat AWR
where AWR.sql_id = '&SQL_ID'
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
group by snap_id, sql_id, plan_hash_value
order by snap_id;



