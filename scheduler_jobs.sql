



	column P_JOB_OWNER new_value 1 FORMAT A10
	column P_JOB_NAME new_value 2 format A10


	select null P_JOB_NAME, null P_JOB_OWNER from dual where 1=2;
	select nvl( '&1','&_USER') P_JOB_OWNER, nvl('&2','%') P_JOB_NAME  from dual ;


	define JOB_OWNER=&1     
	define JOB_NAME=&2

	undefine 1
	undefine 2

	alter session set NLS_TIMESTAMP_TZ_FORMAT="DY DD-MON-RR HH24.MI TZR";

	column repeat_interval format A30
	column comments format A80
	column client_id format A20
	column repeat_interval format A50
	column job_creator format A25
	column last_start_date format A25
	column next_run_date format A25
	column START_date format A25
	column last_run_mins format 999,999.9
	column last_run_secs format 999,999,999.9
	column schedule_name format A25
	column raise_events format A40
	column job_text format A400
	column running_instance format 999
	column etime_mins format 9,999.9
	column failure_count format 999,999
	column  retry_count format 999,999
	column run_count format 999,999
	column end_date format A19
	column job_priority format 999



	SELECT 
	  job_creator,
	  job_name,
	  job_type,
	  schedule_type,
	  start_date,
	  repeat_interval,
	  max_run_duration,
	  enabled,
	  state,
	  run_count,
	  failure_count,
	  retry_count,
	  last_start_date,
	  EXTRACT(HOUR FROM last_run_duration ) * 3600 + EXTRACT(MINUTE FROM last_run_duration) * 60 + EXTRACT( SECOND from last_run_duration) last_run_secs,
	  EXTRACT(HOUR FROM last_run_duration ) * 60 + EXTRACT(MINUTE FROM last_run_duration) last_run_mins,
	  next_run_date,
	  instance_id inst_id,
	  instance_stickiness,
	  end_date,
	  job_class,
	  auto_drop,
	  restartable,
	  job_priority,
	  system,
	  raise_events,
	  comments,
	  --regexp_replace( substr(job_action, 0, 300), '[' || chr(10) || chr(13) || ']', ' ') job_text
	  regexp_replace( substr(job_action, 0, 300), '[[:space:]]+', ' ') job_text
	FROM dba_scheduler_jobs
	where job_name like '&JOB_NAME'
	and job_creator like '&JOB_OWNER';


	prompt
	prompt running jobs :
	prompt

	select OWNER , JOB_NAME,   JOB_STYLE,    DETACHED,  SESSION_ID,   RUNNING_INSTANCE,  RESOURCE_CONSUMER_GROUP  ,         
	      EXTRACT(HOUR FROM elapsed_time) * 60 + EXTRACT(MINUTE FROM elapsed_time) etime_mins,  CPU_USED, LOG_ID
	 from all_scheduler_running_jobs;

