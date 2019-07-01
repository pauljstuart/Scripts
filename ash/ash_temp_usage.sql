


-- temp space usage, per minute

col P1 new_value 1 format A10
col P2 new_value 2 format A10


select null p1, null p2 from dual where 1=2;
select nvl( '&1','%') p1, nvl('&2','%') p2 from dual ;

define TEMP_NAME=&1  

undefine 1
undefine 2

column temp_sum_gb format 999,999,999;
column temporary_tablespace format A20
column sample_time format A20

WITH
pivot1 AS
(
SELECT
   trunc(ash.sample_time,'MI') sample_time,
   ash.inst_id, 
   ash.SESSION_ID,
   ash.SESSION_SERIAL#,
   ash.SQL_ID,
   ash.sql_exec_id,
   ash.sql_exec_start,
   temporary_tablespace,
  max(temp_space_allocated)/(1024*1024*1024) max_temp_gb
FROM  GV$ACTIVE_SESSION_HISTORY ash
inner join dba_users DU on DU.user_id = ASH.user_id
WHERE
       ash.session_type = 'FOREGROUND'
and ash.temp_space_allocated > 0
and  temporary_tablespace like '&TEMP_NAME'
GROUP BY
  trunc(ash.sample_time,'MI'),
  ash.inst_id, 
  ash.SESSION_ID,
  ash.SESSION_SERIAL#,
  ash.SQL_ID,
  ash.sql_exec_id,
  ash.sql_exec_start,
  temporary_tablespace
)
SELECT  temporary_tablespace, sample_time, sum(max_temp_gb) temp_sum_gb
from pivot1
GROUP BY sample_time, temporary_tablespace
ORDER BY 1,2 ;



/*


-- new temp query, looking at each SQL active during each minute


column total_temp_mb format 999,999,999,999
column sql_start_time format A21

define PATTERN=TEMP2
with pivot2 as
(
SELECT   
     ASH.inst_id, 
     ASH.user_id, 
      ASH.session_id sid, 
      ASH.session_serial# serial#, 
      ASH.sql_opname,
      ASH.module,
      ASH.top_level_sql_id, 
      ASH.sql_id, 
      ASH.sql_exec_id,
      ASH.SQL_PLAN_HASH_VALUE,
      ASH.in_hard_parse, 
      NVL(ASH.sql_exec_start, min(sample_time)) sql_start_time, 
            MAX(sample_time) sql_end_time, 
             (CAST(MAX(sample_time)  AS DATE) - CAST( NVL(ASH.sql_exec_start, min(sample_time)) AS DATE)) * 3600*24 etime_secs ,
             (CAST(MAX(sample_time)  AS DATE) - CAST( NVL(ASH.sql_exec_start, min(sample_time)) AS DATE)) * 60*24 etime_mins ,
             max(temp_space_allocated)/(1024*1024) max_temp_mb,
             max(pga_allocated)/(1024*1024) max_pga_mb         
from gv$active_session_history ASH
inner join dba_users DU  on DU.user_id = ASH.user_id 
WHERE  
     ASH.session_type = 'FOREGROUND'
and  ASH.sql_id is not null
and  DU.temporary_tablespace = 'TEMP1'
and ASH.temp_space_allocated > 0
group by  ASH.inst_id, ASH.user_id, ASH.session_id, ASH.session_serial#, ASH.sql_opname, ASH.module, ASH.top_level_sql_id, ASH.sql_id,  ASH.sql_exec_id, ASH.SQL_PLAN_HASH_VALUE, ASH.in_hard_parse, sql_exec_start
) 
select  BB.sql_start_time,  ( select sum(max_temp_mb) from pivot2 AA where AA.sql_start_time < BB.sql_start_time  AND  BB.sql_start_time <=  AA.sql_end_time ) as total_temp_mb
from (select distinct trunc(sql_start_time, 'MI') sql_start_time from pivot2 ) BB
order by 1;





-- summing temp usage per tablespace, summed per 15 sec interval 


column temp_mb format 999,999,999
column max_size_mb format 999,999,999
column temporary_tablespace format A10
with 
pivot1 as
( 
select   
     to_char(sample_time, 'DD-MM-YYYY HH24:MI') ||   ':' ||
       (case WHEN  extract( second from sample_time) < 15 THEN '00'
             WHEN  extract( second from sample_time) < 30 THEN '15'
             WHEN  extract( second from sample_time) < 45 THEN '30'
             WHEN  extract( second from sample_time) < 60 THEN '45'
             END) sec_period,
   ash.session_id,
   ash.session_serial#,
   ash.sql_id,
   ash.sql_exec_id,
   ash.temp_space_allocated,
   DU.temporary_tablespace
from
        gv$active_session_history ash
INNER JOIN dba_users DU ON ash.user_id = DU.user_id
where
 xxxx      ash.session_state = 'WAITING'
   AND ash.session_type = 'FOREGROUND'
   and ash.temp_space_allocated > 0
--   and DU.temporary_tablespace = 'TEMP3'
   ),
pivot2 as
(
select sec_period, session_id, session_serial#, sql_id, sql_exec_id, temporary_tablespace, max(temp_space_allocated) max_temp_per_sql_op
from pivot1
group by sec_period, session_id, session_serial#, sql_id, sql_exec_id, temporary_tablespace
)
select temporary_tablespace, DD.tablespace_size/(1024*1024) max_size_mb, sec_period, sum(max_temp_per_sql_op)/(1024*1024) temp_mb
from pivot2
inner join dba_temp_free_space DD ON DD.tablespace_name = pivot2.temporary_tablespace
GROUP BY  temporary_tablespace,  DD.tablespace_size/(1024*1024), sec_period
order by temporary_tablespace, sec_period;



-- summing temp usage per meridian run :


column total_io_mb format 999,999,999
column largest_sql_temp_mb format 999,999,999
column total_run_temp_mb format 999,999,999
column meridian_run format A10
column duration_mins format 999,999
column run_start format A20
column run_end format A20

with
pivot1 as
(
select top_level_sql_id, sql_id, sql_exec_id, 
       replace( regexp_substr( module, '([^_]+)_' ), '_', '')  Meridian_run,
       MIN(ASH.sample_time) start_time, 
       MAX(ASH.sample_time) end_time, 
       sum(delta_write_io_bytes)/(1024*1024) written_io_mb, 
       max(temp_space_allocated)/(1024*1024) max_sql_temp_mb
from gv$active_session_history ASH
where session_state = 'WAITING' 
and session_type = 'FOREGROUND'
--and snap_id > 36220
and  user_id = 50
group by ash.top_level_sql_id,ash.sql_id, ash.sql_exec_id,  replace( regexp_substr( module, '([^_]+)_' ), '_', '')
)
select Meridian_run, min(start_time) run_start, max(end_time) run_end, 
   (CAST(MAX(end_time) as DATE) - (CAST(MIN(start_time) AS DATE))) * (60*24) duration_mins ,
    sum(written_io_mb) total_io_mb,
    max( max_sql_temp_mb) largest_sql_temp_mb,
    sum(max_sql_temp_mb) total_run_temp_mb
from pivot1
where meridian_run is not null and meridian_run not in ( 'null', 'compression', '<unknown>')
group by meridian_run
order by min(start_time);


-- summing temp usage per 




-- A mighty Meridian query for temp usage, that includes the unknown and compression sqls


COLUMN table_name format A30;
column run_total_io_mb format 999,999,999
column run_total_temp_mb format 999,999,999
column meridian_run format A10
column duration_mins format 999,999



WITH tom1 AS
(
SELECT sample_time, 
       replace( regexp_substr( module, '([^_]+)_' ), '_', '')  Meridian_run, 
           lag(sample_time) OVER (ORDER BY sample_time), sample_time - lag(sample_time) OVER (ORDER BY sample_time) ,
           CASE WHEN sample_time - lag(sample_time) OVER (ORDER BY sample_time)  >  TO_DSINTERVAL('000 00:05:00')  THEN row_number() OVER (ORDER BY sample_time)
                    when row_number() over (order by sample_time) = 1 then 1
                            else null
                    END rn
      from gv$active_session_history T
      where session_type = 'FOREGROUND'
      and client_id in ('MERIDIAN', 'meridian')
),
tom2 AS
(
SELECT sample_time, MAX(rn) OVER (ORDER BY sample_time) AS date_range_id
from tom1
),
tom3 as
(
SELECT date_range_id, 
        MIN(sample_time) range_start, 
         MAX(sample_time) range_end
FROM tom2
GROUP BY date_range_id
order by min(sample_time)
),
pivot1 as
(
select sql_id, sql_exec_id, 
--       replace( regexp_substr( module, '([^_]+)_' ), '_', '')  Meridian_run,
       MIN(ASH.sample_time) start_time, 
       MAX(ASH.sample_time) end_time, 
       sum(delta_write_io_bytes)/(1024*1024) sql_io_written_mb, 
       max(temp_space_allocated)/(1024*1024) sql_temp_mb
from gv$active_session_history ASH
where 
  session_type = 'FOREGROUND'
--session_state = 'WAITING' 
and  client_id in ('MERIDIAN', 'meridian')
group by ash.sql_id, ash.sql_exec_id
),
join_pivot as
(
select tom3.*,
      pivot1.*
from pivot1 
inner join tom3 on pivot1.start_time between tom3.range_start and tom3.range_end
)
select join_pivot.range_start, join_pivot.range_end,
        (CAST(join_pivot.range_end as DATE) - CAST(join_pivot.range_start AS DATE)) * (60*24) duration_mins ,
    sum(join_pivot.sql_io_written_mb) run_total_io_mb,
    sum(join_pivot.sql_temp_mb)         run_total_temp_mb
from join_pivot
group by join_pivot.range_start, join_pivot.range_end
having  (CAST(join_pivot.range_end as DATE) - CAST(join_pivot.range_start AS DATE)) * (60*24)  > 2;


*/
