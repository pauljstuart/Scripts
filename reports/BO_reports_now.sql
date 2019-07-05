


-- get all BO reports running, using v$session

column sql_id format A13
column bo_user format A10
column px_start_time format A20
column oracle_username format A15
column report_name format A50
column elapsed_time_mins format 999,999,999
column total_phys_IO_gb format 999,999,999,999
column parallel_deg format 999
column instances_list format A20 


WITH
 sql_monitor_summary AS
  (
    SELECT
      sql_id,
      sql_exec_id,
      sql_exec_start,
      SUM(buffer_gets)                      total_px_buffers,
      SUM(physical_read_bytes+physical_write_bytes) /(1024*1024) total_px_phys_IO_mb,
      COUNT(px_server#)                     total_px_servers,
      ( max(last_refresh_time) - min(first_refresh_time) )*60*24 px_etime_mins
    FROM
      gv$sql_monitor
    WHERE status = 'EXECUTING'
    GROUP BY
      sql_id,
      sql_exec_id,
      sql_exec_start
  ),
pivot2 as
(
select 
      username, 
      sql_id, 
      sql_exec_id,
      sql_exec_start , 
     count(*) as parallel_deg,
      LISTAGG(inst_id, ',') WITHIN GROUP (ORDER BY inst_id) parallel_instances,
      (trunc(sysdate, 'MI') - trunc(SQL_EXEC_START, 'MI')) * 60*24 etime_mins 
from gv$session
WHERE  
     sql_id is not null AND  SQL_EXEC_ID IS NOT NULL
and command = 3
and  username  LIKE '%BO%'
and status = 'ACTIVE'
group by    username, sql_id,  sql_exec_id, sql_exec_start
order by sql_exec_start
)
select distinct
      username as oracle_username,
      regexp_substr( dbms_LOB.substr(sql_fulltext, 300, dbms_lob.getlength(sql_fulltext) - 300) ,q'#AppUserName='([a-z]+)',.*#', 1,1,'i', 1) as BO_user,
      regexp_substr( dbms_LOB.substr(sql_fulltext, 300, dbms_lob.getlength(sql_fulltext) - 300) ,q'#AppName='(.*)',AppUserName.*#', 1,1,'i', 1) as report_name,
      SM.sql_id, 
      SM.sql_exec_id, 
      parallel_deg,
     lpad(parallel_instances, 20) as instances_list,
      SM.sql_exec_start as px_start_time,
      etime_mins elapsed_time_mins,
     total_px_phys_IO_mb/1024 total_phys_IO_gb
from pivot2 SM 
left outer join GV$SQLAREA DHST on DHST.sql_id = SM.sql_id
left outer join sql_monitor_summary SMS on  SMS.sql_id = SM.sql_id and SMS.sql_exec_id = SM.sql_exec_id and SMS.sql_exec_start = SM.sql_exec_start 
order by SM.sql_exec_start 
/


with
pivot2 as
(
select 
      username, 
      sql_id, 
      sql_exec_id,
      sql_exec_start , 
     count(*) as parallel_deg,
      LISTAGG(inst_id, ',') WITHIN GROUP (ORDER BY inst_id) parallel_instances,
      (trunc(sysdate, 'MI') - trunc(SQL_EXEC_START, 'MI')) * 60*24 etime_mins 
from gv$session
WHERE  
     sql_id is not null AND  SQL_EXEC_ID IS NOT NULL
and command = 3
and  username  LIKE '%BO%'
and status = 'ACTIVE'
group by    username, sql_id,  sql_exec_id, sql_exec_start
order by sql_exec_start
)
select distinct
      username as oracle_username,
      regexp_substr( dbms_LOB.substr(sql_fulltext, 300, dbms_lob.getlength(sql_fulltext) - 300) ,q'#AppUserName='([a-z]+)',.*#', 1,1,'i', 1) as BO_user,
      regexp_substr( dbms_LOB.substr(sql_fulltext, 300, dbms_lob.getlength(sql_fulltext) - 300) ,q'#AppName='(.*)',AppUserName.*#', 1,1,'i', 1) as report_name
from pivot2 SM 
left outer join GV$SQLAREA DHST on DHST.sql_id = SM.sql_id
order by 2;
