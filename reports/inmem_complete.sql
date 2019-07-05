

-- report to show all the inmemory queries which have completed :

column identifier format A10
column inmemory_query format A10
column report_id format A10
column hint format A10


column total_px_phys_read_mb format 999,999,999
column  total_px_phys_write_mb format 999,999,999

WITH
  sql_monitor_summary AS
  (
    SELECT
      sql_id,
      sql_exec_id,
      SUM(buffer_gets)                      total_px_buffers,
      SUM(physical_read_bytes) /(1024*1024) total_px_phys_read_mb,
      SUM(physical_write_bytes)/(1024*1024) total_px_phys_write_mb,
      COUNT(px_server#)                     total_px_servers,
      ( max(last_refresh_time) - min(first_refresh_time) )*60*24 px_etime_mins
    FROM
      gv$sql_monitor
  --  WHERE
   --   sql_id LIKE 'SQL_ID'
    GROUP BY
      sql_id,
      sql_exec_id
  )
SELECT
regexp_replace(SM.module, '([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)', '\4') as report_id, 
regexp_replace(SM.module, '([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)', '\2') as inmemory_query, 
regexp_replace(SM.module, '([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)', '\3') as hint, 
  SM.sql_id,
  SM.sql_exec_id,
  SM.sql_exec_start,
  SMS.px_etime_mins etime_mins,
  SM.sql_plan_hash_value, 
  SMS.total_px_phys_read_mb,
  SMS.total_px_phys_write_mb,
  regexp_replace(SM.module, '([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)', '\1') as identifier,
  SM.status
FROM
  gv$sql_monitor SM
left outer JOIN sql_monitor_summary SMS  on   SM.sql_id = SMS.sql_id and SM.sql_exec_id = SMS.sql_exec_id
WHERE     
          SM.status like 'DONE%'
-- SM.status = 'DONE (ALL ROWS)'
and        (SM.process_name = 'ora' or SM.process_name like 'j%')
and      SM.module like 'PJS%'
and       SM.elapsed_time > 0
ORDER BY   SM.inst_id, SM.sql_exec_start;

