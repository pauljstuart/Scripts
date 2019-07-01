

define SQL_ID=&1
define SQL_EXEC_ID=&2

column time_waited_ms format 999,999.9
column average_wait_ms format 999,999.9
column max_wait_ms format 999,999.9

with pivot1 as
(
select 
     sql_id,
     sql_exec_id,
     CASE WHEN session_state = 'WAITING' THEN event ELSE 'ON CPU' end as db_event
from dba_hist_active_sess_history ASH
WHERE ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
and ASH.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and ASH.session_type = 'FOREGROUND'
),
pivot2 as 
(select sql_id,
       sql_exec_id,
       db_event,
       count(*) total_waits
from pivot1
group by sql_id,sql_exec_id, db_event
)
select pivot2.*, 
       total_waits*100/(sum(total_waits) over ()) wait_pct,
       (sum(total_waits) over ())*10 as total_time_approx_sec
from pivot2
order by wait_pct desc;

prompt 
prompt 
prompt Session Events for &SQL_ID/&SQL_EXEC_ID (from ASH)
prompt

select /*+ parallel(4) */ event, count(*), sum(time_waited)/1000 time_waited_ms, sum(time_waited)/count(*)/1000 average_wait_ms, max(time_waited)/1000 max_wait_ms
from dba_hist_active_sess_history ASH
WHERE ASH.sql_id = '&SQL_ID' and   ASH.sql_exec_id = &SQL_EXEC_ID
and ASH.snap_id  >= (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and ASH.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and session_state = 'WAITING'
AND SESSION_TYPE = 'FOREGROUND'
group by event
order by time_waited_ms desc;
