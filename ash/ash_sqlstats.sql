

define SQL_ID=&1



prompt
prompt ASH SQL : &SQL_ID
prompt
prompt



with pivot2 as
(
SELECT   
     ASH.inst_id, 
    (select username from dba_users where ash.user_id = user_id ) as username,  
      ASH.session_id sid, 
      ASH.session_serial# serial#, 
      ASH.sql_opname,
      ASH.module,
      ASH.in_hard_parse,       
      ASH.top_level_sql_id, 
      ASH.sql_id, 
      ASH.sql_exec_id,
      ASH.SQL_PLAN_HASH_VALUE,
      NVL(ASH.sql_exec_start, min(sample_time)) sql_start_time, 
            MAX(sample_time) sql_end_time, 
             (CAST(MAX(sample_time)  AS DATE) - CAST( NVL(ASH.sql_exec_start, min(sample_time)) AS DATE)) * 3600*24 etime_secs ,
             (CAST(MAX(sample_time)  AS DATE) - CAST( NVL(ASH.sql_exec_start, min(sample_time)) AS DATE)) * 60*24 etime_mins ,
             sum(DELTA_INTERCONNECT_IO_BYTES)/(1024*1024) interconnect_mb,
             sum(nvl(delta_write_io_bytes, 0) + nvl(delta_read_io_bytes, 0))/(1024*1024)   phys_total_mb,
             sum(delta_read_io_bytes)/(1024*1024)  phys_read_mb,
             sum(delta_write_io_bytes)/(1024*1024)  phys_write_mb,
             sum(DELTA_READ_IO_REQUESTS) read_io_requests,
             sum(DELTA_WRITE_IO_REQUESTS) write_io_requests,
             max(temp_space_allocated)/(1024*1024) max_temp_mb,
             max(pga_allocated)/(1024*1024) max_pga_mb
from gv$active_session_history ASH
WHERE  
     ASH.session_type = 'FOREGROUND'
and  ASH.sql_id in &SQL_ID
-- and inst_id = 2
--and session_id in ( 2275)
--and sample_time > to_date('05-04-2017 15:40', 'DD-MM-YYYY HH24:MI')'
--and top_level_sql_id = '2074gqdz4z2y2'
group by  ASH.inst_id, ASH.user_id, ASH.session_id, ASH.session_serial#, ASH.sql_opname, ASH.module,  ASH.sql_id, ash.top_level_sql_id, ASH.sql_exec_id, ASH.SQL_PLAN_HASH_VALUE, ASH.in_hard_parse, sql_exec_start
) 
select SM.*
from pivot2 SM
order by sql_start_time;






/*


---- finding sql based on run times

SELECT * FROM 
(
SELECT inst_id,
       sql_id,
     sql_exec_id,
      user_id,
      to_char(sql_exec_start, 'dd/mm/yyyy hh24:mi:ss') start_time,
      max(to_char(sample_Time, 'dd/mm/yyyy hh24:mi:ss')) end_time,
      round(((cast(max(sample_time)  As Date)) - (cast(sql_exec_start as date))) * (3600*24),2) secs,
      max(temp_space)
FROM   gv$active_session_history
WHERE  sql_exec_id IS NOT NULL
AND sql_exec_start > to_date('05-06-2013 04:37', 'DD-MM-YYYY HH24:MI')
AND sql_exec_start < to_date('05-06-2013 06:03', 'DD-MM-YYYY HH24:MI')
AND session_type = 'FOREGROUND'
and inst_id = 6
GROUP BY inst_id, sql_id, sql_exec_Id, user_id, sql_exec_start
ORDER BY start_time, end_time
)
WHERE secs > 15;



--------------------------------------------
-- or combined with a search on the sql text :
--------------------------------------------

ALTER SESSION SET  nls_date_format='dd/mm/yyyy hh24:mi:ss';

WITH pivot1 AS
(
SELECT sql_id FROM dba_hist_sqltext
WHERE sql_text LIKE '%DATA_PROCESSING_STATISTICS%'
)
SELECT ASH.sql_id, ASH.sql_exec_id,ASH.sql_plan_hash_value, ASH.sql_exec_start,  MAX(ASH.sample_time) sql_end_time, round(((CAST(MAX(ASH.sample_time)  AS DATE)) - (CAST(ASH.sql_exec_start AS DATE))) * (3600*24),2) duration_secs 
from gv$active_session_history ASH
where  
    ASH.session_type = 'FOREGROUND'
AND ash.session_state = 'WAITING'
AND  ASH.sql_id IN ( select sql_id from pivot1 )
AND ash.sql_plan_hash_value != 0
and ash.sql_exec_id is not null
GROUP BY ASH.sql_id, ASH.sql_exec_id, ASH.sql_plan_hash_value,ASH.sql_exec_start
order by 4 asc;


*/


undefine 1

