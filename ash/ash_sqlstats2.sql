
   
define SQL_ID=&1



COLUMN SQL_TEXT format A100



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
AND  SQL_EXEC_ID IS NOT NULL
and  sql_id  in &SQL_ID
--and sql_opname = 'INSERT'
--and module LIKE 'load_pnl_signoff%'
--and sample_time > sysdate -1/24
--and session_id = 3424
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
      max(etime_secs) px_etime_secs,
    sum( interconnect_mb) px_interconnect_mb,
    sum(   phys_total_mb ) px_phys_total_mb,
    sum(  phys_read_mb ) px_phys_read_mb,
    sum(phys_write_mb )  px_phys_write_mb,
                 sum(read_io_requests) px_read_io_requests,
                 sum(write_io_requests) px_write_io_requests,
    sum(max_temp_mb)   px_temp_mb, 
    sum(max_pga_mb)   px_pga_mb,
    regexp_replace( substr(sql_text, 0, 300), '[[:space:]]+', ' ') sql_text
from pivot2 SM 
 left outer join GV$SQLAREA DHST on DHST.sql_id = SM.sql_id   and DHST.inst_id = SM.inst_id
group by SM.user_id, SM.sql_opname, SM.module, SM.sql_id, SM.sql_exec_id, SM.sql_plan_hash_value, SM.sql_exec_start,  regexp_replace( substr(sql_text, 0, 300), '[[:space:]]+', ' ')
order by sql_exec_start
/

