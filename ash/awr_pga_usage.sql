----------------------------------------------------------------------------
-- pga usage per minute

COLUMN total_pga_permin_mb FORMAT 999,999,999,999.9
column sample_min format A20
	
with 
pivot2 as
(  
SELECT
   trunc(ash.sample_time,'MI') sample_min,
  ash.instance_number as inst_id	, 
   ash.SESSION_ID,
   ash.SESSION_SERIAL#,
   ash.SQL_ID,
   ash.sql_exec_id,
  ash.sql_exec_start,
  max(pga_allocated)/(1024*1024) max_pga_per_sql_mb
from
        dba_hist_active_sess_history ash
where
        ash.session_type = 'FOREGROUND'
   and ash.pga_allocated > 0
   and snap_id > (select min(snap_id) AS begin_snap_id from dba_hist_snapshot  where begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD'))
 group by  
      trunc(ash.sample_time,'MI') ,
    instance_number, 
   ash.SESSION_ID,
   ash.SESSION_SERIAL#,
   ash.SQL_ID,
   ash.sql_exec_id,
   ash.sql_exec_start
   )
--select * from pivot2 where sample_min = '14/07/2016 17:03:00'
--select * from pivot2 where sample_min = 'SAT 18/06/2016 08:35:00';
select  inst_id, sample_min, sum(max_pga_per_sql_mb) total_pga_permin_mb
from pivot2
group by  inst_id, sample_min
order by inst_id, sample_min;
