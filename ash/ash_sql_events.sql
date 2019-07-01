-- here is the Session event report 

column event format A40
column time_waited_ms format 999,999.9
column average_wait_ms format 999,999.9
column max_wait_ms format 999,999.9

define SQL_ID=&1
define SQL_EXEC_ID=&2

prompt
prompt Session Events for &SQL_ID/&SQL_EXEC_ID
prompt


select /*+ parallel(4) */ 
     (case when session_state = 'WAITING' THEN EVENT ELSE 'ON CPU' END), count(*) as event, sum(time_waited)/1000 time_waited_ms, sum(time_waited)/count(*)/1000 average_wait_ms, max(time_waited)/1000 max_wait_ms
from gv$active_session_history
where sql_id = '&SQL_ID' and sql_exec_id = &SQL_EXEC_ID
and user_id = (select user_id from dba_users where username = user)
--and session_state = 'WAITING'
AND SESSION_TYPE = 'FOREGROUND'
and sample_time > sysdate - 3/24
group by (case when session_state = 'WAITING' THEN EVENT ELSE 'ON CPU' END)
order by count(*) desc;
