

Creating STS :


BEGIN
DBMS_SQLTUNE.CREATE_SQLSET ( sqlset_name => 'dev92patch_2', description => 'Additional 55 statements');

END;




BEGIN
DBMS_SQLTUNE.DELETE_SQLSET ('dev92patch');
SYS.DBMS_SQLTUNE.CREATE_SQLSET (
sqlset_name => 'dev92patch',
description => 'dev92patch dealsink queries');
END;




**********************************************************************************
*
* Populating the STS from the Cursor Cache:
*
***********************************************************************************



EXEC DBMS_SQLTUNE.CAPTURE_CURSOR_CACHE_SQLSET( -
                                        sqlset_name     => 'my_workload', -
                                        time_limit      =>  30, -
                                        repeat_interval =>  5);

begin
DBMS_SQLTUNE.CAPTURE_CURSOR_CACHE_SQLSET( sqlset_name => 'dev92apatch_2', 
                                   time_limit => 36000, 
                                  repeat_interval => 5, 
                                  capture_option => 'MERGE' , 
                                  capture_mode => dbms_sqltune.MODE_ACCUMULATE_STATS, 
          basic_filter => 'MODULE like ''gdfp%'' ' );
end;  
      

DECLARE
  stscur dbms_sqltune.sqlset_cursor;
BEGIN
  OPEN stscur FOR
  SELECT VALUE(P)
      FROM TABLE(dbms_sqltune.select_cursor_cache(  ‘parsing_schema_name <> ‘‘SYS’’’,null, null, null, null, 1, null, 'ALL')) P;
  
  -- populate the sqlset 
  dbms_sqltune.load_sqlset(sqlset_name => 'SPM_STS',populate_cursor => stscur);
END;


Populating from the AWR based on SQL text values :

select * from  table(dbms_sqltune.select_workload_repository( &begin_snap_id, &end_snap_id, 
  ' parsing_schema_name = ''STORM_OWNER'' AND (
   dbms_lob.instr(sql_text, ''RATE_COMPONENTS'' ) > 0 
OR dbms_lob.instr(sql_text, ''RATE_HEADERS'' ) > 0 
OR dbms_lob.instr(sql_text, ''TRADE_HEADERS'' ) > 0 
OR dbms_lob.instr(sql_text, ''UNILATERAL_COMPONENTS'' ) > 0 
OR dbms_lob.instr(sql_text, ''CONTRACT_REVISION_PARTICIPANTS'' ) > 0 )  ' ) );



Populating from the AWR :



select distinct snap_id, begin_interval_time, end_interval_time
from dba_hist_snapshot
where instance_number = 1
and begin_interval_time > sysdate -1
order by 2 asc;



$ cat sql_workload.sql


BEGIN

DBMS_SQLTUNE.DELETE_SQLSET ('SPA_STS');


**********************************************************************************
*
* populating STS - advanced
*
***********************************************************************************


DECLARE
        ref_cur DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
OPEN ref_cur FOR SELECT VALUE(p) FROM table(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY( begin_snap => 1, 
                                                               end_snap => 2, 
                        basic_filter =>  ' parsing_schema_name = ''SWAPP_OWNER'' and MODULE like ''gdfp%'' ' )) p;
DBMS_SQLTUNE.LOAD_SQLSET('dev92patch', ref_cur);

END;



populating based on an advanced query on another STS :

set serveroutput on;

DECLARE

CURSOR desired_modules_cur IS 
  SELECT module  
  FROM
  (
    select  before_sts.module,
        before_sts.buffer_gets before_buffer_gets, 
         after_sts.buffer_gets after_buffer_gets,
         (after_sts.buffer_gets  - before_sts.buffer_gets)*100/before_sts.buffer_gets  difference_pct
    from 
    ( select * from DBA_SQLSET_STATEMENTS where ( sqlset_name = 'dev92patch' or sqlset_name = 'dev92patch_2' ) ) before_sts, 
    ( select * from DBA_SQLSET_STATEMENTS where sqlset_name = 'dev92apatch_2' ) after_sts
    where before_sts.module = after_sts.module
  )
  WHERE difference_pct <= 0;

  --module_rec   desired_modules_cur%ROWTYPE;
  module_rec     VARCHAR2(256);


  ref_cur DBMS_SQLTUNE.SQLSET_CURSOR;
  criteria VARCHAR2(256);
  
BEGIN

  OPEN desired_modules_cur;
  LOOP
      FETCH desired_modules_cur INTO module_rec;
      EXIT WHEN desired_modules_cur%NOTFOUND;
      criteria := ' module =  ''' || module_rec || ''''  ;
      DBMS_OUTPUT.PUT_LINE( 'criteria is : ' || criteria  );
      OPEN ref_cur FOR SELECT VALUE(p) FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET( 'dev92apatch_2', basic_filter => '' || criteria || ''   ))  p;
      DBMS_SQLTUNE.LOAD_SQLSET('dev92a_good_baselines', ref_cur);
  END LOOP;
  
END;




**********************************************************************************
*
* moving sql tuning sets
*
***********************************************************************************

EXEC DBMS_SQLTUNE.CREATE_STGTAB_SQLSET(table_name => 'DEV92APATCH_TAB');



EXEC DBMS_SQLTUNE.PACK_STGTAB_SQLSET(sqlset_name => 'dev92apatch', staging_table_name => 'DEV92APATCH_TAB');



begin
DBMS_SQLTUNE.UNPACK_STGTAB_SQLSET(sqlset_name => '%', sqlset_owner => '%', replace => TRUE, staging_table_name => 'DEV92PATCH_2_TAB', staging_schema_owner => 'PSTUART');
end;


**********************************************************************************
*
* deleting from sql tuning sets
*
***********************************************************************************

DBMS_SQLTUNE.DELETE_SQLSET ('SPA_STS');

EXEC DBMS_SQLTUNE.DELETE_SQLSET(sqlset_name   => 'dev92apatch', basic_filter  => 'sql_text like ''begin DBMS_APPLICATION_INFO.SET_MODULE%'' ');
                                
                                
                                
*************************************************************************

to query SQL Tuning Sets :

**************************************************************************


SELECT * FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET( 'SPM_STS' ) );


select * from
table(dbms_sqltune.select_workload_repository( &begin_snap_id, &end_snap_id, 'parsing_schema_name in ( ''SWAPP_OWNER'' , ''STORM_OWNER'', ''OPS$SWAPSAPP'', ''SWREF_OWNER'', ''SWSEC_OWNER'')  ') );


select * from
table(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY( begin_snap => 1, 
                                                               end_snap => 2, 
                        basic_filter =>  ' parsing_schema_name = ''SWAPP_OWNER'' and MODULE like ''gdfp%'' ' ));
                        

SELECT sql_plan FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET( 'TEST_STS', null, null, null,null, null, 1, null, 'ALL' ) );


SELECT * FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET( 'my_sql_tuning_set', '(disk_reads/buffer_gets) >= 0.75'));





Using USER_SQLSET_STATEMENTS


select sqlset_name, sql_id, plan_hash_value, elapsed_time, cpu_time, buffer_gets, disk_reads, rows_processed, fetches, executions, optimizer_cost
from user_sqlset_statements;



**********************************************************************************
*
* joining a before and after STS based on the module column
*
***********************************************************************************



COLUMN DIFFERENCE_PCT FORMAT 999,999.00;
COLUMN module FORMAT a30;

select  before_sts.module,
        before_sts.buffer_gets before_buffer_gets, 
         after_sts.buffer_gets after_buffer_gets,
         (after_sts.buffer_gets  - before_sts.buffer_gets)*100/before_sts.buffer_gets  difference_pct
from 
( select * from DBA_SQLSET_STATEMENTS where sqlset_name = 'dev92patch' and plan_hash_value != 0) before_sts, 
( select * from DBA_SQLSET_STATEMENTS where sqlset_name = 'dev92apatch' and plan_hash_value != 0) after_sts
where before_sts.module = after_sts.module
order by 4 ;





select  before_sts.module,
        before_sts.buffer_gets before_buffer_gets, 
         after_sts.buffer_gets after_buffer_gets,
         (after_sts.buffer_gets  - before_sts.buffer_gets)*100/before_sts.buffer_gets  difference_pct
from 
( select * from DBA_SQLSET_STATEMENTS where (sqlset_name = 'dev92patch_3' OR sqlset_name = 'dev93patch_4') and sql_text like 'SELECT%') before_sts, 
( select * from DBA_SQLSET_STATEMENTS where (sqlset_name = 'dev92apatch_3' OR sqlset_name = 'dev93apatch_4') and sql_text like 'SELECT%') after_sts
where before_sts.module = after_sts.module
order by 4 ;


**********************************************************************************
*
* loading the SQL baselines from a STS
*
***********************************************************************************



DECLARE
  results    PLS_INTEGER;
BEGIN


results := DBMS_SPM.LOAD_PLANS_FROM_SQLSET ( sqlset_name  => 'dev92a_good_baselines');
DBMS_OUTPUT.PUT_LINE('There were ' || results || ' loaded.' );

END;


******************************************************************
*
* load only certain SQL into our baseline STS
*
*****************************************************************



set serveroutput on;

DECLARE

CURSOR desired_modules_cur IS 
  SELECT module  
  FROM
  (
    select  before_sts.module,
        before_sts.buffer_gets before_buffer_gets, 
         after_sts.buffer_gets after_buffer_gets,
         (after_sts.buffer_gets  - before_sts.buffer_gets)*100/before_sts.buffer_gets  difference_pct
    from 
    ( select * from DBA_SQLSET_STATEMENTS where ( sqlset_name = 'dev92patch' or sqlset_name = 'dev92patch_2' ) ) before_sts, 
    ( select * from DBA_SQLSET_STATEMENTS where sqlset_name = 'dev92apatch_2' ) after_sts
    where before_sts.module = after_sts.module
  )
  WHERE difference_pct <= 0;

  --module_rec   desired_modules_cur%ROWTYPE;
  module_rec     VARCHAR2(256);


  ref_cur DBMS_SQLTUNE.SQLSET_CURSOR;
  criteria VARCHAR2(256);
  
BEGIN

  OPEN desired_modules_cur;
  LOOP
      FETCH desired_modules_cur INTO module_rec;
      EXIT WHEN desired_modules_cur%NOTFOUND;
      criteria := ' module =  ''' || module_rec || ''''  ;
      DBMS_OUTPUT.PUT_LINE( 'criteria is : ' || criteria  );
      OPEN ref_cur FOR SELECT VALUE(p) FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET( 'dev92apatch_2', basic_filter => '' || criteria || ''   ))  p;
      DBMS_SQLTUNE.LOAD_SQLSET('dev92a_good_baselines', ref_cur);
  END LOOP;
  
END;


*************************************************************
*
* now remove the MODULE and add our description to them
*
************************************************************





DECLARE

  
  CURSOR desired_sql_ids_cur IS 
    SELECT sql_id 
    FROM dba_sqlset_statements  
   WHERE sqlset_name = 'dev92a_good_baselines';

  results      number;
  this_sql     VARCHAR2(256);

BEGIN
  results := 0;
  
  OPEN desired_sql_ids_cur;
  LOOP
      FETCH desired_sql_ids_cur INTO this_sql;
      EXIT WHEN desired_sql_ids_cur%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE( 'Changing  : ' || this_sql  );
      DBMS_SQLTUNE.UPDATE_SQLSET( sqlset_name  =>'dev92a_good_baselines', sql_id => this_sql,attribute_name => 'MODULE', attribute_value => '');
      DBMS_SQLTUNE.UPDATE_SQLSET( sqlset_name  =>'dev92a_good_baselines', sql_id => this_sql,attribute_name => 'OTHER', attribute_value => '921 dealsink baseline');

      results := results +1;
  END LOOP;
   DBMS_OUTPUT.PUT_LINE( 'There were '  || results || ' modified.'  );
END;

**********************************************************************************
*
* Now load the baselines into the SQL base
*
*
**********************************************************************************



DECLARE
  results    PLS_INTEGER;
BEGIN


results := DBMS_SPM.LOAD_PLANS_FROM_SQLSET ( sqlset_name  => 'dev92a_good_baselines');
DBMS_OUTPUT.PUT_LINE('There were ' || results || ' loaded.' );

END;


**********************************************************************************
*
* loading a single plan into the base

**************************************************


declare 
  result  number;
begin
result := DBMS_SPM.LOAD_PLANS_FROM_SQLSET( sqlset_name  => 'dev92apatch_4', basic_filter => ' module = ''gdfp_5''  ');
end;


*************************************************************
*
* Change the attributes of the SQL plans in the base
*
************************************************************


DECLARE

  
  CURSOR desired_sql_ids_cur IS 
    SELECT sql_id
    FROM dba_sqlset_statements  
   WHERE sqlset_name = 'dev92a_good_baselines';

  CURSOR desired_sql_handles IS
    SELECT sql_handle
    FROM   dba_sql_plan_baselines
    WHERE sql_id
  results      number;
  this_sql     VARCHAR2(256);

BEGIN
  results := 0;
  
  OPEN desired_sql_ids_cur;
  LOOP
      FETCH desired_sql_ids_cur INTO this_sql;
      EXIT WHEN desired_sql_ids_cur%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE( 'Changing  : ' || this_sql  );
      
      DBMS_SPM.ALTER_SQL_PLAN_BASELINE( sql_handle  =>  this_handle,attribute_name => 'MODULE', attribute_value => 'good_plan_for_export');

      results := results +1;
  END LOOP;
   DBMS_OUTPUT.PUT_LINE( 'There were '  || results || ' modified.'  );
END;


*************************************************************
*
* now pack only the SQL baselines from a particular STS using the MODULE column to get the baseline
* from the SQL base.
*
***********************************************************


create table desired_sql_ids (module VARCHAR2(256) );
insert into desired_sql_ids values ('gdfp_9');
insert into desired_sql_ids values ('gdfp_81');
insert into desired_sql_ids values ('gdfp_77');
insert into desired_sql_ids values ('gdfp_64');
insert into desired_sql_ids values ('gdfp_5');
insert into desired_sql_ids values ('gdfp_21');
insert into desired_sql_ids values ('gdfp_29');
insert into desired_sql_ids values ('gdfp_259');
insert into desired_sql_ids values ('gdfp_2');
insert into desired_sql_ids values ('gdfp_178');
insert into desired_sql_ids values ('gdfp_15');


exec DBMS_SPM.CREATE_STGTAB_BASELINE('DEV92A_GOOD_BASELINES');

DECLARE
/*
  CURSOR desired_module_names_cur IS 
    SELECT module
    FROM dba_sqlset_statements  
   WHERE sqlset_name = 'dev92a_good_baselines';
*/

 CURSOR desired_module_names_cur IS 
    SELECT module
    FROM desired_sql_ids;
   
  total_packed      number;
  this_result    number;
  this_module     VARCHAR2(256);
  
BEGIN
  total_packed := 0;
  
  OPEN desired_module_names_cur;
  LOOP
      FETCH desired_module_names_cur INTO this_module;
      EXIT WHEN desired_module_names_cur%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE( 'Packing module : ' || this_module  );
      
      this_result := 0;
      this_result := DBMS_SPM.PACK_STGTAB_BASELINE( table_name  =>'DEV92A_GOOD_BASELINES', module => this_module   ) ;
     total_packed := total_packed + this_result;
  END LOOP;
BEGIN
     
   DBMS_OUTPUT.PUT_LINE( 'There were '  || total_packed || ' baselines packed.'  );
END;


********************************************
*
* loading the baselines into the database.
*
********************************************

declare
  result number;
begin
  result := DBMS_SPM.UNPACK_STGTAB_BASELINE( 'DEV92A_GOOD_BASELINES');
end; 





****************************************************************************************
*
* reporting on before and after values from 2 STS
*
****************************************************************************************

COLUMN DIFFERENCE_PCT FORMAT 999,999.00;
COLUMN module FORMAT a30;

clear screen

select  before_sts.module,  'run1',
        before_sts.buffer_gets before_buffer_gets, 
         after_sts.buffer_gets after_buffer_gets,
         before_sts.rows_processed before_rows,
         after_sts.rows_processed after_rows,
         before_sts.fetches before_fetches,
         after_sts.fetches after_fetches,
         (after_sts.buffer_gets  - before_sts.buffer_gets)*100/before_sts.buffer_gets  difference_pct
from 
( select * from DBA_SQLSET_STATEMENTS where (sqlset_name = 'dev92patch_3' ) and sql_text like 'SELECT%' and fetches != 0) before_sts, 
( select * from DBA_SQLSET_STATEMENTS where (sqlset_name = 'dev92apatch_3' ) and sql_text like 'SELECT%' and fetches != 0) after_sts
where before_sts.module = after_sts.module
UNION
select  before_sts.module,  'run2',
        before_sts.buffer_gets before_buffer_gets, 
         after_sts.buffer_gets after_buffer_gets,
        before_sts.rows_processed before_rows,
         after_sts.rows_processed after_rows,
          before_sts.fetches before_fetches,
         after_sts.fetches after_fetches,
         (after_sts.buffer_gets  - before_sts.buffer_gets)*100/before_sts.buffer_gets  difference_pct
from 
( select * from DBA_SQLSET_STATEMENTS where (sqlset_name = 'dev92patch_4' ) and sql_text like 'SELECT%' and fetches != 0) before_sts, 
( select * from DBA_SQLSET_STATEMENTS where (sqlset_name = 'dev92apatch_4' ) and sql_text like 'SELECT%' and fetches != 0) after_sts
where before_sts.module = after_sts.module
order by 1;

----------------------------------------------------------------------------
-- Load in all the SQL from a set of AWR snapshots (ie a after period)
----------------------------------------------------------------------------

DECLARE
        ref_cur DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN

DBMS_SQLTUNE.delete_SQLSET('SW_9.3_SQL');

open ref_cur for select VALUE(p) from table( DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY( begin_snap => 39746, end_snap => 39823,
                       basic_filter => 'parsing_schema_name in ( ''SWAPP_OWNER'' , ''STORM_OWNER'', ''OPS$SWAPSAPP'', ''SWREF_OWNER'', ''SWSEC_OWNER'')  ' )) p;
DBMS_SQLTUNE.LOAD_SQLSET('SW_9.3_SQL', ref_cur);
end;


SELECT count(*) FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET( 'SW_9.3_SQL' ) );

set serveroutput on 

----------------------------------------------------------------------------
-- Now delete all the sql_id from the previous period, in order to end up with the delta
-- ie new or modified SQL (after period).
----------------------------------------------------------------------------
                      
DECLARE
       
      CURSOR  old_92_sql is  select distinct sql_id from dba_hist_sqlstat   
                      WHERE snap_id >= 58317 and snap_id < 58894
                      AND parsing_schema_name in ( 'SWAPP_OWNER' , 'STORM_OWNER', 'OPS$SWAPSAPP', 'SWREF_OWNER', 'SWSEC_OWNER');
                      
    this_sql old_92_sql%ROWTYPE;
BEGIN

OPEN old_92_sql;
LOOP                                        
  FETCH old_92_sql into this_sql;
  EXIT WHEN old_92_sql%NOTFOUND;
  dbms_output.put_line( 'deleting sql_id =  ''' || this_sql.sql_id  || '''  ');
  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', 'sql_id =  ''' || this_sql.sql_id  || '''  ' );
  
END LOOP;

commit;
dbms_output.put_line('end');

END;



SELECT count(*) FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET( 'SW_9.3_SQL' ) );


-------------------------------------------------------------------------------------
-- further tidying
-------------------------------------------------------------------------------------

exec dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' sql_text like ''%SQL Analyze%'' ' );
exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' sql_text like ''%DS_SVC%'' ' );

exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' sql_text like ''DELETE%'' ' );
exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' sql_text like ''UPDATE%'' ' );
exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' sql_text like ''INSERT%'' ' );
exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' sql_text like ''BEGIN%'' ' );
exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' sql_text like ''begin%'' ' );



exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' module like ''%plsqldev%'' ' );
exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' module like ''%Developer%'' ' );
exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' module like ''%developer%'' ' );   
exec  dbms_sqltune.delete_sqlset( 'SW_9.3_SQL', ' module like ''%SQL*Plus%'' ' ); 



-------------------------------------------------------------------------------------
-- end of section
