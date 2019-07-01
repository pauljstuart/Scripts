

define SQL_ID=&1


prompt
prompt Looking back &DAYS_AGO days
prompt 
prompt Looking for : &SQL_ID
prompt


WITH 
pivot2 as
(
SELECT   
     ASH.instance_number as inst_id,  
     (select username from dba_users where ash.user_id = user_id ) as username, 
      ASH.session_id sid, 
      ASH.session_serial# serial#, 
      ASH.sql_opname,
      ASH.module,
      program,
      ASH.in_hard_parse, 
    --  ASH.top_level_sql_id, 
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
             max(temp_space_allocated)/(1024*1024) max_temp_mb,
             max(pga_allocated)/(1024*1024) max_pga_mb,
             min(snap_id), max(snap_id)
from dba_hist_active_sess_history ASH
WHERE  
     session_type = 'FOREGROUND'
and  sql_id in  &SQL_ID
and sql_exec_id is not null
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
group by  ASH.instance_number, ASH.user_id, ASH.session_id,ash.program, ASH.session_serial#, ASH.sql_opname, ASH.module, ASH.sql_id,  ASH.sql_exec_id, ASH.SQL_PLAN_HASH_VALUE, ASH.in_hard_parse, sql_exec_start
)
select SM.* 
 -- 	,regexp_replace(dbms_LOB.substr(sql_text, 14, dbms_lob.getlength(sql_text) -14 ), '[[:cntrl:]]',null) sql_end
from pivot2 SM 
--left outer join dba_hist_sqltext DHST on DHST.sql_id = SM.sql_id   
order by sql_start_time, sql_end_time ;


/*
select * from pivot2
where sql_start_time < to_date('27-05-2015 00:00', 'DD-MM-YYYY hh24:mi')
and sql_end_time > to_date('27-05-2015 01:30', 'DD-MM-YYYY hh24:mi');
order by sql_start_time, sql_end_time 
*/



/*
WITH 
pivot1 as
(
select min(snap_id) AS begin_snap_id
from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
),
pivot2 as
(
SELECT   
     ASH.instance_number, 
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
            MIN(sample_time) sql_start_time, 
            MAX(sample_time) sql_end_time, 
             ((CAST(MAX(sample_time)  AS DATE)) - (CAST(MIN(sample_time) AS DATE))) * (3600*24) etime_secs ,
             ((CAST(MAX(sample_time)  AS DATE)) - (CAST(MIN(sample_time) AS DATE))) * (60*24) etime_mins ,
             sum(delta_read_io_bytes)/(1024*1024)  read_io_mb,
             sum(delta_write_io_bytes)/(1024*1024) write_io_mb,
             (sum(delta_write_io_bytes) + sum(delta_read_io_bytes))/(1024*1024) total_io_mB,
             sum(DELTA_INTERCONNECT_IO_BYTES)/(1024*1024) interconnect_mb,
             max(temp_space_allocated)/(1024*1024) max_temp_mb,
             max(pga_allocated)/(1024*1024) max_pga_mb
from dba_hist_active_sess_history ASH
WHERE  
     session_type = 'FOREGROUND'
and   sql_id is not null
and  sql_id in  &SQL_ID 
and     snap_id > (select begin_snap_id from pivot1)
group by  ASH.instance_number, ASH.user_id, ASH.session_id, ASH.session_serial#, ASH.top_level_sql_id, ASH.sql_id, ASH.sql_opname, ASH.sql_exec_id, ASH.SQL_PLAN_HASH_VALUE, ASH.in_hard_parse, ASH.module
)
select * from pivot2;
--where sql_start_time < to_date('20-05-2014 13:50', 'DD-MM-YYYY hh24:mi')
--and sql_end_time > to_date('20-05-2014 13:50', 'DD-MM-YYYY hh24:mi');
*/



-- fancy one, selecting snap_ids and sql from sqltext :

/*

WITH 
pivot1 AS
(
SELECT snap_id FROM dba_hist_snapshot where begin_interval_time > sysdate - 7
),  
pivot2 AS
(
SELECT sql_id FROM dba_hist_sqltext
WHERE sql_text LIKE '%parallel(8)%'
)
SELECT ASH.sql_id, ASH.sql_exec_id,ASH.sql_plan_hash_value, ASH.sql_exec_start,  MAX(ASH.sample_time) sql_end_time, 
        ((CAST(MAX(ASH.sample_time)  AS DATE)) - (CAST(ASH.sql_exec_start AS DATE))) * (3600*24) duration_secs ,
        max(temp_space_allocated)/(1024*1024) max_temp_mb
from dba_hist_active_sess_history ASH
WHERE  
     ASH.session_type = 'FOREGROUND'
AND ASH.session_state = 'WAITING'
--and  ASH.sample_time >  TO_DATE ('1/01/2013 02:05', 'dd/mm/yyyy hh24:mi:ss') 
--AND ASH.sample_time < TO_DATE ('18/01/2013 09:55', 'dd/mm/yyyy hh24:mi:ss') 
and     ASH.snap_id in (select snap_id from pivot1)
and  ASH.sql_id in (select sql_id from pivot2)
group by ASH.sql_id, ASH.sql_exec_id, ASH.sql_plan_hash_value,ASH.sql_exec_start
order by 4 asc;

*/

