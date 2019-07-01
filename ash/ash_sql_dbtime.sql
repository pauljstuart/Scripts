



define SQL_ID=&1
define SQL_EXEC_ID=&2




column sql_plan_line_id format 999,999
column ALL_PHYS_MB format 999,999,999
column temp_used_mb format 999,999,999
column db_time_secs format 999,999,999
column phys_total_gb format 999,999,999
column sql_plan_operation format A15
column sql_plan_options format A15
column event format A30
column object_name format a30
column start_time format A20
column end_time format A20


COLUMN wait_pct FORMAT 999.9;
COLUMN total_time_approx_sec FORMAT 999,999;
COLUMN db_event format A30

COLUMN phys_total_mb format   999,999,999,999
column phys_read_mb format    999,999,999,999
column phys_write_mb format   999,999,999,999
column interconnect_mb format 999,999,999,999
COLUMN max_temp_mb FORMAT     999,999,999,999
COLUMN max_pga_mb FORMAT      999,999,999,999
COLUMN SQL_TEXT format A100
column   BLOCKING_INST_ID format 999,999
column  BLOCKING_SESSION  format 999,999              
column "BLOCKING_SESSION_SERIAL#"  format 999,999


prompt =========================================================================================================================================================================================================

prompt 
prompt SQL database time for  SQL_ID  : &SQL_ID	  SQL_EXEC_ID :	&SQL_EXEC_ID
prompt


PROMPT
prompt top level summary
prompt

column  px_start_time format A20
column  px_end_time format A20
column px_interconnect_mb format 999,999,999,999
column px_phys_total_mb format 999,999,999,999
column px_phys_read_mb format 999,999,999,999
column px_phys_write_mb format 999,999,999,999
column  px_temp_mb format 999,999,999,999
column  px_pga_mb format 999,999,999,999
column parallel_deg format 999
COLUMN SQL_TEXT format A100
column parallel_deg format 999
COLUMN PX_ETIME_MINS FORMAT 999,999
COLUMN PX_ETIME_secs FORMAT 999,999,999
column  PX_READ_IO_REQUESTS   format 999,999,999,999                 
column PX_WRITE_IO_REQUESTS format 999,999,999,999
column parallel_instances format A20


with pivot2 as 
(
select  
      inst_id,
      user_id, 
     session_id,
     session_serial#,
      sql_opname,
      module,
      sql_id, 
      sql_exec_id,
      SQL_PLAN_HASH_VALUE,
      sql_exec_start , 
      MAX(ash.sample_time) sql_end_time, 
             (CAST(MAX(sample_time)  AS DATE) - CAST( SQL_EXEC_START AS DATE)) * 3600*24 etime_secs ,
       (CAST(MAX(sample_time)  AS DATE) - CAST( SQL_EXEC_START AS DATE)) * 60*24 etime_mins ,
       sum(DELTA_INTERCONNECT_IO_BYTES)/(1024*1024) interconnect_mb,
	     sum(nvl(delta_write_io_bytes, 0) + nvl(delta_read_io_bytes, 0))/(1024*1024)   phys_total_mb,
	     sum(delta_read_io_bytes)/(1024*1024)  phys_read_mb,
       sum(delta_write_io_bytes)/(1024*1024)  phys_write_mb,
                    sum(DELTA_READ_IO_REQUESTS) read_io_requests,
                    sum(DELTA_WRITE_IO_REQUESTS) write_io_requests,
       max(temp_space_allocated)/(1024*1024) max_temp_mb,
             max(pga_allocated)/(1024*1024) max_pga_mb,
      row_number() over ( order by sql_exec_start  desc) as start_rank
from gv$active_session_history ASH
WHERE  
     session_type = 'FOREGROUND'
and  ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
group by  inst_id, user_id, session_id, session_serial#, sql_opname, module,  sql_id,  sql_exec_id, SQL_PLAN_HASH_VALUE, sql_exec_start
)
select
      (select username from dba_users where SM.user_id = user_id ) as username, 
      sql_opname,
      SM.sql_id, 
      sql_exec_id,
      SQL_PLAN_HASH_VALUE,
      SM.module,
      count(*)-1 parallel_deg,
 lpad(  LISTAGG(SM.inst_id, '') WITHIN GROUP (ORDER BY SM.inst_id) , 20) as parallel_instances,
      sql_exec_start as px_start_time, 
      max(sql_end_time) as px_end_time,
      max(etime_mins) px_etime_mins,
    sum(   phys_total_mb ) px_phys_total_mb,
    sum(  phys_read_mb ) px_phys_read_mb,
    sum(phys_write_mb )  px_phys_write_mb,
    sum(max_temp_mb)   px_temp_mb
from pivot2 SM    
group by SM.user_id, SM.sql_opname, SM.module, SM.sql_id, SM.sql_exec_id, SM.sql_plan_hash_value, SM.sql_exec_start
order by sql_exec_start
/



prompt
prompt ASH session level  summary :
prompt

SELECT   
     ASH.inst_id, 
     ASH.user_id, 
      ASH.session_id sid, 
      ASH.session_serial# serial#, 
      ASH.top_level_sql_id, 
      ASH.sql_id, 
      ASH.sql_exec_id,
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
from gv$active_session_history ASH 
WHERE
     ASH.session_type = 'FOREGROUND'
and  ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
group by  ASH.inst_id , ASH.user_id, ASH.session_id, ASH.session_serial#, ASH.sql_opname, ASH.module, ASH.top_level_sql_id, ASH.sql_id,  ASH.sql_exec_id, ASH.SQL_PLAN_HASH_VALUE, ASH.in_hard_parse, sql_exec_start;


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
from gv$active_session_history ASH
WHERE ASH.sql_id = '&SQL_ID'
and   ASH.sql_exec_id = &SQL_EXEC_ID 
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

COLUMN wait_pct FORMAT 999.9;
COLUMN total_time_approx_sec FORMAT 999,999;
COLUMN db_event format A30
column total_waits format 999,999

with pivot1 as
(
select 
     sql_id,
     sql_exec_id,
     CASE WHEN session_state = 'WAITING' THEN event ELSE 'ON CPU' end as db_event
from gv$active_session_history ASH
WHERE ASH.sql_id = '&SQL_ID'
and   ASH.sql_exec_id = &SQL_EXEC_ID
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
       (sum(total_waits) over ()) as total_time_approx_sec
from pivot2
order by wait_pct desc;



column event format A40
column time_waited_ms format 999,999,999.9
column average_wait_ms format 999,999.9
column max_wait_ms format 999,999.9







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
from gv$active_session_history ASH
WHERE ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
GROUP BY  sQL_ID, sql_EXEC_ID, sql_plan_line_id, sql_plan_options, sql_plan_operation
order by sql_plan_line_id
) 
select pivot1.*, sum(phys_write_mb + phys_read_mb) over () phys_total_mb
from pivot1;



prompt
prompt Plan operations detail :
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
from   gv$active_session_history ASH
LEFT OUTER JOIN DBA_OBJECTS DA on da.object_id = ASH.current_obj#
where  sql_id = '&SQL_ID' and    sql_exec_id = &SQL_EXEC_ID
and    session_type = 'FOREGROUND'
group by sql_id, sql_exec_id, sql_plan_hash_value, sql_plan_operation, sql_plan_line_id, sql_plan_options,  decode(session_state, 'ON CPU', 'CPU', event), OBJECT_NAME, SUBOBJECT_NAME
order by sql_plan_line_id, COUNT(*) DESC ;






prompt
prompt Any blocking issues 
prompt



select blocking_inst_id, blocking_session, blocking_session_serial#, count(*)
from gv$active_session_history where sql_id = '&SQL_ID'  and sql_exec_id =   &SQL_EXEC_ID
and blocking_session is not null
group by blocking_inst_id, blocking_session, blocking_session_serial#;


prompt
prompt any child SQL for &SQL_ID:
prompt

select distinct inst_id, top_level_sql_id,  sql_id, count(*)
from gv$active_session_history ASH
where top_level_sql_id = '&SQL_ID'
group by inst_id, top_level_sql_id, sql_id;



prompt
prompt Physical IO usage :
prompt


SELECT
  sql_id,
  sql_exec_id,
  sql_exec_start,
  TRUNC(SUM(NVL(delta_write_io_bytes, 0) + NVL(delta_read_io_bytes,0  ))/(1024*1024*1024), 1 ) phys_total_gb
FROM
  GV$active_session_history  AWR
WHERE
     sql_id = '&SQL_ID'
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
from gv$active_session_history ash
left outer join dba_data_files DDF on DDF.file_id = ASH.current_file#
where  sql_id = '&SQL_ID' and    sql_exec_id = &SQL_EXEC_ID
and    session_type = 'FOREGROUND'
)
select tablespace_name, sum(delta_read_io_bytes)/(1024*1024) ts_read_mb, sum(delta_write_io_bytes)/(1024*1024) ts_write_mb
from pivot1
group by tablespace_name;



/*
prompt
prompt most recent events from ASH for &SQL_ID  &SQL_EXEC_ID 
prompt 

column session_serial# format 99999
column top_level_call_name format A20
column action format A20
column client_id format A20
column machine  format A20

select * from
(
SELECT sample_time, session_id, session_serial#, program, module, action, machine, sql_id, sql_exec_id, in_hard_parse, top_level_sql_id, sql_opname, sql_exec_start,  sql_plan_hash_value, SQL_PLAN_LINE_ID, sql_plan_operation, sql_plan_options, session_state, event as wait_event, blocking_inst_id, blocking_session, blocking_session_serial#, object_name,
         row_number() over (order by sample_id desc) as sample_order
from gv$active_session_history ASH
left outer join dba_objects DA on DA.object_id = AsH.current_obj#
where sql_id = '&SQL_ID'
and sql_exec_id = &SQL_EXEC_ID
)
where sample_order < 50
order by sample_order desc; 

*/

prompt
prompt 
prompt Session Events for &SQL_ID/&SQL_EXEC_ID (from ASH)
prompt

select /*+ parallel(4) */ event, count(*), sum(time_waited)/1000 time_waited_ms, sum(time_waited)/count(*)/1000 average_wait_ms, max(time_waited)/1000 max_wait_ms
from gv$active_session_history
where sql_id = '&SQL_ID' and sql_exec_id = &SQL_EXEC_ID
and session_state = 'WAITING'
AND SESSION_TYPE = 'FOREGROUND'
group by event
order by time_waited_ms desc;

prompt
prompt objects accessed in the last 5 mins
prompt

select sql_id,
       sql_exec_id, 
      OBJECT_NAME, SUBOBJECT_NAME,
  sql_plan_line_id,
    decode(session_state, 'ON CPU', 'CPU', event) event,
	sum(DELTA_READ_IO_BYTES)/(1024*1024) phys_read_mb, 
	sum(DELTA_WRITE_IO_BYTES)/(1024*1024) phys_write_mb,
  count(*) num_waits
from   gv$active_session_history ASH
LEFT OUTER JOIN DBA_OBJECTS DA on da.object_id = ASH.current_obj#
where  sql_id = '&SQL_ID' and    sql_exec_id = &SQL_EXEC_ID
and    session_type = 'FOREGROUND'
and sample_time > sysdate -5/60/24
group by sql_id, sql_exec_id,sql_plan_line_id, decode(session_state, 'ON CPU', 'CPU', event), OBJECT_NAME, SUBOBJECT_NAME
order by COUNT(*) DESC ;



prompt
prompt Any current waits from v$session :
prompt

column wait_class format A15
column event format A30
column seconds_in_wait format 999,999,999
column P1TEXT format A15
column P1  format A15
column P2TEXT format A15
column P2  format A15
column P3TEXT format A15
column P3 format A15
column "ROW_WAIT_OBJ#" format 99999999
column FINAL_BLOCKING_INSTANCE format 99999
column FINAL_BLOCKING_SESSION format 999999
column BLOCKING_INSTANCE format 99999
column BLOCKING_SESSION format 999999


SELECT
  inst_id,
  sid,
  serial#,
  username,
  S.status,
  sql_id,
  sql_exec_id,
  wait_class,
  SEQ# ,
  EVENT,
  seconds_in_wait,
  program,
  command,
  sql_exec_start,
  BLOCKING_INSTANCE,
  BLOCKING_SESSION ,
  FINAL_BLOCKING_INSTANCE,
  FINAL_BLOCKING_SESSION ,
  P1TEXT,
  P1,
  P2TEXT ,
  P2,
  P3TEXT,
  P3,
  ROW_WAIT_OBJ# ,
  DO.object_name
FROM
  gv$session S
LEFT OUTER JOIN dba_objects DO
ON
  DO.object_id = S.ROW_WAIT_OBJ#
WHERE
  sql_id        = '&SQL_ID'
AND sql_exec_id = &SQL_EXEC_ID
order by status;
