





define SQL_ID=&1
define SQL_EXEC_ID=&2


column sql_plan_line_id format 999,999
column ALL_PHYS_MB format 999,999,999
column phys_total_gb format 999,999,999
column temp_used_mb format 999,999,999
column max_temp_mb format 999,999,999
column db_time_secs format 999,999,999

column sql_plan_operation format A15
column sql_plan_options format A15
column event format A30
column object_name format a30
column start_time format A20
column end_time format A20
column average_wait_ms format 999,999
column MAX_WAIT_MS format 999,999,999
column TIME_WAITED_MS format 999,999,999

COLUMN wait_pct FORMAT 999.9;
COLUMN total_time_approx_sec FORMAT 999,999;
COLUMN db_event format A30
column total_waits format 999,999,999
column   BLOCKING_INST_ID format 999,999
column  BLOCKING_SESSION  format 999,999              
column BLOCKING_SESSION_SERIAL#  format 999,999



prompt =========================================================================================================================================================================================================

 
prompt 
prompt SQL database time for  SQL_ID  : &SQL_ID	  SQL_EXEC_ID :	&SQL_EXEC_ID
prompt



PROMPT
prompt top level summary
prompt


WITH 
pivot2 as
(
select  
      instance_number as inst_id,
      user_id, 
      session_id,
      session_serial#,
      sql_opname,
      module,
      sql_id, 
      sql_exec_id,
      SQL_PLAN_HASH_VALUE,
      sql_exec_start , 
      MAX(sample_time) sql_end_time, 
         (CAST(MAX(sample_time)  AS DATE) - CAST( SQL_EXEC_START AS DATE)) * 3600*24 etime_secs ,
         (CAST(MAX(sample_time)  AS DATE) - CAST( SQL_EXEC_START AS DATE)) * 60*24 etime_mins ,
       sum(DELTA_INTERCONNECT_IO_BYTES)/(1024*1024) interconnect_mb,
	     sum(nvl(delta_write_io_bytes, 0) + nvl(delta_read_io_bytes, 0))/(1024*1024)   phys_total_mb,
	     sum(delta_read_io_bytes)/(1024*1024)  phys_read_mb,
       sum(delta_write_io_bytes)/(1024*1024)  phys_write_mb,
                     sum(DELTA_READ_IO_REQUESTS) read_io_requests,
                    sum(DELTA_WRITE_IO_REQUESTS) write_io_requests,
       max(temp_space_allocated)/(1024*1024) max_temp_mb,
    max(pga_allocated)/(1024*1024) max_pga_mb
from dba_hist_active_sess_history 
WHERE  
        session_type = 'FOREGROUND'
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
and  sql_id  = '&SQL_ID'
AND  sql_exec_id = &SQL_EXEC_ID
group by  instance_number, user_id, session_id, session_serial#, sql_opname, module,  sql_id,  sql_exec_id, SQL_PLAN_HASH_VALUE, sql_exec_start
)
select
     (select username from dba_users where SM.user_id = user_id ) as username,
      sql_opname,
      SM.sql_id, 
      sql_exec_id,
      SQL_PLAN_HASH_VALUE,
      SM.module,
      count(*) parallel_deg,
      LISTAGG(SM.inst_id, '') WITHIN GROUP (ORDER BY SM.inst_id) as parallel_instances,
      sql_exec_start as px_start_time, 
      max(sql_end_time) as px_end_time,
      max(etime_mins) px_etime_mins,
    sum(   phys_total_mb ) px_phys_total_mb,
    sum(  phys_read_mb ) px_phys_read_mb,
    sum(phys_write_mb )  px_phys_write_mb,
    sum(max_temp_mb)   px_temp_mb,
   sum(max_pga_mb) px_pga_mb
from pivot2 SM 
group by user_id, sql_opname, module, sql_id, sql_exec_id, sql_exec_start, sql_plan_hash_value
order by sql_exec_start
/

prompt
prompt ASH summary :
prompt

SELECT   
     ASH.instance_number as inst_id, 
     ASH.user_id, 
      ASH.session_id sid, 
      ASH.session_serial# serial#, 
      ASH.top_level_sql_id, 
      ASH.sql_id, 
      ASH.sql_exec_id,
      ash.sql_exec_start,
      ASH.SQL_PLAN_HASH_VALUE,
       ASH.sql_opname,
      ASH.module,
      ASH.in_hard_parse, 
       NVL(ASH.sql_exec_start, min(sample_time)) sql_start_time, 
             MAX(sample_time) sql_end_time, 
              (CAST(MAX(sample_time)  AS DATE) - CAST( NVL(ASH.sql_exec_start, min(sample_time)) AS DATE)) * 3600*24 etime_secs ,
             (CAST(MAX(sample_time)  AS DATE) - CAST( NVL(ASH.sql_exec_start, min(sample_time)) AS DATE)) * 60*24 etime_mins ,
             sum(DELTA_INTERCONNECT_IO_BYTES)/(1024*1024) interconnect_mb,
             sum(nvl(delta_write_io_bytes, 0) + nvl(delta_read_io_bytes, 0))/(1024*1024)   phys_total_mb,
             sum(delta_read_io_bytes)/(1024*1024)  phys_read_mb,
             sum(delta_write_io_bytes)/(1024*1024)  phys_write_mb,
             max(temp_space_allocated)/(1024*1024) max_temp_mb,
             max(pga_allocated)/(1024*1024) max_pga_mb
from dba_hist_active_sess_history ASH 
WHERE
     ASH.session_type = 'FOREGROUND'
and ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and ASH.sql_exec_start >  trunc(sysdate - &DAYS_AGO, 'DD') 
and  ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
group by  ASH.instance_number, ASH.user_id, ASH.session_id, ASH.session_serial#, ASH.sql_opname, ASH.module, ASH.top_level_sql_id, ASH.sql_id,  ASH.sql_exec_id, ASH.SQL_PLAN_HASH_VALUE, ASH.in_hard_parse, sql_exec_start
order by ash.sql_exec_start;

prompt 
prompt summing db time per wait class
prompt

column wait_userio_sum format 999,999
column wait_systemio_sum format 999,999
column wait_concurrency_sum format 999,999
column wait_admin_sum format 999,999
column wait_commit_sum format 999,999
column wait_app_sum format 999,999
column wait_config_sum format 999,999
column wait_cluster_sum format 999,999
column  wait_network_sum format 999,999
column wait_other_sum format 999,999  

with sub1 as 
(
select 
     sql_id,
     sql_exec_id,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'User I/O' then 1 else 0 END as wait_userio,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'System I/O' then 1 else 0 END as wait_systemio,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'Concurrency' then 1 else 0 END as wait_concurrency,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'Administrative' then 1 else 0 END as wait_admin,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'Commit' then 1 else 0 END as wait_commit,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'Application' then 1 else 0 END as wait_application,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'Configuration' then 1 else 0 END as wait_config,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'Cluster' then 1 else 0 END as wait_cluster,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'Network' then 1 else 0 END as wait_network,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and wait_class = 'Other' then 1 else 0 END as wait_other,     
     CASE  WHEN session_type = 'FOREGROUND' AND session_state = 'WAITING'  then 1 else 0 END as waiting_sess ,
     CASE  WHEN session_type = 'FOREGROUND' and session_state = 'ON CPU'  then 1 else 0 END as cpu_sess
from dba_hist_active_sess_history ASH
WHERE ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
and ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and ASH.sql_exec_start >  trunc(sysdate - &DAYS_AGO, 'DD') 
and ASH.session_type = 'FOREGROUND'
)
select 
          sub1.sql_id,
          sub1.sql_exec_id,
          sum(sub1.wait_userio) wait_userio_sum,
          sum(sub1.wait_systemio) wait_systemio_sum,
          sum(sub1.wait_concurrency) wait_concurrency_sum,
          sum(sub1.wait_admin) wait_admin_sum,
          sum(sub1.wait_commit) wait_commit_sum,
          sum(sub1.wait_application) wait_app_sum,
          sum(sub1.wait_config) wait_config_sum,
          sum(sub1.wait_cluster) wait_cluster_sum,
          sum(sub1.wait_network) wait_network_sum,
          sum(sub1.wait_other) wait_other_sum,
           '|' as " " ,
          sum(sub1.cpu_sess) cpu_sum
from sub1
group by sub1.sql_id, sub1.sql_exec_id;


prompt
prompt And the sum of the events :
prompt



with pivot1 as
(
select 
     sql_id,
     sql_exec_id,
     CASE WHEN session_state = 'WAITING' THEN event ELSE 'ON CPU' end as db_event
from dba_hist_active_sess_history ASH
WHERE ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
and ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and ASH.sql_exec_start >   trunc(sysdate - &DAYS_AGO, 'DD') 
and ASH.session_type = 'FOREGROUND'
),
pivot2 as 
(select sql_id,
       sql_exec_id,
       db_event,
       count(*) total_waits
from pivot1
group by sql_id,sql_exec_id, db_event
)
select pivot2.*, 
       total_waits*100/(sum(total_waits) over ()) wait_pct,
       (sum(total_waits) over ())*10 as total_time_approx_sec
from pivot2
order by wait_pct desc;

prompt 
prompt 
prompt Session Events for &SQL_ID/&SQL_EXEC_ID (from ASH)
prompt

select /*+ noindex(ash) full(ASH@SEL$2) use_hash(ASH@SEL$2) parallel(4) */ event, count(*), sum(time_waited)/1000 time_waited_ms, sum(time_waited)/count(*)/1000 average_wait_ms, max(time_waited)/1000 max_wait_ms
from dba_hist_active_sess_history ASH
WHERE ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
and ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and ASH.sql_exec_start >   trunc(sysdate - &DAYS_AGO, 'DD') 
and session_state = 'WAITING'
AND SESSION_TYPE = 'FOREGROUND'
group by event
order by time_waited_ms desc;

prompt
prompt IO report, Broken down by plan line :
prompt

column object_name format A30
column phys_total_mb format 999,999,999,999
column phys_read_io format 999,999,999,999
column sql_exec_id format 999999999999
column sql_plan_line_id format 9999999999
column etime_secs format 999,999,999
column phys_read_mb format 999,999,999
column phys_write_mb format 999,999,999
column sql_plan_options format A30
column sql_plan_operation format A30
column all_phys_mb format 999,999,999


with pivot1 as
(
SELECT SQL_ID, sql_EXEC_ID, sql_plan_line_id,  sql_plan_operation,  sql_plan_options,
	(CAST(MAX(sample_time)  AS DATE) - CAST(  min(sample_time) AS DATE)) * 3600*24 etime_secs,  
	count(*) wait_count, 
	sum(delta_read_io_requests) phys_read_io, 
	sum(nvl(DELTA_READ_IO_BYTES,0))/(1024*1024) phys_read_mb, 
	sum(nvl(DELTA_WRITE_IO_BYTES,0))/(1024*1024) phys_write_mb
from dba_hist_active_sess_history ASH
WHERE ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
and ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and ASH.sql_exec_start >  trunc(sysdate - &DAYS_AGO, 'DD') 
  GROUP BY  sQL_ID, sql_EXEC_ID, sql_plan_line_id, sql_plan_options, sql_plan_operation
order by sql_plan_line_id
) 
select pivot1.*, sum(phys_write_mb + phys_read_mb) over () phys_total_mb
from pivot1;



prompt
prompt Now show the plan operations for the same period :
prompt




select sql_id,
       sql_exec_id, 
 sql_plan_hash_value,
        sql_plan_line_id,
        sql_plan_operation,
      sql_plan_options,
    decode(session_state, 'ON CPU', 'CPU', event) event,
      count(*) num_waits,
      OBJECT_NAME, SUBOBJECT_NAME,
	sum(DELTA_READ_IO_BYTES)/(1024*1024) phys_read_mb, 
	sum(DELTA_WRITE_IO_BYTES)/(1024*1024) phys_write_mb,
  MAX(temp_space_allocated)/1024/1024 temp_used_mb, 
  min(sample_time) start_time,
  max(sample_time) end_time, 
  (CAST(MAX(sample_time)  AS DATE) - CAST(  min(sample_time) AS DATE)) * 3600*24 etime_secs
from   dba_hist_active_sess_history ASH
LEFT OUTER JOIN DBA_OBJECTS DA on da.object_id = ASH.current_obj#
where  sql_id = '&SQL_ID' and    sql_exec_id = &SQL_EXEC_ID
and    session_type = 'FOREGROUND'
and ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and ASH.sql_exec_start >  trunc(sysdate - &DAYS_AGO, 'DD') 
group by sql_id, sql_exec_id, sql_plan_hash_value, sql_plan_operation, sql_plan_line_id, sql_plan_options,  decode(session_state, 'ON CPU', 'CPU', event), OBJECT_NAME,SUBOBJECT_NAME
order by sql_plan_line_id, COUNT(*) DESC ;




prompt
prompt Any blocking issues 
prompt



select blocking_inst_id, blocking_session, blocking_session_serial#, count(*)
from   dba_hist_active_sess_history ASH
where sql_id = '&SQL_ID'  and sql_exec_id =   &SQL_EXEC_ID
and    session_type = 'FOREGROUND'
and ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and blocking_session is not null
group by blocking_inst_id, blocking_session, blocking_session_serial#;


prompt
prompt Physical IO usage :
prompt

SELECT
  sql_id,
  sql_exec_id,
  sql_exec_start,
  TRUNC(SUM(NVL(delta_write_io_bytes, 0) + NVL(delta_read_io_bytes,0  ))/(1024*1024*1024), 1 ) phys_total_gb
FROM
  dba_hist_active_sess_history ASH
WHERE
     ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and ASH.sql_exec_start >  trunc(sysdate - &DAYS_AGO, 'DD') 
  and sql_id = '&SQL_ID'
and sql_exec_id = &SQL_EXEC_ID
GROUP BY
  sql_id,
  sql_exec_id,
  sql_exec_start;

prompt
prompt And the tablespace  usage :
prompt

column ts_read_mb format 999,999,999,999
column ts_write_mb format 999,999,999,999


with pivot1 as
(
select /*+ noindex(ash) full(ASH@SEL$2) use_hash(ASH@SEL$2) parallel(4)  */         DDF.tablespace_name  ,
    current_file#, delta_read_io_bytes, delta_write_io_bytes
from dba_hist_active_sess_history ash
left outer join dba_data_files DDF on DDF.file_id = ASH.current_file#
where  sql_id = '&SQL_ID' and    sql_exec_id = &SQL_EXEC_ID
and    session_type = 'FOREGROUND'
and ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and ASH.sql_exec_start >  trunc(sysdate - &DAYS_AGO, 'DD') 
)
select tablespace_name, sum(delta_read_io_bytes)/(1024*1024) ts_read_mb, sum(delta_write_io_bytes)/(1024*1024) ts_write_mb
from pivot1
group by tablespace_name;





