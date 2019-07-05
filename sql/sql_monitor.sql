

prompt
prompt =====================================
prompt




column P_USER new_value 1 format A10
column P_SQL_ID new_value 2 format A10
column P_STATUS new_value 3 format A10

select null P_USER, null P_SQL_ID, null P_STATUS from dual where 1=2;
select nvl( '&1','&_USER') P_USER, nvl('&2','%') P_SQL_ID, nvl('&3','EXECUTING') P_STATUS from dual ;


define USERNAME=&1
define SQL_ID=&2     
define STATUS=&3

undefine 1
undefine 2
undefine 3


@P:\Documents\PJS\scripts\ash\ash_aas_now.sql

prompt

@P:\Documents\PJS\scripts\sess\session_wait.sql


prompt
prompt V$PX_PROCESS :
prompt



SELECT
  inst_id,
  status,
  COUNT(*)
FROM
  gv$px_process
GROUP BY
  inst_id,
  status
ORDER BY
  1;


--break on sql_id skip page duplicates

column sum_rows format 999,999,999,999,999
column px_buffer_gets format 999,999,999,999
column px_phys_read_blocks format 999,999,999
column ETIME_MIN format 999,999.9
column max_mem_mb format 999,999,999.9
column max_temp_mb format 999,999,999,999.9

with sql_monitor_plan_summary as
(
select inst_id,  sql_id, sql_exec_id, process_name, sql_exec_start, sql_plan_hash_value, sum(output_rows) sum_rows, sum(workarea_max_mem)/(1024*1024) max_mem_mb, max(workarea_max_tempseg)/(1024*1024) max_temp_mb
from gv$sql_plan_monitor
where sql_id like '&SQL_ID' and status like '&STATUS'
group by inst_id, sql_id, sql_exec_id, process_name, sql_exec_start, sql_plan_hash_value
)
select     SM.username,
  DECODE(SQL.command_type, 1,'CRE TAB', 2,'INSERT', 3,'SELECT', 6,'UPDATE', 7,'DELETE', 9,'CRE INDEX', 12,'DROP TABLE', 15,'ALT TABLE',39,'CRE TBLSPC', 42, 'DDL', 44,'COMMIT', 45,'ROLLBACK', 47,'PL/SQL EXEC', 48,'SET XACTN', 62, 'ANALYZE TAB', 63,'ANALYZE IX', 71,'CREATE MLOG', 74,'CREATE SNAP',79, 'ALTER ROLE', 85,'TRUNC TAB' ) COMMAND,
  SM.status, 
  SM.sql_id, 
  SM.sql_exec_id,
  SM.sql_exec_start,  
  SM.sql_plan_hash_value,
  SM.program,
  SM.module,
  SM.inst_id, 
     SM.process_name, 
     SM.sid, 
  SM.session_serial# serial#, 
     SM.elapsed_time/1000000/60 etime_min, 
     SM.buffer_gets px_buffer_gets , 
      SM.physical_read_bytes/(1024*1024) phys_read_mb,
      SM.physical_write_bytes/(1024*1024) phys_write_mb,
     SP.sum_rows, 
     SP.max_mem_mb, 
     SP.max_temp_mb
from gv$sql_monitor SM
left outer join sql_monitor_plan_summary SP  on  SM.inst_id = SP.inst_id and SM.sql_id = SP.sql_id and SM.sql_exec_id = SP.sql_exec_id and SM.process_name = SP.process_name
LEFT OUTER JOIN gv$sql SQL      ON         SM.sql_child_address = SQL.child_address AND SM.inst_id = SQL.inst_id
WHERE      SM.sql_id like '&SQL_ID'
AND        SM.status like '&STATUS'
AND   ( SM.inst_id, SM.sid) in (SELECT     inst_id, sid FROM  gv$session  WHERE   username like '&USERNAME' )
and       SM.elapsed_time > 0
order by sql_id, process_name;





clear breaks;
