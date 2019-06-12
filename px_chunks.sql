col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2, nvl('&3','%')  PARAM3 from dual ;


define USERNAME=&1
define TASK_NAME=&2     
DEFINE STATUS=&3


undefine 1
undefine 2
undefine 3



column start_ts format A21
column end_ts format A21
COLUMN TASK_NAME FORMAT a30
column task_owner format A20
COLUMN JOB_NAME FORMAT a20
column error_message format A200
COLUMN MIN(start_ts) FORMAT a21
COLUMN MAX(end_ts) FORMAT A21

select  task_name, MIN(start_ts) , MAX(end_ts) ,  (CAST(MAX(end_ts)  AS DATE) - CAST( MIN(start_ts) AS DATE)) * 60*24 etime_mins 
from dba_parallel_execute_CHUNKS
where task_name LIKE '&TASK_NAME'
AND TASK_OWNER like '&USERNAME'
GROUP BY TASK_NAME;


select  task_name,status, count(*)
from dba_parallel_execute_CHUNKS
where task_name LIKE '&TASK_NAME'
AND TASK_OWNER like '&USERNAME'
GROUP BY TASK_NAME, status;



select TASK_OWNER, task_name, job_name, start_id, end_id,   status, start_ts, end_ts,  (CAST(end_ts  AS DATE) - CAST( start_ts AS DATE)) * 60*24 etime_mins , error_code, error_message 
from dba_parallel_execute_CHUNKS
where task_name LIKE '&TASK_NAME'
AND TASK_OWNER like '&USERNAME'
AND STATUS LIKE '&STATUS'
order by job_name, START_ID;


