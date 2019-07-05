

COLUMN execs FORMAT 999,999,999
COLUMN avg_etime_sec FORMAT 999,999.999
COLUMN avg_lio FORMAT 999,999,999,999

COLUMN avg_rows_processed FORMAT 999,999,999,999
COLUMN avg_buffer_gets FORMAT 999,999,999,999
COLUMN avg_io_saved_pct  FORMAT  999,999.9
COLUMN avg_px_servers FORMAT 999
COLUMN io_saved_pct format 9999.9
COLUMN cell_offload FORMAT a15


COLUMN avg_phys_reads_mb FORMAT 999,999,999,999.9
COLUMN avg_phys_writes_mb FORMAT 999,999,999,999.9
COLUMN avg_io_offload_elig_mb FORMAT 999,999,999,999.9
COLUMN avg_io_interconnect_mb FORMAT 999,999,999,999.9
COLUMN avg_total_phys_mb FORMAT 999,999,999,999.9
COLUMN avg_elapsed_time_sec FORMAT 999,999,999,999.9
COLUMN avg_elapsed_time_mins FORMAT 999,999,999,999.9
column plan_hash_value format 999999999999
column parsing_schema_name format A15


define SQL_ID=&1 

prompt
prompt Looking back &DAYS_AGO days ago.
prompt
prompt DBA_HIST_SQL_STAT for the following SQL : &SQL_ID  
prompt


prompt 
prompt Average, per execution :
prompt

WITH 
pivot1 as
(
select min(snap_id) AS begin_snap_id
from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
)
select sql_id,
      plan_hash_value,
      parsing_schema_name,
      force_matching_signature, 
      sql_profile,
    sum(executions_delta) executions,
    sum(elapsed_time_delta)/1000000/decode(sum(executions_delta),0,null,sum(executions_delta)) avg_elapsed_time_sec,
    sum(elapsed_time_delta)/1000000/decode(sum(executions_delta),0,null,sum(executions_delta))/60 avg_elapsed_time_mins,
    sum(rows_processed_delta)/decode(sum(executions_delta),0,null,sum(executions_delta)) avg_rows_processed,
    sum(buffer_gets_delta)/decode(sum(executions_delta),0,null,sum(executions_delta)) avg_buffer_gets,
   sum(PX_SERVERS_EXECS_DELTA)/decode(sum(executions_delta),0,null,sum(executions_delta)) avg_px_servers,
   sum(IO_OFFLOAD_ELIG_BYTES_DELTA)/decode(sum(executions_delta),0,null,sum(executions_delta))/(1024*1024) avg_io_offload_elig_mb,
   sum(IO_INTERCONNECT_BYTES_DELTA)/decode(sum(executions_delta),0,null,sum(executions_delta))/(1024*1024) avg_io_interconnect_mb,
    sum(PHYSICAL_write_BYTES_delta+PHYSICAL_READ_BYTES_delta)/decode(sum(executions_delta),0,null,sum(executions_delta))/(1024*1024) avg_total_phys_mb,
   sum(PHYSICAL_READ_BYTES_delta)/decode(sum(executions_delta),0,null,sum(executions_delta))/(1024*1024) avg_phys_reads_mb,
   sum(PHYSICAL_WRITE_BYTES_delta)/decode(sum(executions_delta),0,null,sum(executions_delta))/(1024*1024) avg_phys_writes_mb,
     decode(sum(IO_OFFLOAD_ELIG_BYTES_DELTA),0,'No','Yes') cell_offload,
  (  sum(IO_OFFLOAD_ELIG_BYTES_DELTA) -  sum(IO_INTERCONNECT_BYTES_DELTA) )*100/decode(sum(IO_OFFLOAD_ELIG_BYTES_DELTA),0,null,sum(IO_OFFLOAD_ELIG_BYTES_DELTA) )  avg_io_saved_pct,
  min(snap_id) as begin_snap, max(snap_id) as end_snap
from dba_hist_sqlstat hss
where snap_id > (select begin_snap_id from pivot1)
and  sql_id in &SQL_ID
group by sql_id, plan_hash_value, parsing_schema_name,       force_matching_signature, sql_profile
order by begin_snap;


/*
-- note this query includes where the executions_delta is 0



WITH 
pivot1 as
(
select min(snap_id) AS begin_snap_id
from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
)
SELECT SS.snap_id,
       trunc(AWR.begin_interval_time,'MI') begin_interval,
       SS.sql_id, 
      SS.plan_hash_value,
      sum(executions_delta) execs,
      (sum(elapsed_time_delta)/greatest(sum(executions_delta),1))/1000000 avg_etime_sec,
      sum(buffer_gets_delta)/greatest(sum(executions_delta),1) avg_lio,
      sum(disk_reads_delta)/greatest(sum(executions_delta),1) avg_phy_block_reads,
      sum(rows_processed_delta)/greatest(sum(executions_delta),1) avg_rows_processed
FROM DBA_HIST_SQLSTAT SS
INNER JOIN DBA_HIST_SNAPSHOT AWR ON  SS.snap_id = AWR.snap_id and ss.instance_number = AWR.instance_number 
and  SS.sql_id in  &SQL_ID
and   SS.snap_id > (select begin_snap_id from pivot1)
--AND SS.executions_delta > 0
GROUP BY SS.snap_id, trunc(AWR.begin_interval_time, 'MI'), SS.sql_id, SS.plan_hash_value
order by 1, 2, 3;




define SQL_ID=&1
prompt
prompt PARALLEL AND Exadata stats FOR &SQL_ID FROM dba_hist_sqlstat :
prompt





WITH 
pivot1 as
(
select min(snap_id) AS begin_snap_id
from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
)
select SS.snap_id,
       trunc(AWR.begin_interval_time,'MI') begin_interval,
       SS.sql_id, 
      SS.plan_hash_value, 
      sum(executions_delta) execs, 
        (sum(elapsed_time_delta)/1000000)/ decode(sum(executions_delta),0,1,sum(executions_delta)) / decode(sum(px_servers_execs_delta),0,1,sum(px_servers_execs_delta)/decode(sum(executions_delta),0,1,sum(executions_delta))) avg_etime_sec,
      sum(PX_SERVERS_EXECS_DELTA) px_execs,
      sum(PX_SERVERS_EXECS_DELTA)/decode(sum(executions_delta), 0, 1, sum(executions_delta))  avg_px_per_exec,
      sum(PHYSICAL_READ_BYTES_delta)/1024 / decode(sum(executions_delta),0,1,sum(executions_delta))/ decode(sum(px_servers_execs_delta),0,1,sum(px_servers_execs_delta)/decode(sum(executions_delta),0,1,sum(executions_delta))) phys_read_kb_per_exec,
      sum(IO_OFFLOAD_ELIG_BYTES_delta)/1024 / decode(sum(executions_delta),0,1,sum(executions_delta))/ decode(sum(px_servers_execs_delta),0,1,sum(px_servers_execs_delta)/decode(sum(executions_delta),0,1,sum(executions_delta))) io_elig_kb_per_exec,
	    sum(IO_INTERCONNECT_BYTES_delta)/1024 / decode(sum(executions_delta),0,1,sum(executions_delta))/ decode(sum(px_servers_execs_delta),0,1,sum(px_servers_execs_delta)/decode(sum(executions_delta),0,1,sum(executions_delta))) io_conn_kb_per_exec,
      decode(sum(IO_OFFLOAD_ELIG_BYTES_DELTA),0,'No','Yes') Offload,
      decode(sum(IO_OFFLOAD_ELIG_BYTES_DELTA),0,0,100*(sum(IO_OFFLOAD_ELIG_BYTES_delta)-sum(IO_INTERCONNECT_BYTES_DELTA))/sum(IO_OFFLOAD_ELIG_BYTES_delta)) avg_IO_SAVED_pct
--        regexp_replace( substr(sql_text, 1, 70) , '[' || chr(10) || chr(13) || ']', ' ') sql_text
FROM DBA_HIST_SQLSTAT SS
INNER JOIN DBA_HIST_SNAPSHOT AWR ON  SS.snap_id = AWR.snap_id and ss.instance_number = AWR.instance_number 
and   SS.sql_id in &SQL_ID 
AND SS.snap_id > (select begin_snap_id from pivot1)
--AND SS.executions_delta > 0
GROUP BY SS.snap_id, trunc(AWR.begin_interval_time, 'MI'), SS.sql_id, SS.plan_hash_value
order by 1, 2, 3;


-- awr sqlstats combined with a sql_text search

WITH pivot1 AS
(
select sql_id from dba_hist_sqltext where sql_text like '%parallel(po 6)%' and sql_text not like '%sql_text%'
), 
pivot2 AS
(
SELECT snap_id FROM dba_hist_snapshot WHERE begin_interval_time > SYSDATE - 7
)
SELECT SS.snap_id,
       trunc(AWR.begin_interval_time,'MI') begin_interval,
       SS.sql_id, 
      SS.plan_hash_value,
      sum(executions_delta) execs,
      (sum(elapsed_time_delta)/sum(executions_delta))/1000000 avg_etime_sec,
      sum(buffer_gets_delta)/sum(executions_delta) avg_lio,
      sum(physical_read_requests_delta)/sum(executions_delta) avg_phy_read,
      sum(rows_processed_delta)/sum(executions_delta) avg_rows_processed
FROM DBA_HIST_SQLSTAT SS, DBA_HIST_SNAPSHOT AWR
WHERE SS.sql_id in (select sql_id from pivot1)
AND SS.snap_id = AWR.snap_id
AND SS.snap_id in (select snap_id from pivot2)
AND SS.executions_delta > 0
GROUP BY SS.snap_id, trunc(AWR.begin_interval_time, 'MI'), SS.sql_id, SS.plan_hash_value
order by 1, 2, 3;




--this query shows the instance number 

SELECT ss.snap_id, 
  ss.instance_number node, 
  begin_interval_time, sql_id, plan_hash_value,
  nvl(executions_delta,0) execs,
  (elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime_sec,
  (buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)) avg_lio,
  (physical_read_bytes_delta/decode(nvl(physical_read_bytes_delta,0),0,1,executions_delta)) avg_phy_read_bytes
FROM DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS
WHERE sql_id like '&SQL_ID'
AND ss.snap_id = S.snap_id
AND S.snap_id >= &STARTING_SNAP_ID 
AND ss.instance_number = S.instance_number
AND executions_delta > 0
order by 1, 2, 3;

*/


-- original query by austin

/*
define SQLID=%;
define DAYS_AGO=7;

clear screen;


select to_char(min(s.end_interval_time),'DD-MON-YYYY DY HH24:MI') sample_end, 
  q.sql_id, 
  q.plan_hash_value, 
  sum(q.EXECUTIONS_DELTA) executions, 
  round(sum(DISK_READS_delta)/greatest(sum(executions_delta),1),1) pio_perexec, 
  round(sum(BUFFER_GETS_delta)/greatest(sum(executions_delta),1),1) lio_perexec, 
  round((sum(ELAPSED_TIME_delta)/greatest(sum(executions_delta),1)/1000),1) msec_perexec,
  round((sum(ROWS_PROCESSED_delta)/greatest(sum(executions_delta),1)/1000),1) ROWS_PROCESSED_perexec
from dba_hist_sqlstat q, dba_hist_snapshot s
where q.SQL_ID like '&SQLID'
and s.snap_id = q.snap_id
and s.dbid = q.dbid
AND S.INSTANCE_NUMBER = Q.INSTANCE_NUMBER
and begin_interval_time >= sysdate - &DAYS_AGO
and executions_delta != 0
group by s.snap_id, q.sql_id, q.plan_hash_value
ORDER BY S.SNAP_ID, Q.SQL_ID, Q.PLAN_HASH_VALUE;



*/


