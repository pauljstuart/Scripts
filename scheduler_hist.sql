



column P_JOB_OWNER new_value 1 FORMAT a10
column P_JOB_NAME new_value 2 FORMAT a10


select null P_JOB_NAME, null P_JOB_OWNER from dual where 1=2;
select nvl( '&1','&_USER') P_JOB_OWNER, nvl('&2','%') P_JOB_NAME  from dual ;


define JOB_OWNER=&1     
define JOB_NAME=&2

undefine 1
undefine 2

prompt from &DAYS_AGO days ago 

column end_time format A19
column owner format A15
column start_time format A20
column job_name format A30
column status format A10
column instance_id format 999
column last_run_mins format 999,999
column retry_count format 999

select OWNER,
      job_name,
        CAST(actual_start_date AS TIMESTAMP WITH LOCAL TIME ZONE) start_time  ,
       log_date  end_time,
      status,
      instance_id, 
      error#,
   extract(day from run_duration)*24*60 +       EXTRACT(HOUR FROM run_duration ) * 60 + EXTRACT(MINUTE FROM run_duration) run_mins
from dba_SCHEDULER_JOB_run_details
where job_name like '&JOB_NAME'
and OWNER like '&JOB_OWNER'
and log_date > sysdate - &DAYS_AGO
order by log_date ;


/*

prompt : Window log :


select * from DBA_SCHEDULER_WINDOW_LOG 
where window_name like '%&JOB_SEARCH%'
order by log_date;
*/
