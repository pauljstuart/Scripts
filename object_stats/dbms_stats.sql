
BEGIN
   DBMS_STATS.gather_table_stats (ownname       => 'FDD',
                                  tabname       => 'JOURNALS_GMIB_INST_20180909',
                                  method_opt => 'FOR ALL INDEXED COLUMNS SIZE 1', 
                                  granularity   => 'GLOBAL',
                                  DEGREE        => 16,
                                  force         => TRUE);
END;
/


-- GATHER table stats :


begin
  dbms_stats.gather_table_stats( ownname => 'MERIDIAN', tabname => 'POSTING', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 8, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    no_invalidate => FALSE,
                    granularity => 'GLOBAL AND PARTITION' );
end;

-- gathering index stats :

begin
  dbms_stats.gather_index_stats( ownname => 'PERF_SUPPORT', indname => 'PK_GCR_CORE1', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL AND PARTITION' );
end;



  dbms_output.put_line("Start at "||SYSTIMESTAMP);
DBMS_STATS.GATHER_TABLE_STATS(ownname => schema_name,
                                  tabname =>  tableName,
                                  method_opt => 'FOR ALL COLUMNS SIZE 1',
                                  estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                                  granularity => 'AUTO',
                                  cascade => TRUE,
                                  degree => 4,
                                  no_invalidate => TRUE);
  dbms_output.put_line("end  at "||SYSTIMESTAMP);

-- gathering stats on just one column :


exec dbms_stats.gather_table_stats( ownname => 'MERIDIAN', tabname => 'TRADEBALANCE_MARKTOMARKET', partname => 'WORKFLOW11624', method_opt => 'FOR COLUMNS WORKFLOW_ID SIZE 1' );


-- gathering subpartition stats


begin
  dbms_stats.gather_table_stats( ownname => 'MERIDIAN', tabname => 'POSTING', 
                     partname => 'WORKFLOW12038P2', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 8, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'SUBPARTITION' );
end;



-- gathering schema stats

 

DBMS_STATS.GATHER_SCHEMA_STATS(ownname=>'MVDS', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 4, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                    granularity => 'GLOBAL' ,
                    options => 'GATHER STALE',
                    obj_filter_list => filter_lst,
                    objlist => output_tab_list);

-- GATHER EMPTY :

begin
  dbms_stats.gather_schema_stats( ownname => 'MVDS', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                    granularity => 'GLOBAL AND PARTITION' ,
                    options => 'GATHER EMPTY');
end;


-- deleting schema stats :


begin
  dbms_stats.delete_schema_stats( ownname => 'MERIDIAN' );
end;

-- deleting global column stats, for a particular column :

begin
  dbms_stats.delete_column_stats( ownname => 'CF_CDL_UAT1', tabname => 'FF_RISK_CALCULATED_MEASURE', 
                    partname => null, colname => 'RISK_DATASET_SLICE_ID' );
end;


-- complex method_opt


 method_opt                    => 'FOR ALL COLUMNS  SIZE 1, FOR COLUMNS SIZE 254 SAP_MANAGEMENT_CENTER,REPORTING_DATE,SAP_GL_POSTING_ACCT',
                                        


-- disabling histograms :


11:08     Burns, Doug       Is the use of FOR ALL INDEXED COLUMNS SIZE 1 to disable histograms 
11:09     Burns, Doug       But also disables column stats on any non-indexed columns 
11:09     Burns, Doug       Doh 
11:09     Stuart, Paul         ah 
11:09     Burns, Doug       Idea is to improve stats collection performance where all of your queries use indexes 
11:09     Burns, Doug       All over the web in the 90s ;-) 
11:09     Burns, Doug       and people here picked up on that 
11:09     Burns, Doug       FOR ALL COLUMNS SIZE 1 !!! 



---------------------------------------
-- querying _opstat_tab_history
-------------------------------------

select OBJECT_NAME AS TABLE_NAME, SUBOBJECT_NAME AS PARTITION_NAME, obj#, analyzetime,  rowcnt as NUM_ROWS, samplesize
from sys.wri$_optstat_tab_history W
INNER JOIN DBA_OBJECTS DO on DO.object_id = W.obj#
and DO.object_name = 'CASH_MOVE' and DO.subobject_name = 'CM_R_20170925'
and  analyzetime > trunc(sysdate) - &DAYS_AGO
 order by analyzetime ; 




------------------------------------------------------------------------------------------------------------
-- Checking for the different stats
------------------------------------------------------------------------------------------------------------


-- to see if system stats are gathered on Exadata

select pname, PVAL1 from sys.aux_stats$ where pname='MBRC';


if it returns NULL, then no system stats.


select * from dba_optstat_operations;

-- seeing when fixed object stats where gathered 

select trunc(last_analyzed), count(*) FROM DBA_TAB_STATISTICS WHERE OBJECT_TYPE='FIXED TABLE' group by trunc(last_analyzed);


-- seing when dictionary stats gathered :


select * from dba_optstat_operations
where operation like '%dictionary%';

-- seeing when System stats were gathered :


 SELECT pname, pval1, pval2
 FROM sys.aux_stats$
 WHERE sname = 'SYSSTATS_INFO';


-- checking for fixed object stats 


select OWNER, TABLE_NAME, LAST_ANALYZED 
     from dba_tab_statistics where table_name='X$KGLDP'

-- checking incremental stats 

select o.name, c.name, decode(bitand(h.spare2, 8), 8, 'yes', 'no') incremental
from sys.hist_head$ h, sys.obj$ o, sys.col$ c
where h.obj# = o.obj#
and o.obj# = c.obj#
and h.intcol# = c.intcol#
and o.name = 'BALANCE'
and o.subname is null;

-- setting stats :



begin
  DBMS_STATS.unlock_table_stats (ownname      => 'ONEBALANCE',
                                tabname      => 'CRESCENT_RDS_TB_IDS'
                               );
  DBMS_STATS.set_table_stats (ownname      => 'ONEBALANCE',
                                tabname      => 'CRESCENT_RDS_TB_IDS',
                                numrows => 20000,
                                numblks => 500
                               );
  DBMS_STATS.lock_table_stats (ownname      => 'ONEBALANCE',
                                tabname      => 'CRESCENT_RDS_TB_IDS'
                               );
end;
/
begin
  DBMS_STATS.gather_table_stats (ownname      => 'ONEBALANCE',
                                tabname      => 'CRESCENT_RDS_TB_IDS'
                               );
end;
/



------------------------------------------------------------------------------------------------------------
-- Exporting and importing stats
------------------------------------------------------------------------------------------------------------


DECLARE 
  s_stats_table VARCHAR2(64) := 'PJS_STATS_15MAR';

BEGIN

  for c1 in (select table_name from user_tables where table_name = s_stats_table)
    LOOP
    execute immediate 'drop table ' || s_stats_table;
    END LOOP;
  
   DBMS_STATS.CREATE_STAT_TABLE( ownname => USER, stattab => s_stats_table);

  DBMS_STATS.EXPORT_TABLE_STATS( ownname => 'MVDS', tabname => 'GCR_CORE', statown => USER, stattab => s_stats_table);

   dbms_stats.delete_table_stats( ownname => USER, tabname => 'GCR_CORE',cascade_columns => TRUE, cascade_indexes => TRUE );

  DBMS_STATS.IMPORT_TABLE_STATS(ownname => USER, tabname => 'GCR_CORE', statown => USER, stattab => 's_stats_table ');



END;
/


------------------------------------------------------------------------------------------------------------
-- Using unpublished stats 
------------------------------------------------------------------------------------------------------------


So we have :

Set publishing off on that partition :

begin
  DBMS_STATS.set_table_prefs(ownname => 'MERIDIAN', tabname => 'TRADEBALANCE_MARKTOMARKET', pname => 'PUBLISH',  pvalue => 'false');
end;
/

then gather the stats on that partition column :

begin
  dbms_stats.gather_table_stats( ownname => 'MERIDIAN', tabname => 'TRADEBALANCE_MARKTOMARKET', partname => 'WORKFLOW11626', method_opt => 'FOR COLUMNS SIZE 1 WORKFLOW_ID', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE );
end;
/

set publishing back on :
(note : I believe this command just sets the default behaviour back to TRUE.  It does not publish the pending stats.  I say that because there appears to be
a special, separate function to do that - dbms_stats.publish_pending_stats.)


begin
  DBMS_STATS.set_table_prefs(ownname => 'MERIDIAN', tabname => 'TRADEBALANCE_MARKTOMARKET', pname => 'PUBLISH',  pvalue => 'TRUE');
end;
/

Check that they are there :

SELECT TABLE_NAME,PARTITION_NAME ,LAST_ANALYZED  FROM DBA_TAB_PENDING_STATS;

Then, conduct testing using the session parameter OPTIMIZER_USE_PENDING_STATISTICS=TRUE;

Then after testing just delete the pending stats  :

EXEC DBMS_STATS.delete_pending_stats(ownname => 'MERIDIAN', tabname => 'TRADEBALANCE_MARKTOMARKET', partname => 'WORKFLOW11626' );


------------------------------------------------------------------------------------------------------------
-- setting preferences
------------------------------------------------------------------------------------------------------------

-- setting table prefs :

begin
  DBMS_STATS.SET_TABLE_PREFS( ownname               =>'FBI_FDR_BALANCE' ,
                                tabname               => 'BALANCE',
                                 pname => 'INCREMENTAL', pvalue => TRUE );

end;



BEGIN
DBMS_STATS.SET_GLOBAL_PREFS('INCREMENTAL','TRUE');
END;
/


BEGIN
DBMS_STATS.SET_TABLE_PREFS(‘SH’,’SALES’,‘INCREMENTAL’,’TRUE’);
END;

BEGIN
DBMS_STATS.GATHER_TABLE_STATS('SWAPP_OWNER’,’ENTITY_SIDE_MAJORS');
END;




exec DBMS_STATS.SET_TABLE_PREFS('SWAPP_OWNER','ENTITY_SIDE_MAJORS', 'ESTIMATE_PERCENT', 0.5);
exec DBMS_STATS.SET_TABLE_PREFS('SWAPP_OWNER','ENTITY_SIDE_MAJORS', 'DEGREE', 1);

select DBMS_STATS.get_PREFS('INCREMENTAL', 'SWAPP_OWNER','ENTITY_SIDE_MAJORS' ) from dual;



EXEC DBMS_AUTO_TASK_ADMIN.ENABLE('auto optimizer stats collection', NULL, NULL);



exec DBMS_STATS.SET_TABLE_PREFS('SWAPP_OWNER','ENTITY_SIDE_MAJORS', 'METHOD_OPT', 'FOR COLUMNS size 1 ID');


exec DBMS_STATS.SET_TABLE_PREFS('SWAPP_OWNER','ENTITY_SIDE_MAJORS', 'ESTIMATE_PERCENT', 0.0005);
exec DBMS_STATS.SET_TABLE_PREFS('SWAPP_OWNER','ENTITY_SIDE_MAJORS', 'METHOD_OPT', 'FOR ALL COLUMNS size AUTO');


exec DBMS_STATS.SET_TABLE_PREFS('SWAPP_OWNER','ENTITY_SIDE_MAJORS', 'ESTIMATE_PERCENT',DBMS_STATS.AUTO_SAMPLE_SIZE);

to turn off histogram collection :

exec DBMS_STATS.SET_TABLE_PREFS('SWAPP_OWNER','ENTITY_SIDE_MAJORS', 'METHOD_OPT', 'FOR ALL INDEXED COLUMNS size 1');




------------------------------------------------------------------------------------------------------------
-- Histograms and method_opt
------------------------------------------------------------------------------------------------------------



-- GATHERING HISTOGRAMS ON WORKFLOW AND PARTITION_ID

begin
  dbms_stats.gather_table_stats( ownname => 'MVDS', tabname => 'POSTING', granularity => 'GLOBAL', degree => 8, method_opt => 'FOR COLUMNS SIZE AUTO WORKFLOW_ID,PARTITION_ID', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE );
end;
/

-- gathering no histograms on a set of columns :


 'FOR COLUMNS size 1 PARTITION_ID,SUB_PARTITION_ID,WORKFLOW_ID'


-- gathering histograms on some columns, but not others :

 method_opt => 'FOR COLUMNS  PARTITION_ID size 1,SUB_PARTITION_ID size auto ,WORKFLOW_ID size 1'

-- How to add a histogram :


exec  dbms_stats.delete_column_stats( ownname=>'STELIOS', tabname=>'TEST3', colname=>'OBJECT_TYPE', col_stat_type=>'HISTOGRAM');

Note this does not remove the histogram permanently!



if you want to remove the histogram forever, change the table preferences :

exec dbms_stats.set_table_prefs('ownname=>'STELIOS', tabname=>'TEST3', pname=>'method_opt', pvalue=>'FOR ALL COLUMNS SIZE 1');


To set a particular column ignored for histograms :


exec dbms_stats.set_table_prefs('ownname=>'STELIOS', tabname=>'TEST3', pname=>'method_opt', pvalue=>'FOR COLUMNS OBJECT_TYPE SIZE 1');



------------------------------------------------------------------------------------------------------------
-- DBMS_SCHEDULER stuff
------------------------------------------------------------------------------------------------------------


-- job to gather dictionary stats once a week :


ALTER session SET NLS_TIMESTAMP_TZ_FORMAT="DD-MON-YYYY HH24:MI TZR";
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
   job_name             => 'DICT_STATS_GATHER',
   job_type             => 'PLSQL_BLOCK',
   job_action           => q'#
BEGIN
  dbms_stats.gather_dictionary_stats; 
END; #',
   start_date           => '8-FEB-2014 22:00 UTC',
   repeat_interval      => 'FREQ=WEEKLY', 
   enabled              =>  TRUE,
   auto_drop            =>  FALSE,
   comments             => 'Gather dictionary stats');
END;
/

-- general daily job :


ALTER session SET NLS_TIMESTAMP_TZ_FORMAT="DD-MON-YYYY HH24:MI TZR";
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
   job_name             => 'MVDS_STATS_GATHER',
   job_type             => 'PLSQL_BLOCK',
   job_action           => q'#
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('Gathering empty',NULL);
  dbms_stats.gather_schema_stats( ownname => 'CF_CDL_UAT1', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 32, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                    granularity => 'ALL' ,
                    options => 'GATHER EMPTY');
  DBMS_APPLICATION_INFO.SET_MODULE('Gathering stale',NULL);
  dbms_stats.gather_schema_stats( ownname => 'CF_CDL_UAT1', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 32, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                    granularity => 'ALL' ,
                    options => 'GATHER STALE');
END; 
#',
   start_date           => '27-JUN-2014 01:30 UTC',
   repeat_interval      => 'FREQ=DAILY', 
   enabled              =>  TRUE,
   auto_drop            =>  FALSE,
   comments             => 'statistics gathering for unanalyzed partitions');
END;
/





-- Running a one-off job immediately :


 begin
    dbms_scheduler.create_job 
    (  
      job_name      =>  'PJS_TEST_JOB',  
      job_type      =>  'PLSQL_BLOCK',  
      job_action    =>  'begin pjs_test; end;',  
      start_date    =>  sysdate,  
      enabled       =>  TRUE,  
      auto_drop     =>  FALSE,  
      comments      =>  'one-time job');
  end;
  /


-- scheduling stats using one-off dbms_scheduler at a particular time :


alter session set NLS_TIMESTAMP_TZ_FORMAT="DD-MON-YYYY HH24:MI TZR";
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
   job_name             => 'MERIDIAN_TEMP3_MONITORING',
   job_type             => 'PLSQL_BLOCK',
   job_action           => 'BEGIN 
                            dbms_stats.gather_schema_stats( ownname => ''MERIDIAN'', 
                                method_opt => ''FOR ALL COLUMNS SIZE 1'', 
                                degree => 16, 
                                estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                                cascade => TRUE, 
                                granularity => ''GLOBAL AND PARTITION'' );
                            END;',
   start_date           => '27-FEB-2014 16:30 UTC',
   --repeat_interval      => 'FREQ=WEEKLY', 
--   end_date             => '25-MAR-2014 14:15 UTC',
   enabled              =>  TRUE,
   auto_drop            =>  FALSE,
   comments             => 'Paul Stuart - statistics gathering');
END;


-- ALTERNATIVELY creating a job with schedule type of IMMEDIATE
-- you create it disabled, and then when you enable it, it runs :



BEGIN
DBMS_SCHEDULER.CREATE_JOB (
   job_name             => 'ONE_OFF_JOB',
   job_type             => 'PLSQL_BLOCK',
   job_action           => q'#BEGIN 
                            DBMS_STATS.GATHER_TABLE_STATS( ownname => 'FDD', 
                                method_opt => 'FOR ALL COLUMNS SIZE 1', 
                                degree => 16, 
                                estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                                cascade => TRUE, 
                                granularity => 'GLOBAL AND PARTITION' );
                            END; #',
   enabled              =>  FALSE,
   comments             => 'Paul Stuart - statistics gathering');
END;

-- enable the first job so it starts running
 exec dbms_scheduler.enable('ONE_OFF_JOB')
 



begin
DBMS_SCHEDULER.DROP_JOB (
   job_name             => 'MERIDIAN_TEMP3_MONITORING' );
end;

 
-- changing attribute :

alter session set NLS_TIMESTAMP_TZ_FORMAT="DD-MON-YYYY HH24:MI";
begin
   dbms_scheduler.set_attribute( name => 'MERIDIAN_TEMP3_MONITORING',
                                 attribute => 'end_date',
                                 value => '25-APR-2014 14:15' );
end;


alter session set NLS_TIMESTAMP_TZ_FORMAT="DD-MON-YYYY HH24:MI";
begin
   dbms_scheduler.set_attribute( name => 'MVDS_STATS_GATHER',
                                 attribute => 'start_date',
                                 value => '14-DEC-2014 03:15' );
   dbms_scheduler.set_attribute( name => 'MVDS_STATS_GATHER',
                                 attribute => 'repeat_interval',
                                 value => 'FREQ=WEEKLY' );
end;


-- fixing the action attribute :

BEGIN

DBMS_SCHEDULER.SET_ATTRIBUTE (
name => 'MIDS.MIDS_STATS_GATHER',
attribute => 'job_action',
value =>  q'#
BEGIN
  dbms_stats.gather_schema_stats( ownname => 'MIDS', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                    granularity => 'PARTITION' ,
                    options => 'GATHER EMPTY');
END;
#');

END;
/


 -- to stop the job :
 
 
begin
   dbms_scheduler.set_attribute( name => 'MERIDIAN_TEMP3_MONITORING', 
                                 attribute => 'auto_drop', 
                                 value => FALSE );
end;


-- code to create a weekly stats gather job called 	WEEKLY_STATS_GATHER
--
-- this has a max duration of 2 hours
--


BEGIN

  for i in (select 1 from user_scheduler_jobs where job_name = 'WEEKLY_STATS_GATHER' )
  loop
      DBMS_SCHEDULER.DROP_JOB(JOB_NAME => 'WEEKLY_STATS_GATHER');
  end loop;

  EXECUTE IMMEDIATE 'ALTER session SET NLS_TIMESTAMP_TZ_FORMAT="DD-MON-YYYY HH24:MI TZR"';

  DBMS_SCHEDULER.CREATE_JOB (
         job_name          => 'WEEKLY_STATS_GATHER',
         job_type          => 'PLSQL_BLOCK',
         job_action           => q'#
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('Gathering empty',NULL);
  dbms_stats.gather_schema_stats( ownname => 'MIDS', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 32, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                    granularity => 'ALL' ,
                    options => 'GATHER EMPTY');
  DBMS_APPLICATION_INFO.SET_MODULE('Gathering stale',NULL);
  dbms_stats.gather_schema_stats( ownname => 'MIDS', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 32, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                    granularity => 'ALL' ,
                    options => 'GATHER STALE');
END;    #',
         start_date        => '09-JUNE-2019 01:00 UTC',
         repeat_interval   => 'FREQ=WEEKLY',
         enabled           => TRUE,
         auto_drop         => FALSE,
         comments          => 'statistics gathering for all tables');

DBMS_SCHEDULER.SET_ATTRIBUTE (
	name => 'WEEKLY_STATS_GATHER',
	attribute => 'max_run_duration',
	value => interval '120' minute);

EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line ('Could not create WEEKLY_STATS_GATHER job -' || SQLERRM);
END;
/

----------------------------------------------------------------------------
-- code to create a weekly stats stopper job called 	WEEKLY_STATS_STOPPER
----------------------------------------------------------------------------


BEGIN

  for i in (select 1 from user_scheduler_jobs where job_name = 'WEEKLY_STATS_STOPPER' )
  loop
      DBMS_SCHEDULER.DROP_JOB(JOB_NAME => 'WEEKLY_STATS_STOPPER');
  end loop;
  for i in (   select 1  from  ALL_QUEUE_SUBSCRIBERS where consumer_name='SUPCHKAGENT' 
               AND NOT EXISTS (SELECT * FROM ALL_QUEUE_SUBSCRIBERS where consumer_name='SUPCHKAGENT') )
  loop
       DBMS_SCHEDULER.ADD_EVENT_QUEUE_SUBSCRIBER('SUPCHKAGENT');
  end loop;

   DBMS_SCHEDULER.CREATE_JOB(
     job_name        => 'WEEKLY_STATS_STOPPER',
     job_type        => 'plsql_block',
     job_action            => q'# DBMS_SCHEDULER.STOP_JOB('WEEKLY_STATS_GATHER',false); #',
     event_condition       => q'# tab.user_data.object_name = 'WEEKLY_STATS_GATHER' AND tab.user_data.event_type = 'JOB_OVER_MAX_DUR' #',
     queue_spec            => 'sys.scheduler$_event_queue,SUPCHKAGENT',
     comments              => 'This job kills the WEEKLY_STATS_GATHER job when it has over-run its max duration ',
     enabled=>true);
     
     EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line ('Could not create WEEKLY_STATS_STOPPER job -' || SQLERRM);
      
END;
/


----- testing calendar strings :


set serveroutput on;
alter session set nls_timestamp_format = 'DD-MON-YYYY HH24:MI:SS';

DECLARE
  p_calendar_string   VARCHAR2(256) := 'FREQ=HOURLY;BYMINUTE=15';
  p_iterations        NUMBER := 5;
  l_start_date         TIMESTAMP := TO_TIMESTAMP('01-JAN-2004 03:04:32',
                                               'DD-MON-YYYY HH24:MI:SS');
  l_return_date_after  TIMESTAMP := l_start_date;
  l_next_run_date      TIMESTAMP;
BEGIN
  FOR i IN 1 .. p_iterations LOOP
    DBMS_SCHEDULER.evaluate_calendar_string (  
      calendar_string   => p_calendar_string,
   --   start_date        => l_start_date,
      return_date_after => l_return_date_after,
      next_run_date     => l_next_run_date);

    DBMS_OUTPUT.put_line('Next Run Date: ' || l_next_run_date);
    l_return_date_after := l_next_run_date;
  END LOOP;
END;
/


------------------------------------------------------------------------------------------------------------
-- PL/SQL code
------------------------------------------------------------------------------------------------------------


-- code to gather stats on a set of schemas :


set serveroutput on
declare
  type myarray is table of varchar2(255) index by binary_integer;
  v_array myarray;
begin

v_array(v_array.count + 1) := 'APP_GCRS_MERIVAL_RECON';
v_array(v_array.count + 1) := 'APP_MER_AGGREGATES';
v_array(v_array.count + 1) := 'APP_MERIVAL_GCRS_VALIDATION';
v_array(v_array.count + 1) := 'APP_BO_ONSHORE';
v_array(v_array.count + 1) := 'APP_BO';
v_array(v_array.count + 1) := 'APP_FDD_MERIVAL_RECON';
v_array(v_array.count + 1) := 'RFA_AUDIT';
v_array(v_array.count + 1) := 'APP_AXIOM';
v_array(v_array.count + 1) :=  'APP_ICS';
v_array(v_array.count + 1) :=  'APP_RFA_BO';
v_array(v_array.count + 1) :=  'CRESCENT_STATE' ;
v_array(v_array.count + 1) := 'CRESCENT_CALC_DETAIL';
v_array(v_array.count + 1) :=  'CRESCENT_CONFIG';
v_array(v_array.count + 1) :=  'CRESCENT_INPUT';
v_array(v_array.count + 1) :=  'CRESCENT_RPTG';
v_array(v_array.count + 1) :=  'APP_CDM';

  for i in 1..v_array.count loop
    dbms_output.put_line('doing ' || v_array(i));
    BEGIN dbms_stats.gather_schema_stats(ownname => v_array(i) , 
                                 method_opt=>'FOR ALL COLUMNS SIZE 1', 
                                 degree=>4,
                                 estimate_percent=>DBMS_STATS.AUTO_SAMPLE_SIZE,
                                 cascade=>TRUE,
                                granularity=>'GLOBAL AND PARTITION');
                        END;

  end loop; 
end;
/


-- code to iterate every partition and gather stats on stale partitions and subpartitions

set serveroutput on
DECLARE

  s_input_table_name VARCHAR2(128)  := 'OV_CALC_FACT';
  s_input_owner VARCHAR2(128)  := 'ONEVIEW_DATA';
  i_elapsed_time        NUMBER ;

BEGIN
  
  
   dbms_output.put_line('Examining ' || s_input_owner || ' : ' || s_input_table_name );
  for cursor_name in (select owner, table_name, partition_name, stale_stats from all_tab_statistics where owner = s_input_owner and table_name = s_input_table_name and object_type = 'PARTITION' )
    loop
      if ( cursor_name.stale_stats = 'YES' or cursor_name.stale_stats is NULL )
      then

          dbms_output.put_line('Gathering on ' || cursor_name.owner || ' ' || cursor_name.table_name || ' partition : ' || cursor_name.partition_name ) ;
          i_elapsed_time  := dbms_utility.get_time();
          
          dbms_stats.gather_table_stats( ownname => cursor_name.owner, 
                     tabname => cursor_name.table_name, 
                     partname => cursor_name.partition_name,
                    method_opt => 'FOR ALL COLUMNS SIZE AUTO', 
                    DEGREE => 4, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    no_invalidate => FALSE,
                    granularity => 'PARTITION' );
         i_elapsed_time := (dbms_utility.get_time() - i_elapsed_time)/100;
         dbms_output.put_line('Time for partition stats : ' || i_elapsed_time || ' secs.' );
         i_elapsed_time  := dbms_utility.get_time();
         dbms_stats.gather_table_stats( ownname => cursor_name.owner, 
                     tabname => cursor_name.table_name, 
                     partname => cursor_name.partition_name,
                    method_opt => 'FOR ALL COLUMNS SIZE AUTO', 
                    DEGREE => 4, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    no_invalidate => FALSE,
                    granularity => 'SUBPARTITION' );
          i_elapsed_time := (dbms_utility.get_time() - i_elapsed_time)/100;
         dbms_output.put_line('Time for subpartition stats : ' || i_elapsed_time || ' secs.' );
      end if;
    end loop;


   dbms_output.put_line('Completed  ' || s_input_owner || ' : ' || s_input_table_name );
END;
/



-- setting num_rows on a set of partitions :

SET SERVEROUTPUT ON
declare
  i_today_position INTEGER;

begin
  select partition_position into i_today_position from dba_tab_partitions where TABLE_OWNER = 'ONEVIEW_DATA' AND TABLE_NAME = 'OV_CALC_FACT_NEW' AND partition_name = 'P_' || to_char( sysdate,'YYYYMMDD');
 dbms_output.put_line('Today position is ' || i_today_position );

  FOR C1 in (select partition_name from  dba_tab_partitions where TABLE_OWNER = 'ONEVIEW_DATA' AND TABLE_NAME = 'OV_CALC_FACT_NEW' and partition_position >= i_today_position)
    LOOP
    dbms_output.put_line('Doing partition  ' || C1.partition_name );
    dbms_stats.set_table_stats( ownname => 'ONEVIEW_DATA', 
                                tabname => 'OV_CALC_FACT_NEW', 
                                partname => C1.partition_name, 
                                numrows => 50000000 );
    END LOOP;

end;
/


-- Setting global stats by copying them from another table in a different schema :


set serveroutput on
declare
  type myarray is table of varchar2(255) index by binary_integer;
  v_array myarray;

  srec               DBMS_STATS.STATREC;
  i_numrows  NUMBER;
  i_numblks  NUMBER;
  i_avgrlen  NUMBER;
  
  i_distinct NUMBER;
  i_nullcnt  NUMBER;
  i_avgcol_len NUMBER;
  f_density  NUMBER;

  s_postfix VARCHAR2(32) := '_PART_WORKFLOW_QL';

begin

v_array(v_array.count + 1) := 'POSTING';
v_array(v_array.count + 1) := 'GCR_CORE';
v_array(v_array.count + 1) := 'GCR_DERIVED';
v_array(v_array.count + 1) := 'GCR_INST';
v_array(v_array.count + 1) := 'GCR_LNF';
v_array(v_array.count + 1) := 'ICD';
v_array(v_array.count + 1) := 'ICDCAP';
v_array(v_array.count + 1) := 'LCR_CUBE';

  -- setting global table stats :
  for i in 1..v_array.count 
    LOOP
    --dbms_output.put_line('doing ' || v_array(i));
    DBMS_STATS.GET_TABLE_STATS (  ownname => 'MVDS',       tabname => v_array(i),   numrows =>   i_numrows ,    numblks  =>  i_numblks ,   avgrlen =>     i_avgrlen );
    DBMS_OUTPUT.PUT_LINE('Table ' || v_array(i) || ' num_rows=' || RPAD(i_numrows,20) || ' numblks=' || RPAD(i_numblks,20) || ' avgrowlen=' || RPAD(i_avgrlen,20) );
    DBMS_STATS.SET_TABLE_STATS (  ownname => USER,       tabname => v_array(i) || s_postfix,   numrows =>   i_numrows ,    numblks  =>  i_numblks ,   avgrlen =>     i_avgrlen );
  END LOOP;

  -- setting global column stats
  for i in 1..v_array.count 
    LOOP
    DBMS_OUTPUT.PUT_LINE('Setting global column stats for ' || v_array(i) );
      for C1 in (select column_name from dba_tab_columns where owner = 'MVDS' and table_name = v_array(i) )
        LOOP
        --DBMS_OUTPUT.PUT_LINE('Examining column ' || v_array(i) || '.' || C1.column_name );
        DBMS_STATS.GET_COLUMN_STATS( ownname => 'MVDS',  tabname => v_array(i) , colname => C1.column_name ,  distcnt => i_distinct, density => f_density, nullcnt => i_nullcnt, avgclen => i_avgcol_len, srec => srec);
        DBMS_OUTPUT.PUT_LINE('Column stats : ' || v_array(i) || '.' || rpad(C1.column_name,30)  || ' distinct : ' ||  rpad(i_distinct,20) || ' density : ' ||  rpad(f_density,20) || ' null count : ' ||  rpad(i_nullcnt,20) || ' avg col length : ' || rpad(i_avgcol_len, 20) );

        DBMS_STATS.set_COLUMN_STATS( ownname => USER,  tabname => v_array(i) || s_postfix  , colname => C1.column_name ,  distcnt => i_distinct, density => f_density, nullcnt => i_nullcnt, avgclen => i_avgcol_len, srec => srec);
        END LOOP;

    END LOOP;   

end;
/



------------- CTP LAP INSERT deleting all subpartition stats -----------------------------------------------------------------------------------------------------------



set serveroutput on
declare
  type myarray is table of varchar2(255) index by binary_integer;
  v_array myarray;
begin

v_array(v_array.count + 1) := 'LAP_ASSET_TYPE';     
v_array(v_array.count + 1) := 'LAP_ASSET_REPORT';    
v_array(v_array.count + 1) := 'LAP_ACCOUNT_REPORT'; 
v_array(v_array.count + 1) := 'LAP_ACCOUNTING_RESULT';
v_array(v_array.count + 1) := 'LAP_FILE_LOCATION';  
v_array(v_array.count + 1) := 'LAP_ACCOUNTING_ENTRY';
v_array(v_array.count + 1) := 'LAP_GROUP_DETAILS';  
v_array(v_array.count + 1) := 'LAP_GROUP_STATUS';   



  for i in 1..v_array.count 
  loop
    dbms_output.put_line('doing table : ' || v_array(i));
              for C1 in ( select partition_name, subpartition_name from dba_tab_subpartitions where table_owner = 'ONEBALANCE' and table_name = v_array(i) and partition_name = (select partition_name from dba_tab_partitions where table_name = v_array(i) and table_owner = 'ONEBALANCE' and partition_position = 872 ))
              loop
                 dbms_output.put_line('doing partition' || C1.partition_name || ' doing subpartition : ' || C1.subpartition_name );
            
                DBMS_STATS.delete_table_stats (ownname      => 'ONEBALANCE',
                                            tabname      => v_array(i),
                                            partname     => C1.subpartition_name
                                           );
            
              end loop;
  end loop; 
end;
/

------------------------------------------------------------------------------------------------------------
-- Reports 
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- reporting on tables, indexes and columns which lack any global stats :
------------------------------------------------------------------------------------------------------------

prompt tables without global stats :

define SCHEMA_NAME=MVDS
define REGEXP_PATTERN="CMP|BKP|TEMP|TMP|LOG|BACKUP|M\$"

select S.owner, S.table_name, S.last_analyzed
from 
  dba_tab_statistics S  
where owner = '&SCHEMA_NAME'
and S.object_type = 'TABLE'
and not regexp_like( table_name, '&REGEXP_PATTERN')
and  S.last_analyzed is NULL ;

prompt Indexes without global stats  :

select owner, index_name, table_name,  last_analyzed
from dba_indexes 
where owner = '&SCHEMA_NAME'
and not regexp_like( table_name, '&REGEXP_PATTERN')
and  index_type != 'LOB'
and last_analyzed is NULL;

prompt Columns without global stats :

select owner, table_name, column_name, last_analyzed
from dba_tab_columns C
where owner = '&SCHEMA_NAME'
and not regexp_like( table_name, '&REGEXP_PATTERN')
and not exists (select 1 from dba_views V where V.owner = C.owner and V.view_name = C.table_name)
and last_analyzed is NULL;




-- getting stale stats using dbms_stats

DECLARE 

  ObjList dbms_stats.ObjectTab; 

BEGIN 
  dbms_stats.gather_schema_stats( ownname => 'MERIDIAN', objlist=>ObjList, options=>'LIST STALE'); 
  FOR i IN ObjList.FIRST..ObjList.LAST 
    LOOP 
    dbms_output.put_line(ObjList(i).ownname || '.' || ObjList(i).ObjName || ' ' || ObjList(i).ObjType || ' ' || ObjList(i).partname); 
    END LOOP; 
END; 
/


-- USING OBJ_FILTER_LIST :


set serveroutput on
DECLARE
  i   NUMBER := 0;
  filter_lst DBMS_STATS.OBJECTTAB := DBMS_STATS.OBJECTTAB();
  output_tab_list DBMS_STATS.OBJECTTAB := DBMS_STATS.OBJECTTAB();
BEGIN

FOR table_list IN 
    (
    select owner, table_name
    from dba_tables where
    owner = 'MVDS'
    AND TEMPORARY = 'N'
    AND PARTITIONED = 'NO'
    AND TABLE_NAME NOT LIKE 'N$L%'
    )
LOOP
  i := i + 1;
  filter_lst.extend(1);
  filter_lst(i).ownname := table_list.owner;
  filter_lst(i).objname := table_list.table_name;
END LOOP;

DBMS_OUTPUT.PUT_LINE('Entered ' || i || ' tables in to the list ');


DBMS_STATS.GATHER_SCHEMA_STATS(ownname=>'MVDS', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 4, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                    granularity => 'GLOBAL' ,
                    options => 'GATHER EMPTY',
                    obj_filter_list => filter_lst,
                    objlist => output_tab_list);

DBMS_OUTPUT.PUT_LINE('The following tables were found to be empty :' || output_tab_list.COUNT);



FOR i in 1..output_tab_list.COUNT 
LOOP
           dbms_output.put_line('Object Name: ' || output_tab_list(i).objname );
END LOOP;


DBMS_OUTPUT.PUT_LINE('The following tables were found to be stale :' || output_tab_list.COUNT);



FOR i in 1..output_tab_list.COUNT 
LOOP
           dbms_output.put_line('Object Name: ' || output_tab_list(i).objname );
END LOOP;


END;
/


------------------------- checking for stale and empty objects in onebal_etl ------------------------------------------------------



clear screen
SET SERVEROUTPUT ON
DECLARE 


  ObjList dbms_stats.ObjectTab; 

BEGIN 

    DBMS_OUTPUT.ENABLE (buffer_size => NULL); 

  dbms_stats.gather_schema_stats( ownname => 'ONEBAL_ETL', objlist=>ObjList, options=>'LIST STALE',  granularity => 'GLOBAL'); 
 dbms_output.put_line('TABLES : ' || ObjList.count);

  FOR i IN ObjList.FIRST..ObjList.LAST 
    LOOP 
    dbms_output.put_line(ObjList(i).ObjType  || ' ' ||  ObjList(i).ownname || '.' || ObjList(i).ObjName || ' ' || ObjList(i).partname); 
    END LOOP;

  dbms_stats.gather_schema_stats( ownname => 'ONEBAL_ETL', objlist=>ObjList, options=>'LIST STALE',  granularity => 'PARTITION'); 
 dbms_output.put_line('PARTITIONS : ' || ObjList.count);

  FOR i IN ObjList.FIRST..ObjList.LAST 
    LOOP 
    dbms_output.put_line(ObjList(i).ObjType  || ' ' || ObjList(i).ownname || '.' || ObjList(i).ObjName || ' ' || ObjList(i).partname); 
    END LOOP; 

  dbms_stats.gather_schema_stats( ownname => 'ONEBAL_ETL', objlist=>ObjList, options=>'LIST EMPTY',  granularity => 'PARTITION'); 
  dbms_output.put_line('EMPTY PARTITIONS : ' || ObjList.count);

  FOR i IN ObjList.FIRST..ObjList.LAST 
    LOOP 
    dbms_output.put_line(ObjList(i).ObjType  || ' ' || ObjList(i).ownname || '.' || ObjList(i).ObjName || ' ' || ObjList(i).partname); 
    END LOOP; 

  dbms_stats.gather_schema_stats( ownname => 'ONEBAL_ETL', objlist=>ObjList, options=>'LIST EMPTY',  granularity => 'GLOBAL'); 
  dbms_output.put_line('EMPTY TAbles : ' || ObjList.count);

  FOR i IN ObjList.FIRST..ObjList.LAST 
    LOOP 
    dbms_output.put_line(ObjList(i).ObjType  || ' ' || ObjList(i).ownname || '.' || ObjList(i).ObjName ); 
    END LOOP; 


 
END; 
/
