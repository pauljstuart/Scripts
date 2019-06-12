set echo off
SET feedback off



col p1 new_value 1

select null p1 from dual where 1=2;
select nvl( '&1','%') p1 from dual ;

define JOB_SEARCH=&1     

undefine 1


column repeat_interval format A30
column comments format A80
column client_id format A20
column repeat_interval format A50
column job_creator format A25
column last_start_date format A20
column next_run_date format A20
column next_start_date format A20
column START_date format A20
column last_run_secs format 999,999.9
column schedule_name format A25
column schedule_owner format A10

alter session set NLS_TIMESTAMP_TZ_FORMAT="DY DD-MON-RR HH24.MI";



SELECT *
FROM dba_scheduler_windows
where window_name like '%&JOB_SEARCH%';



SELECT *
FROM dba_scheduler_window_groups
where window_group_name like '%&JOB_SEARCH%';
