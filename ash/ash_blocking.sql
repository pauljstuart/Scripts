

-- summing from AWR based on blocking session/sid

SELECT snap_id, MIN(sample_time) blocking_starts, event, wait_class, count(*) AS num_waiting_sessions, BLOCKING_SESSION,BLOCKING_SESSION_SERIAL#,
CASE WHEN EVENT = 'enq: TM - contention' THEN (SELECT object_NAME FROM DBA_OBJECTS WHERE OBJECT_ID = current_obj#)
     WHEN EVENT = 'enq: TX - row lock contention' THEN (SELECT object_NAME FROM DBA_OBJECTS WHERE OBJECT_ID = CURRENT_OBJ#) 
     ELSE NULL END  AS BLOCKING_OBJECT
FROM dba_hist_active_sess_history ASH
WHERE sample_time >  TO_DATE ('&START_TIME', 'dd/mm/yyyy hh24:MI') 
AND sample_time < TO_DATE ('&END_TIME', 'dd/mm/yyyy hh24:MI') 
AND session_type = 'FOREGROUND'
AND session_state = 'WAITING'
AND wait_class = 'Application'
GROUP BY snap_id, event, wait_class, BLOCKING_SESSION,BLOCKING_SESSION_SERIAL#, P2, CURRENT_OBJ#
ORDER BY 1
;




-- finding current blockers, waiters and objects using ASH

Column waiting_sid FORMAT 9999 heading  trunc
COLUMN waiting_sql FORMAT A70  Trunc
COLUMN locked_object FORMAT 99999999999999999999 
COLUMN filler Heading " " FORMAT A50
COLUMN blocking_sid FORMAT 9999 
COLUMN sql_from_blocking_session  FORMAT A70  trunc

select distinct
	waiter.sid waiting_sid, 
    w_sql.sql_text waiting_sql, 
    waiter.ROW_WAIT_OBJ# locked_object,
     ' ' Filler, 
    waiter.BLOCKING_SESSION blocking_sid, 
    b_sql.sql_text 			sql_from_blocking_session
from v$session waiter, v$active_session_history blocker, v$sql b_sql, v$sql w_sql
where waiter.event='library cache lock'
and waiter.sql_id=w_sql.sql_id
and waiter.blocking_session=blocker.session_id
and b_sql.sql_id=blocker.sql_id
and blocker.CURRENT_OBJ#=waiter.ROW_WAIT_OBJ#
and blocker.CURRENT_FILE#= waiter.ROW_WAIT_FILE#
and blocker.CURRENT_BLOCK#= waiter.ROW_WAIT_BLOCK#


----------------------------------------------------------------------------------------------------------
-- finding historical blockers and objects using ASH (my query).  This one joins on the sample second :


define START_TIME='13/01/2017 06:00';
define   END_TIME='13/01/2017 11:00';
column event format A20
column time_waited_ms format 999,999,999.99
column object_name format A20
column event format A20

with pivot1 as
(
SELECT distinct to_char(ash.sample_time, 'DY DD-MM-YY HH24:MI.SS')  t_sample_time, inst_id, session_id, session_serial#, ash.sql_id as blocking_sql_id, (select username from dba_users where user_id =  ash.user_id)  blocking_username,
    (select distinct command_name from dba_hist_sqltext ST inner join v$sqlcommand SC on SC.command_type = ST.command_type where sql_id = ash.sql_id) blocking_command
     FROM
        gv$active_session_history ash
WHERE  sample_time    >= TO_DATE ('&START_TIME', 'dd/mm/yyyy hh24:mi')
AND    sample_time    <= TO_DATE ('&END_TIME', 'dd/mm/yyyy hh24:mi')
)
,
blocking_time_list as
(
SELECT to_char(ash.sample_time, 'DY DD-MM-YY HH24:MI.SS'), ash.inst_id, ash.session_id sid, ash.session_serial# serial#,
                   (select username from dba_users where user_id =  ash.user_id) username,
                   sql_opname,
                   top_level_sql_id, 
                    ash.sql_id,
                   sql_exec_id,
                   in_hard_parse,
                    module,
                   DA.object_name ,
                  DA.subobject_name,
                   event,
                    time_waited/1000 time_waited_ms,
                    blocking_session,
                   blocking_session_serial#,
                   blocking_inst_id,
                   P1.blocking_username,
                  P1.blocking_sql_id, P1.blocking_command
     FROM
        gv$active_session_history ash
left outer join dba_objects DA on DA.object_id = ASH.current_obj#
left outer join pivot1 P1 on to_char(ash.sample_time, 'DY DD-MM-YY HH24:MI.SS') = P1.t_sample_time and ash.blocking_inst_id = P1.inst_id and ash.blocking_session = P1.session_id and ash.blocking_session_serial# = P1.session_serial#
WHERE
     session_type = 'FOREGROUND'
AND   sample_time    >= TO_DATE ('&START_TIME', 'dd/mm/yyyy hh24:mi')
AND   sample_time    <= TO_DATE ('&END_TIME', 'dd/mm/yyyy hh24:mi')
--and ash.user_id in ( 50 )
--AND ash.SESSION_ID = 1328
--and ash.sql_id = '6v0qm6tatswwj'
--and wait_class = 'Concurrency'
--and time_waited/1000 > 1
and blocking_session is not null
ORDER BY SAMPLE_ID
)
select * from blocking_time_list;

or :

-- summing block events, per sql_id
select username, sql_opname, sql_id, count(*)
from blocking_time_list
group by username, sql_opname, sql_id
order by count(*) desc;


-- complete list of blocking events
select username, sql_opname, sql_id, in_hard_parse, event, blocking_username, blocking_sql_id, blocking_command
from blocking_time_list
order by username, sql_opname, sql_id;

----------------------------------------------------------------------------------------------------------

-- querying AWR (my query) joing on sample minutes


define START_TIME='10/01/2017 16:25';
define   END_TIME='10/01/2017 17:00';

column event format A20
column time_waited_ms format 999,999,999.99
column object_name format A20
column event format A20

define START_TIME='17/02/2017 00:22';
define   END_TIME='17/02/2017 08:30';
define SNAP_ID=48620

column event format A20
column time_waited_ms format 999,999,999.99
column object_name format A20
column event format A20

with pivot1 as
(
SELECT distinct to_char(ash.sample_time, 'DY DD-MM-YY HH24:MI.SS')  t_sample_time, instance_number inst_id, session_id, session_serial#, ash.sql_id as blocking_sql_id, (select username from dba_users where user_id =  ash.user_id)  blocking_username,
     command_type  blocking_command,
      	regexp_replace(dbms_LOB.substr(sql_text, 50), '[[:cntrl:]]',null)  blocking_sqltext
     FROM
        dba_hist_active_sess_history ash
left outer join dba_hist_sqltext DHST on DHST.sql_id = ASH.sql_id   
WHERE  sample_time    >= TO_DATE ('&START_TIME', 'dd/mm/yyyy hh24:mi')
AND    sample_time    <= TO_DATE ('&END_TIME', 'dd/mm/yyyy hh24:mi')
and snap_id > &SNAP_ID
)
,
blocking_time_list as
(
SELECT to_char(ash.sample_time, 'DY DD-MM-YY HH24:MI.SS') sample_min, ash.instance_number inst_id, ash.session_id sid, ash.session_serial# serial#,
                   (select username from dba_users where user_id =  ash.user_id) username,
                   sql_opname,
                   top_level_sql_id, 
                    ash.sql_id,
                   sql_exec_id,
                   in_hard_parse,
                    module,
                   DA.object_name ,
                  DA.subobject_name,
                   event,
                    program,
                    time_waited/1000 time_waited_ms,
                    blocking_session,
                   blocking_session_serial#,
                   blocking_inst_id,
                   P1.blocking_username,
                  P1.blocking_sql_id, P1.blocking_command, P1.blocking_sqltext
     FROM
        dba_hist_active_sess_history ash
left outer join dba_objects DA on DA.object_id = ASH.current_obj#
left outer join pivot1 P1 on to_char(ash.sample_time, 'DY DD-MM-YY HH24:MI.SS') = P1.t_sample_time and ash.blocking_inst_id = P1.inst_id and ash.blocking_session = P1.session_id and ash.blocking_session_serial# = P1.session_serial#
WHERE
     session_type = 'FOREGROUND'
AND   sample_time    >= TO_DATE ('&START_TIME', 'dd/mm/yyyy hh24:mi')
AND   sample_time    <= TO_DATE ('&END_TIME', 'dd/mm/yyyy hh24:mi')
and snap_id > &SNAP_ID
--and ash.user_id in ( 50 )
--AND ash.SESSION_ID = 1328
--and ash.sql_id = '6v0qm6tatswwj'
--and wait_class = 'Concurrency'
--and time_waited/1000 > 1
and program = '<unknown>_null_NEUTRAL'
and blocking_session is not null
ORDER BY SAMPLE_ID
)
select  sample_min, username, sql_opname, sql_id, in_hard_parse, event, blocking_username, blocking_sql_id, blocking_command, blocking_sqltext
from blocking_time_list
order by sample_min;



-- summing block events, per sql_id
select username, sql_opname, sql_id, count(*)
from blocking_time_list
group by username, sql_opname, sql_id
order by count(*) desc;


-- complete list of blocking events
select username, sql_opname, sql_id, in_hard_parse, event, blocking_username, blocking_sql_id, blocking_command
from blocking_time_list
order by username, sql_opname, sql_id;



-- finding historical blockers and objects using ASH (my query) joining on sample_id:


define START_TIME='30/10/2015 06:00';
define   END_TIME='30/10/2015 06:53';





SELECT distinct
  waiter.sample_id,
  waiter.sample_time,
  waiter.user_id,
  (
    SELECT
      username
    FROM
      dba_users
    WHERE
      user_id = waiter.user_id
  )
  waiting_username,
  waiter.inst_id,
  waiter.session_id,
  waiter.current_obj# waiting_object,
  waiter.event, 
  waiter.in_hard_parse,
  waiter.sql_id waiting_sql_id,
  regexp_replace(dbms_LOB.substr( STwaiter.sql_text , 50), '[[:cntrl:]]',NULL)
  waiter_sqltext,
  (
    SELECT
      object_name
    FROM
      dba_objects
    WHERE
      object_id = waiter.current_obj#
  )
  waiting_object_name,
  blocker.inst_id blocking_inst_id,
  blocker.session_id blocking_sid,
  (
    SELECT
      username
    FROM
      dba_users
    WHERE
      user_id = blocker.user_id
  )
  blocking_username,
  blocker.sql_id blocking_sql_id,
  regexp_replace(dbms_LOB.substr( STblocker.sql_text , 50), '[[:cntrl:]]',NULL)
  blocker_sqltext
FROM
  gv$active_session_history waiter
LEFT OUTER JOIN gv$active_session_history blocker
ON
  waiter.blocking_session   = blocker.session_id
AND waiter.blocking_inst_id = blocker.inst_id
AND waiter.sample_id        = blocker.sample_id
LEFT OUTER JOIN dba_hist_sqltext STwaiter
ON
  STwaiter.sql_id = waiter.sql_id
LEFT OUTER JOIN dba_hist_sqltext STblocker
ON
  STblocker.sql_id = blocker.sql_id
WHERE
  waiter.blocking_inst_id IS NOT NULL
AND waiter.user_id        != 0
AND waiter.sample_time     > sysdate - 1/24
ORDER BY
  sample_time;

