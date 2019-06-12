col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10


select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define TASK_NAME=&2     


PROMPT TASKS : &USERNAME - &TASK_NAME

undefine 1
undefine 2

column tASK_COMMENT   format A50
column task_name format a50
COLUMN STATUS FORMAT a30
column additional_info format A100
column task_stmt format A80
column job_name format A20
column job_prefix format A20
column  SESSION_ID  format A20

prompt :  Running Scheduler jobs :

SELECT t.task_name , JOB_PREFIX ,  job_name,  session_id, running_instance, resource_consumer_group , (SYSDATE + elapsed_time*1440 - SYSDATE) AS etime_mins
FROM dba_parallel_execute_tasks t
inner JOIN dba_scheduler_running_jobs d on d.owner = t.task_owner and d.job_name like t.job_prefix||'%'
WHERE task_name  = '&TASK_NAME' 
and t.task_owner = '&USERNAME'
and d.OWNER like '&USERNAME'
ORDER BY t.task_name, d.job_name;



prompt :  Completed Scheduler jobs :

SELECT t.task_name,   regexp_replace( substr(t.sql_stmt, 0, 100), '[[:space:]]+', ' ') task_stmt ,  job_name, d.STATUS, D.ERROR#, d.actual_start_date, d.session_id, regexp_replace( substr(additional_info, 0, 100), '[[:space:]]+', ' ' ) additional_info 
FROM dba_parallel_execute_tasks t
JOIN dba_scheduler_job_run_details d ON d.job_name like t.job_prefix||'%'
WHERE task_name  like '&TASK_NAME' 
and t.task_owner like '&USERNAME'
and d.OWNER like '&USERNAME'
ORDER BY t.task_name, d.job_name;

