

alter session set nls_date_format = "DD-MON-YY HH24:MI";




col USERNAME new_value 1
col OPNAME new_value 2


select null USERNAME, null OPNAME from dual where 1=2;
select nvl( '&1','%') USERNAME, nvl('&2','%') OPNAME from dual ;

define USERNAME=&1
define OPNAME=&2
column target format A20
column message format A100
column opname format A30


select distinct INST_ID, sid,serial#,username, opname, trunc(elapsed_seconds/60) etime_mins, trunc(time_remaining/60) remaining_mins, last_update_time, message
from gv$session_longops 
where opname  like '%&OPNAME%'
and username like '%&USERNAME%'
and trunc(time_remaining/60) != 0
order by LAST_UPDATE_TIME ;

undefine OPNAME
undefine USERNAME
undefine 1
undefine 2
