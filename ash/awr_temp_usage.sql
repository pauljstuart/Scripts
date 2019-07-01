


--  sum of max temp, per temp tablespace, summed per minute :

column sum_max_mb format 999,999,999.9;
COLUMN sample_time FORMAT A20
COLUMN sum_max_mb FORMAT 999,999,999.9;
COLUMN total_temp_permin_mb FORMAT 999,999,999,999.9

define DAYS_AGO=1
define MIN_USAGE=1

with 
pivot2 as
(  
SELECT
   trunc(ash.sample_time,'MI') sample_time,
   ash.SESSION_ID,
   ash.SESSION_SERIAL#,
   ash.SQL_ID,
   ash.sql_exec_id,
   U.temporary_tablespace,
  max(temp_space_allocated)/(1024*1024) max_temp_per_sql_mb
from
        dba_hist_active_sess_history ash
INNER JOIN dba_users U ON ash.user_id = U.user_id
where
        ash.session_type = 'FOREGROUND'
   and ash.temp_space_allocated > 0
  -- and U.temporary_tablespace = 'TEMP3'
and ASH.snap_id  >= (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  <= (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
 group by  
      trunc(ash.sample_time,'MI') ,
   ash.SESSION_ID,
   ash.SESSION_SERIAL#,
   ash.SQL_ID,
   ash.sql_exec_id,
   U.temporary_tablespace
   )
select temporary_tablespace, sample_time, sum(max_temp_per_sql_mb) total_temp_permin_mb
from pivot2
group by temporary_tablespace, sample_time
order by temporary_tablespace, sample_time;


-- temp usage per tablespace, summed per 30sec


column temp_mb format 999,999,999.9
with 
pivot1 as
( 
select   
     to_char(sample_time, 'DD-MM-YYYY HH24:MI') ||   ':' ||
       (case WHEN  extract( second from sample_time) < 30 THEN '00'
             WHEN  extract( second from sample_time) < 60 THEN '30'
             END) sec_period,
   ash.sql_id,
   ash.sql_exec_id,
   ash.temp_space_allocated,
   DU.temporary_tablespace
from
        dba_hist_active_sess_history ash
INNER JOIN dba_users DU ON ash.user_id = DU.user_id
where
      snap_id > 97628 
   and ash.session_state = 'WAITING'
   AND ash.session_type = 'FOREGROUND'
   and ash.temp_space_allocated > 0
   and DU.temporary_tablespace = 'TEMP3'
   ),
pivot2 as
(
select sec_period, sql_id, sql_exec_id, temporary_tablespace, max(temp_space_allocated) max_temp_per_sql
from pivot1
group by sec_period, sql_id, sql_exec_id, temporary_tablespace
)
select temporary_tablespace, sec_period, sum(max_temp_per_sql)/(1024*1024) temp_mb
from pivot2
group by temporary_tablespace, sec_period
order by temporary_tablespace, sec_period;


-- temp space usage from dba_hist_tbspc_space_usage


define days_ago=14
column temp_used_mb format 999,999,999.9;
column temp_ts_maxsize_mb format 999,999,999.9;
column temp_ts_size_mb format 999,999,999.9;
column end_interval_time format A21
WITH 
pivot1 as
(
select min(snap_id) AS begin_snap_id
from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
),
pivot2 AS
(
select value/(1024*1024) as block_size_mb from v$parameter where name = 'db_block_size' 
)
select HH.snap_id, SS.end_interval_time, 
             tablespace_size*(select block_size_mb from pivot2) temp_ts_size_mb,
            tablespace_maxsize*(select block_size_mb from pivot2) temp_ts_maxsize_mb,
          tablespace_usedsize*(select block_size_mb from pivot2)  temp_used_mb
from 
DBA_HIST_TBSPC_SPACE_USAGE HH
inner join dba_hist_snapshot SS on SS.snap_id = HH.snap_id  and instance_number = (select instance_number from v$instance)
where HH.snap_id > (select begin_snap_id from pivot1)
and tablespace_id = (select ts# from v$tablespace where name = 'TEMP3' )
order by HH.snap_id;



-- temp space usage from dbs_hist_tempstatxs


column writes_mb format 999,999,999
column blk_writes_mb format 999,999,999
column begin_interval_time format A21

WITH 
pivot3 as
(
select snap_id, instance_number, file#,
             tsname, block_size/(1024*1024) block_size_mb, 
             phywrts,
             phyblkwrt - lag( phyblkwrt, 1)  over (partition by  instance_number, file# order by snap_id )  result1
from 
dba_hist_tempstatxs HH
where tsname = 'TEMP1'
and dbid = (select dbid from v$database)
)
select HH.snap_id,  tsname, begin_interval_time,
   sum(result1)*block_size_mb blk_writes_mb
from pivot3  HH
inner join dba_hist_snapshot SS on SS.snap_id = HH.snap_id  and SS.instance_number = (select instance_number from v$instance)
group by HH.snap_id,  tsname, block_size_mb, begin_interval_time
order by snap_id;

-- max temp usage per tablespace per day, calculated using 1 min periods 



column max_temp_per_day_mb format 999,999,999;
column temp_ts_max_size_mb format 999,999,999;
column temp_mb format 999,999,999.9
define DAYS_AGO=6
with 
pivot1 as
(
select min(snap_id) AS begin_snap_id
from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
),
pivot2 as
(  
SELECT
   trunc(ash.sample_time,'MI') sample_time,
   ash.SESSION_ID,
   ash.SESSION_SERIAL#,
   ash.SQL_ID,
   ash.sql_exec_id,
   U.temporary_tablespace,
  max(temp_space_allocated)/(1024*1024) max_temp_per_sql_mb
from
        dba_hist_active_sess_history ash
INNER JOIN dba_users U ON ash.user_id = U.user_id
where
        ash.session_type = 'FOREGROUND'
   and ash.temp_space_allocated > 0
  -- and U.temporary_tablespace = 'TEMP3'
   and snap_id > (select begin_snap_id from pivot1)
 group by  
      trunc(ash.sample_time,'MI') ,
   ash.SESSION_ID,
   ash.SESSION_SERIAL#,
   ash.SQL_ID,
   ash.sql_exec_id,
   U.temporary_tablespace
   ),
pivot3 as
(
select temporary_tablespace, sample_time, sum(max_temp_per_sql_mb) total_temp_permin_mb
from pivot2
group by temporary_tablespace, sample_time
order by temporary_tablespace, sample_time
)
select temporary_tablespace, DD.tablespace_size/(1024*1024) temp_ts_max_size_mb, trunc(sample_time, 'DD') as day,  max(total_temp_permin_mb) max_temp_per_day_mb
from pivot3
inner join dba_temp_free_space DD ON DD.tablespace_name = pivot3.temporary_tablespace
group by  temporary_tablespace,  DD.tablespace_size/(1024*1024) , trunc(sample_time, 'DD')
--having trunc(sec_date, 'DD') > to_date('01-11-13', 'DD-MM-YY')
order by temporary_tablespace, day;


/*


-- showing sql running at a point in time with AWR, sumnming temp usage too, per temp tablespace

column module format A30
column sql_opname format A20
column module format A30
column sql_opname format A20
COLUMN tempsum_per_tablespace_mb FORMAT 999,999,999
COLUMN temp_used_mb FORMAT 999,999,999
with pivot1 as
(
SELECT ASH.user_id, ASH.module, ASH.sql_id, ASH.sql_opname,ASH.sql_exec_id,ASH.sql_plan_hash_value, 
        ASH.sql_exec_start,
        MIN(ASH.sample_time) sql_start_time,   
        MAX(ASH.sample_time) sql_end_time, 
        ((CAST(MAX(ASH.sample_time)  AS DATE)) - (CAST(min(ASH.sample_time) AS DATE))) * (3600*24) duration_secs ,
        max(temp_space_allocated)/(1024*1024) temp_used_mb
from dba_hist_active_sess_history ASH
WHERE  
     ASH.session_type = 'FOREGROUND'
AND ASH.session_state = 'WAITING' 
and     ASH.snap_id > 97539
and     ASH.sql_exec_id is not null
group by  ASH.user_id, ASH.module, ASH.sql_id, ASH.sql_opname, ASH.sql_exec_id, ASH.sql_plan_hash_value, ASH.sql_exec_start
)
select T1.username , module, sql_id, sql_opname,sql_exec_id,sql_plan_hash_value,  sql_start_time,   sql_end_time, T1.temporary_tablespace, temp_used_mb, sum(temp_used_mb) over ( partition by T1.temporary_tablespace) tempsum_per_tablespace_mb
from pivot1 P
inner join dba_users T1 on T1.user_id = P.user_id 
where sql_start_time < TO_DATE ('12/12/2013 12:23', 'dd/mm/yyyy HH24:MI')
and   sql_end_time > TO_DATE ('12/12/2013 12:23', 'dd/mm/yyyy HH24:MI') ;

*/


-- an experimental temp query which also sums any temp tablespace io events :


with pivot1 as
(select ASH.*,
        CASE when event in  ('direct path read temp', 'direct path write temp' ) then 1 else 0 end as temp_events
from dba_hist_active_sess_history ASH
WHERE  
     ASH.session_type = 'FOREGROUND'
AND ASH.session_state = 'WAITING'
and   ASH.snap_id between 6919 and 6938
)
SELECT ASH.sql_id, ASH.sql_exec_id,ASH.sql_plan_hash_value, ASH.sql_exec_start,  MAX(ASH.sample_time) sql_end_time, 
        ((CAST(MAX(ASH.sample_time)  AS DATE)) - (CAST(ASH.sql_exec_start AS DATE))) * (3600*24) duration_secs ,
        max(temp_space_allocated)/(1024*1024) max_temp_mem_mb,
        sum(temp_events) 
from pivot1 ASH
group by ASH.sql_id, ASH.sql_exec_id, ASH.sql_plan_hash_value,ASH.sql_exec_start
order by 4 asc;




--
-- A mighty query to find temp space usage :
--

define START_TIME='28/12/2012 01:19';
define   END_TIME='28/12/2012 07:58';


with pre_table as 
( SELECT *
FROM   dba_hist_active_sess_history
WHERE  dbid = (SELECT dbid
               FROM   v$database)
       AND snap_id IN (SELECT snap_id
                       FROM   dba_hist_snapshot
                       WHERE  dbid = (SELECT dbid
                                      FROM   v$database)
                              AND begin_interval_time BETWEEN To_date('&START_TIME', 'dd/mm/yyyy hh24:mi')
                                  AND To_date('&END_TIME', 'dd/mm/yyyy hh24:mi'))
)
 SELECT *
FROM   (SELECT Rank()
                 over (
                   ORDER BY SUM(Nvl(temp_space_delta, 0)) DESC) position,
               sql_id,
               sql_plan_hash_value,
               sql_plan_operation,
               sql_plan_line_id,
               Count(DISTINCT sql_exec_id)                      total_execs,
               Trunc(SUM(Nvl(temp_space_delta, 0)) / 1024 / 1024) temp_usage_mb
        FROM   (SELECT sql_exec_id,
                       sql_id,
                       sql_plan_hash_value,
                       sql_plan_operation,
                       sql_plan_line_id,
                       temp_space_allocated - Nvl(Lag(temp_space_allocated, 1)
                       over (
                         PARTITION BY sql_exec_id, sql_id
                         ORDER BY sample_id), 0)
                       temp_space_delta
                FROM   pre_table)
        GROUP  BY sql_id,
                  sql_plan_operation,
                  sql_plan_hash_value,
                  sql_plan_line_id)
WHERE  position <= 10
ORDER  BY position;               
                
