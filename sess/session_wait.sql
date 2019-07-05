col P_USERNAME new_value 1 format A20
col P_EVENT new_value 2  format A20
col P_INST new_value 3 format A20

select null P_USERNAME, null P_EVENT, null P_INST from dual where 1=2;
select nvl( '&1','&_USER') P_USERNAME, nvl('&2','%') P_EVENT, nvl('&3','%') P_INST from dual ;

define USERNAME=&1     
define WAIT_EVENT=&2
define INST_ID=&3

undefine 1
undefine 2
undefine 3
--
-- Get an overview of database waits.
--
-- Paul Stuart Sep 2004
--

column wait_class format A10
column event format a30;
column username format a20;
column wait_time_ms format 999,999,999.9      

/*
prompt
prompt current session waits :
prompt



select  sw.inst_id, 
        s.username,
        sw.sid, 
	sw.wait_class,
	sw.event, 
	sw.state,  
	sw.seq#, 
	sw.wait_time_micro/1000 wait_time_ms
--	sw.P1, sw.P2, sw.P3
from gv$session_wait sw
inner join gv$session s on sw.inst_id = S.inst_id and S.sid = sw.sid
where    s.username is not null
and sw.wait_class != 'Idle'
and sw.inst_id like '&INST_ID'
order by sw.inst_id, sw.wait_time_micro desc;

*/

prompt
prompt current waits from GV$SESSION :
prompt



select   inst_id,  username,
         sid,
         serial#,
          STATE, WAIT_CLASS  , event,        SECONDS_IN_WAIT, seq#,wait_time_micro/1000 wait_time_ms,
SQL_ID ,     SQL_EXEC_ID,   SQL_CHILD_NUMBER, SQL_EXEC_START     , 
        blocking_session_status,
        blocking_instance,
        blocking_session, 
        FINAL_BLOCKING_SESSION_STATUS,
        FINAL_BLOCKING_instance,
        FINAL_BLOCKING_SESSION
from gv$session
where 
 inst_id like '&INST_ID'
--and wait_class != 'Idle'
AND USERNAME LIKE '&USERNAME'
and (wait_class like '&WAIT_EVENT' or event like '&WAIT_EVENT')
AND STATUS = 'ACTIVE'
AND TYPE = 'USER'
order by inst_id,  wait_time_micro desc;



