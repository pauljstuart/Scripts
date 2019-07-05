

--
-- set commandline defaults
--

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



COLUMN buffer_gets FORMAT 999,999,999,999
COLUMN sql_text FORMAT A200 TRUNCATE
COLUMN current_workarea_mem_mb  FORMAT 999,999,999  
COLUMN current_temp_mb FORMAT 999,999,999
COLUMN max_temp_mb  FORMAT 999,999,999
COLUMN max_workarea_mem_mb FORMAT 999,999,999
COLUMN sql_exec_start FORMAT A20
COLUMN total_buffers FORMAT 999,999,999,999
COLUMN TOTAL_PHYS_READ_MB FORMAT 999,999,999,999
COLUMN TOTAL_PHYS_WRITE_MB FORMAT 999,999,999,999
COLUMN rows_processed FORMAT 999,999,999,999
column status format A20
column total_etime_mins format 999,999,999
column px_instances format A20
column px_sessions format 999,999
column mb_sec format 999,999.9
COLUMN  PX_SERVERS_REQUESTED format 99,999
column  PX_SERVERS_ALLOCATED format 99,999



WITH
  sql_monitor_plan_summary AS
  (
    SELECT
      sql_id,
      sql_exec_id,
      sql_exec_start,
      SUM(workarea_mem)        /(1024*1024) current_workarea_mem_mb ,
      SUM(workarea_tempseg)    /(1024*1024) current_temp_mb ,
      SUM(workarea_max_tempseg)/(1024*1024) max_temp_mb,
      SUM(workarea_max_mem)    /(1024*1024) max_workarea_mem_mb,
      SUM(output_rows) rows_processed
    FROM
      gv$sql_plan_monitor
    WHERE
      sql_id LIKE '&SQL_ID'  AND status like '&STATUS'
    GROUP BY
      sql_id,
      sql_exec_id,
      sql_exec_start
  )
  ,
  sql_monitor_summary AS
  (
    SELECT
      sql_id,
      sql_exec_id,
      sql_exec_start,
      SUM(buffer_gets)                      total_buffers,
      SUM(physical_read_bytes) /(1024*1024) total_phys_read_mb,
      SUM(physical_write_bytes)/(1024*1024) total_phys_write_mb,
      COUNT(px_server#)                     px_servers,
      ( max(last_refresh_time) - min(first_refresh_time) )*60*24 total_etime_mins, 
      LISTAGG(inst_id) WITHIN GROUP (ORDER BY inst_id) as px_instances
    FROM
      gv$sql_monitor
    WHERE
     sql_id LIKE '&SQL_ID'  AND status like '&STATUS'
    GROUP BY
      sql_id,
      sql_exec_id,
       sql_exec_start
  )
SELECT
  SM.username,
 (select COMMAND_NAME from v$sqlcommand where command_type = SQL.command_TYPE) SQL_OPNAME,
  SM.status,
  SM.sql_id,
  SM.sql_exec_id,
  SM.sql_exec_start,
  SM.sql_plan_hash_value,
  SM.program,
  SM.module,            
                      total_buffers,
                      total_phys_read_mb,
                     total_phys_write_mb,
                     total_etime_mins,
'|' as div,
   px_instances,
  px_servers px_sessions,
  SM.PX_SERVERS_REQUESTED ,
  PX_SERVERS_ALLOCATED,
 '|' as div,
    SPS.current_temp_mb ,
  SPS.max_temp_mb,
  SPS.current_workarea_mem_mb, 
  SPS.max_workarea_mem_mb,
  SPS.rows_processed,  
--  decode( total_etime_mins, 0, 0, total_phys_read_mb/(total_etime_mins*60) ) MB_sec,
regexp_replace( substr(SQL.sql_text, 0, 100), '[[:space:]]+', ' ') sql_text  
FROM
      gv$sql_monitor SM
INNER  JOIN      sql_monitor_summary SMS on   SMS.sql_id = SM.sql_id and SM.sql_exec_id = SMS.sql_exec_id and SM.sql_exec_start = SMS.sql_exec_start
LEFT OUTER JOIN      sql_monitor_plan_summary SPS on   SM.sql_id = SPS.sql_id and SM.sql_exec_id = SPS.sql_exec_id and  SM.sql_exec_start = SPS.sql_exec_start
LEFT OUTER JOIN gv$sql SQL      ON         SM.sql_child_address = SQL.child_address AND SM.inst_id = SQL.inst_id
WHERE      
     (SM.process_name = 'ora' or SM.process_name like 'j%')
AND   (SM.username like '&USERNAME' or SM.module like '&USERNAME')
AND SM.sql_id like '&SQL_ID'
AND SM.status like '&STATUS'
order by sql_exec_start;






