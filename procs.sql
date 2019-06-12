col P_USER new_value 1 format A10
col P_PROC new_value 2 format A10


select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') P_USER, nvl('&2','%') P_PROC from dual ;


define USERNAME=&1
define PROC_NAME=&2     


undefine 1
undefine 2
undefine 3


column last_ddl_time format A21
column created format A21
column pipelined format A10
column parallel format A10

select DP.owner,  DP.object_name, procedure_name, DP.object_type, created, last_ddl_time, pipelined, parallel, authid
from dba_procedures DP
INNER JOIN DBA_OBJECTS DA on DA.object_id = DP.object_id
where DP.owner LIKE '&USERNAME'
AND (PROCEDURE_NAME LIKE '&PROC_NAME' OR DP.OBJECT_NAME LIKE '&PROC_NAME' )
and DP.object_type = 'PROCEDURE';
