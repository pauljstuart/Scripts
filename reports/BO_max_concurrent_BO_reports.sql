


-- BO reports running per instance :


with pivot1 as
(
select distinct inst_id, sql_id, sql_exec_id, sql_exec_start
from gv$session 
where     SCHEMANAME IN (  'APP_BO_ONSHORE','APP_BO')
and status = 'ACTIVE'
AND SQL_ID IS NOT NULL AND SQL_EXEC_ID IS NOT NULL
)
select inst_id, count(*)
from pivot1
group by inst_id
order by inst_id;


-- BO reports running right now :

select distinct sql_id, sql_exec_id, sql_exec_start
from gv$session 
where     SCHEMANAME IN (  'APP_BO_ONSHORE','APP_BO')
and status = 'ACTIVE'
AND SQL_ID IS NOT NULL AND SQL_EXEC_ID IS NOT NULL;


-- BO reports, summed over 1 minute interval, then getting max over 15 minute interval :

column  sample_15min format A21
column max_concurrent_bo_reports format 999,999


--set sqlformat csv
with 
pivot1 as
( 
select   distinct
     to_char(sample_time, 'DD-MM-YYYY HH24:') ||
       (case WHEN  extract( minute from sample_time) < 15 THEN '00'
             WHEN  extract( minute from sample_time) < 30 THEN '15'
             WHEN  extract( minute from sample_time) < 45 THEN '30'
             WHEN  extract( minute from sample_time) < 60 THEN '45'
             END) sample_15min,
  trunc(sample_time, 'MI') sample_min,
   ash.user_id,
   ash.sql_id,
   ash.sql_exec_id,
   ash.sql_exec_start,
   ash.module
from
        dba_hist_active_sess_history ash
where
      snap_id > (select min(snap_id)  from dba_hist_snapshot where begin_interval_time > trunc(sysdate - &DAYS_AGO, 'DD') AND  dbid = (select dbid from v$database))
 --  and ash.session_state = 'WAITING'
   AND ash.session_type = 'FOREGROUND'
   and (module like 'busobj%' or module like 'boe%')
  and sql_id is not null and sql_exec_id is not null
  and trunc(sample_time, 'DD') not like 'SUN%'
 and trunc(sample_time, 'DD') not like 'SAT%'
  --and trunc(sample_time, 'MI') = '07-JUN-16 14:42'
),
permin_summary as
(
select  sample_min, sample_15min, count(*) minute_count
from pivot1
group by sample_min, sample_15min
order by sample_min
)
select sample_15min, max(minute_count) max_concurrent_bo_reports
from permin_summary
group by sample_15min
order by to_date(sample_15min, 'DD-MM-YYYY HH24:MI');


prompt
prompt daily BO reports
prompt


set sqlformat default
with 
pivot1 as
( 
select   distinct
  trunc(sample_time, 'DD') sample_day,
   ash.user_id,
   ash.sql_id,
   ash.sql_exec_id,
   ash.sql_exec_start,
   ash.module
from
        dba_hist_active_sess_history ash
where
      snap_id > (select min(snap_id)  from dba_hist_snapshot where begin_interval_time > trunc(sysdate - &DAYS_AGO, 'DD') AND  dbid = (select dbid from v$database))
 --  and ash.session_state = 'WAITING'
   AND ash.session_type = 'FOREGROUND'
   and (module like 'busobj%' or module like 'boe%')
  and sql_id is not null and sql_exec_id is not null
  --and trunc(sample_time, 'MI') = '07-JUN-16 14:42'
)
select sample_day, count(*) daily_bo_reports
from pivot1
group by sample_day
order by 1;
