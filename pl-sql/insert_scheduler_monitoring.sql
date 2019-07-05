
------------------------- monitoring code ------------------------------------------



SELECT SM.USERNAME, SM.SQL_ID, SM.SQL_EXEC_ID, SM.SQL_EXEC_START, SM.STATUS, OUTPUT_ROWS, binds_xml, TRUNC(ELAPSED_TIME/1000000)
from gv$sql_monitor sm
INNER JOIN gv$sql_plan_monitor SPM on SPM.key = SM.key and plan_line_id = 0
where 1=1
and SM.status = 'DONE'
and SM.sql_id in ('czd50f956qupw','8bzym1xnf53dp','bzdumhtz54q10');


drop table pjs_hist_sqlmon;

create table pjs_hist_sqlmon (USERNAME  VARCHAR2(30), 
SQL_ID              VARCHAR2(13) ,
SQL_EXEC_ID         NUMBER      , 
SQL_EXEC_START      DATE        , 
STATUS              VARCHAR2(19) ,
OUTPUT_ROWS         NUMBER  ,
BINDS_XML           VARCHAR2(4000) ,
ETIME_SECS        INTEGER  );


begin
  DBMS_SCHEDULER.DROP_JOB (   job_name     => 'SQLMON_ROWS_MONITOR' );
end;
/



alter session set nls_timestamp_format='DD-MON-YYYY HH24:MI';
alter session set nls_date_format='DD-MON-YYYY HH24:MI';
alter session set NLS_TIMESTAMP_TZ_FORMAT="DD-MON-YYYY HH24:MI TZR";

begin

DBMS_SCHEDULER.CREATE_JOB (
   job_name             => 'SQLMON_ROWS_MONITOR',
   job_type             => 'PLSQL_BLOCK',
   job_action           => q'#BEGIN 

INSERT INTO pjs_hist_sqlmon
SELECT SM.USERNAME, SM.SQL_ID, SM.SQL_EXEC_ID, SM.SQL_EXEC_START, SM.STATUS, OUTPUT_ROWS, binds_xml, TRUNC(ELAPSED_TIME/1000000)
from gv$sql_monitor sm
INNER JOIN gv$sql_plan_monitor SPM on SPM.key = SM.key and plan_line_id = 0
where SM.sql_id in ('2c9zmc5u1t4gt','czd50f956qupw','bzdumhtz54q10');
--and SM.status = 'DONE'

COMMIT;

END;

#',
   start_date           => '09-JAN-2018 14:00 UTC',
   repeat_interval      => 'FREQ=MINUTELY;INTERVAL=5', 
   end_date             => '30-APR-2018 10:00 UTC',
   enabled              =>  TRUE,
   auto_drop            =>  FALSE,
   comments             => 'Gathers additional info gv$sql_monitor - Paul Stuart');
END;
/




@scheduler_jobs

@scheduler_hist

-- viewing output

select * from pjs_hist_sqlmon;


-------------------------------------------------------------------
