col PARAM1 new_value 1 format A10

select null PARAM1 from dual where 1=2;
select nvl( '&1','%') PARAM1 from dual ;


define INST_ID=&1

undefine 1
undefine 2
undefine 3



COLUMN host_cpu_util FORMAT 999;
COLUMN  os_load FORMAT 999;  
COLUMN   avg_act_sess FORMAT 999;
COLUMN  redo_per_sec FORMAT 999,999,999;
COLUMN  total_io_mb_per_sec FORMAT 999,999;
COLUMN  exec_per_sec FORMAT 999,999;
COLUMN  hard_parses_per_sec FORMAT 999;
COLUMN  logical_reads_per_sec FORMAT 999,999,999;
COLUMN   logons_per_sec FORMAT 999,999;
COLUMN  tot_parses_per_sec FORMAT 9,999;
COLUMN   tot_scans_per_sec FORMAT 999,999;
COLUMN  user_calls_per_sec FORMAT 999,999;
COLUMN    user_commits_per_sec FORMAT 999;
COLUMN  gc_block_rec_per_sec FORMAT 999,999;
COLUMN  IOPS FORMAT 999,999
column end_time format A21
column instances format A10

    SELECT
      '&INST_ID' as instances,
      to_char( MAX (end_time), 'DY DD-MON-YYYY HH24:MI')        AS end_time ,
      trunc(SUM (      CASE metric_name   WHEN 'Host CPU Utilization (%)'        THEN average    END)) AS host_cpu_util ,
      trunc(SUM (      CASE metric_name   WHEN 'Current OS Load'  THEN average     END)) AS os_load ,
      trunc(SUM (      CASE metric_name   WHEN 'Average Active Sessions'        THEN average   END)) AS avg_act_sess ,
      trunc(SUM (      CASE metric_name   WHEN 'Redo Generated Per Sec'        THEN average     END)) AS redo_per_sec ,
      trunc(SUM (      CASE metric_name   WHEN 'Physical Read IO Requests Per Sec'  THEN average  END) + SUM ( CASE metric_name WHEN 'Physical Write IO Requests Per Sec'        THEN average    END)) AS iops ,
      trunc(SUM (      CASE metric_name   WHEN 'Physical Read Total Bytes Per Sec'        THEN average  END) + (SUM (      CASE metric_name    WHEN 'Physical Write Total Bytes Per Sec'        THEN average     END)))/(1024*1024) AS total_io_mb_per_sec ,
      trunc(SUM (      CASE metric_name   WHEN 'Executions Per Sec'        THEN average    END)) AS exec_per_sec ,
      trunc(SUM (      CASE metric_name    WHEN 'Hard Parse Count Per Sec'        THEN average END)) AS hard_parses_per_sec ,
      trunc(SUM (      CASE metric_name    WHEN 'Logical Reads Per Sec'        THEN average   END)) AS logical_reads_per_sec ,
      trunc(SUM (      CASE metric_name  WHEN 'Logons Per Sec'        THEN average     END)) AS logons_per_sec ,
      trunc(SUM (      CASE metric_name  WHEN 'Total Parse Count Per Sec'        THEN average  END)) AS tot_parses_per_sec ,
      trunc(SUM (      CASE metric_name  WHEN 'Total Table Scans Per Sec'        THEN average  END)) AS tot_scans_per_sec ,
      trunc(SUM (      CASE metric_name  WHEN 'User Calls Per Sec'        THEN average     END)) AS user_calls_per_sec ,
      trunc(SUM (      CASE metric_name   WHEN 'User Commits Per Sec'        THEN average     END)) AS user_commits_per_sec ,
      trunc(SUM (      CASE metric_name  WHEN 'GC CR Block Received Per Second'        THEN average     END) + SUM (      CASE metric_name  WHEN 'GC Current Block Received Per Second'        THEN average    END)) AS gc_block_rec_per_sec ,
      snap_id    
   FROM
      dba_hist_sysmetric_summary    
WHERE
    snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
and dbid = (select dbid from v$database)
and instance_number like '&INST_ID'
   GROUP BY
      snap_id    
ORDER BY
   snap_id;
   

/*   
   
   prompt
   prompt querying DBA_HIST_SYSMETRIC for the whole database :
   prompt
   
   
   
   WITH 
   pivot1 as
   (
   select min(snap_id) AS begin_snap_id
   from dba_hist_snapshot 
   where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
   ), 
   pivot2 as
   (
   select min(begin_time) begin_time, 
          max(end_time) as end_time,
          metric_name, 
              trunc(SUM(average) total_avg
      FROM
         dba_hist_sysmetric_trunc(SUMmary    
   WHERE snap_id > (select begin_snap_id from pivot1)
   and dbid = (select dbid from v$database)
   group by snap_id, metric_name
   )
   select * from pivot2
   pivot (max( to_char(total_avg , '999,999,999,999,999.9'))
    for metric_name in ( 'Physical Read Total IO Requests Per Sec',
                         'Physical Write Total IO Requests Per Sec',
                         'Physical Read Total Bytes Per Sec',
                         'Physical Write Total Bytes Per Sec',
                         'Average Synchronous Single-Block Read Latency') );
   
   
   
   prompt
   prompt querying DBA_HIST_SYSMETRIC for instance &INSTANCE_NUM :
   prompt
   

   
   WITH 
   pivot1 as
   (
   select min(snap_id) AS begin_snap_id
   from dba_hist_snapshot 
   where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
   ), 
   pivot2 as
   (
   select min(begin_time) begin_time, 
          max(end_time) as end_time,
          metric_name, 
          instance_number, 
              trunc(SUM(average)  total_avg
      FROM
         dba_hist_sysmetric_trunc(SUMmary    
   WHERE snap_id > (select begin_snap_id from pivot1)
   and dbid = (select dbid from v$database)
   group by snap_id, metric_name, instance_number
   )
   select * from pivot2
   pivot (max( to_char(total_avg , '999,999,999,999,999.9')) 
    for metric_name in ( 'Physical Read Total IO Requests Per Sec',
                         'Physical Write Total IO Requests Per Sec',
                         'Physical Read Total Bytes Per Sec',
                         'Physical Write Total Bytes Per Sec',
                         'Average Synchronous Single-Block Read Latency') )
   where instance_number = &INSTANCE_NUM;

*/
