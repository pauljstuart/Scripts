




clear screen
set serveroutput on
set echo off
whenever sqlerror exit

COLUMN TEMP1 NEW_VALUE MODULE_STRING noprint;
COLUMN TEMP2 NEW_VALUE SQL_ID;
COLUMN TEMP3 NEW_VALUE SQL_EXEC_ID;
COLUMN TEMP4 NEW_VALUE SQL_CHILD_NUM;

define MY_SCHEMA=PERF_SUPPORT
define APP_SCHEMA=APP_FBI_FDR_RPTG

select 'PJS_' || (SELECT instance_name from v$instance) || '_' ||to_char(mod(abs(dbms_random.random),100000)+1) TEMP1 from dual;
set worksheetname  &MODULE_STRING


ALTER SESSION SET  statistics_level='ALL';
ALTER SESSION SET  nls_date_format='dd/mm/yyyy hh24:mi:ss';
alter session set "_sqlmon_threshold"=5;
--alter session set optimizer_dynamic_sampling = 2;
--alter session set "_SERIAL_DIRECT_READ"=true;
--ALTER SESSION SET  OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=TRUE ;
--ALTER SESSION SET  _nlj_batching_enabled=0;   /* Vector IO : 1 = DEFAULT, 0 = disabled */
--ALTER SESION SET "_use_nosegment_indexes"=TRUE;  /* use virtual indexes */
--alter session force parallel query ;
--ALTER SESSION SET  OPTIMIZER_USE_SQL_PLAN_BASELINES=TRUE;
--ALTER SESSION SET  sqltune_category='&CATEGORY_NAME';
--ALTER SESSION SET OPTIMIZER_USE_PENDING_STATISTICS=TRUE;
 alter session set "_sqlmon_max_planlines" = 9000;

declare

  cursor_name      INTEGER;
 



sql_text_clob1 CLOB := q'# 

select count(*) from all_tables

#';






BEGIN

  --select sql_text INTO SQL_TEXT_CLOB from dba_hisT_SQLtext where sql_id = '49pm81gp95bpd';

  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
  dbms_application_info.set_module(q'#&MODULE_STRING#','parse');

  cursor_name := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(cursor_name, '/* &MODULE_STRING */ ' ||  sql_text_clob1  , DBMS_SQL.NATIVE);
  DBMS_SQL.CLOSE_CURSOR(cursor_name);

  dbms_application_info.set_module( NULL, NULL);
  
  for output_line in (
       with xplan_data0 as
        (
        select plan_table_output,  substr( '|....+....+....+....+....+....+....+....+....+....+....+....+', 1, length( regexp_substr( plan_table_output, '(\|\ +)', 2 ) ) ) as paul_string
        from  v$sql S, table(dbms_xplan.display_cursor( s.sql_id , s.child_number, 'ADVANCED ALLSTATS LAST -PROJECTION'))
        WHERE S.module = '&MODULE_STRING' 
        ),
        xplan_data1 as
        (
        select regexp_replace( plan_table_output, '(^\|[\* 0-9]+)(\|\ +)(.*)', '\1' || paul_string || '\3' ) as plan_table_output
        from xplan_data0
        )
      select plan_table_output from xplan_data1
      --select paul_string from xplan_data0
  )
  loop
    dbms_output.put_line( output_line.plan_table_output );
  end loop;

  dbms_output.put_line('Module : &MODULE_STRING'  );

END;
/



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  end of parsing
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



/*




*/




----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  run it
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


create or replace procedure &MODULE_STRING as

  cursor_name      INTEGER;
  s_service_name   VARCHAR2(256);
  total_fetches    INTEGER := 0;
  timestart        NUMBER := dbms_utility.get_time();
  i_elapsed_time    NUMBER;
  s_tracefile_name  VARCHAR2(256);
  ret              INTEGER;
  sql_id_cur      SYS_REFCURSOR;
  sql_text_clob  CLOB ;

BEGIN

  DBMS_OUTPUT.ENABLE ( NULL );

------------------ create stats table and load the first stats -------------------  

  BEGIN
      EXECUTE IMMEDIATE 'DELETE FROM T_SQL WHERE MODULE_NAME = ''&MODULE_STRING'' ';
      execute immediate 'INSERT INTO T_SQL (MODULE_NAME, STAT_NUMBER, BEFORE_VALUE) SELECT ''&MODULE_STRING'', STATISTIC#, VALUE FROM V$MYSTAT ';
     dbms_output.put_line('T_SQL found.');
  EXCEPTION
  WHEN OTHERS THEN
          BEGIN
           EXECUTE immediate 'create  table T_SQL   ( MODULE_NAME VARCHAR2(128), STAT_NUMBER INTEGER, BEFORE_VALUE INTEGER, AFTER_VALUE INTEGER, DELTA_VALUE INTEGER) ' ;
            dbms_output.put_line('T_SQL created.');
          EXCEPTION
          WHEN OTHERS THEN
            dbms_output.put_line( 'Couldnt create T_SQL  : '||SQLERRM);
            --RAISE_APPLICATION_ERROR(-20000, 'Couldnt create T_SQL : ' || SQLERRM );
          END;
  END;

----------------- now execute the SQL ------------------------------------------------

  BEGIN
    select sql_fulltext into sql_text_clob from  v$sql where module = '&MODULE_STRING' AND ROWNUM = 1;
  EXCEPTION
    when NO_DATA_FOUND then
    DBMS_OUTPUT.PUT_LINE('Couldnt find &MODULE_STRING in cursor cache - ' || SQLERRM );
   -- RAISE_APPLICATION_ERROR(-20001,'Couldnt find &MODULE_STRING in cursor cache - ' || SQLERRM );
  END;


   begin
     --execute immediate q'#alter session set tracefile_identifier='&MODULE_STRING' #'; 
     --execute immediate q'#alter session set max_dump_file_size='UNLIMITED' #';
     execute immediate q'# ALTER SESSION SET  statistics_level='ALL' #';
     dbms_application_info.set_module(q'#&MODULE_STRING#', 'execute');
     -- DBMS_SESSION.SESSION_TRACE_ENABLE(waits => TRUE, binds => FALSE);
      --for  trace_name_list in (select  regexp_replace(tracefile, '.*/') tracefile_name
       --           FROM  gv$session s 
      --            INNER JOIN  gv$process p ON  s.paddr = p.addr and S.inst_id = P.inst_id
      --            where module = '&MODULE_STRING')
      --       LOOP
      --       DBMS_OUTPUT.PUT_LINE(chr(10) || 'Trace file name : ' || trace_name_list.tracefile_name );
      --       END LOOP;
     cursor_name := DBMS_SQL.OPEN_CURSOR;
    
      DBMS_SQL.PARSE(cursor_name,  sql_text_clob , DBMS_SQL.NATIVE);

    ret := DBMS_SQL.EXECUTE(cursor_name);
    dbms_application_info.set_module( NULL, NULL);
  EXCEPTION
      WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ISSUES compiling SQL - ' || SQLERRM);
      dbms_output.put_line( sql_text_clob);
   end ;

   LOOP                                        
    ret := DBMS_SQL.FETCH_ROWS(cursor_name);
    EXIT WHEN ret = 0;
    total_fetches := total_fetches + 1;
  END LOOP;


  DBMS_SQL.CLOSE_CURSOR(cursor_name);
  --  DBMS_SESSION.SESSION_TRACE_DISABLE();

  i_elapsed_time := (dbms_utility.get_time() - timestart)/100;

  DBMS_OUTPUT.PUT_LINE( chr(10) || 'Fetched : ' || total_fetches || ' rows in '|| i_elapsed_time || ' secs.' || chr(10) );

----------------------------- 2nd stats snapshot --------------------------------------------------

  execute immediate 'UPDATE T_SQL SET after_value = (SELECT value FROM v$mystat WHERE v$mystat.statistic# = T_SQL.STAT_NUMBER) WHERE T_SQL.MODULE_NAME = ''&MODULE_STRING'' ';   
  EXECUTE IMMEDIATE 'update T_SQL SET DELTA_VALUE = AFTER_VALUE - BEFORE_VALUE';
  EXECUTE IMMEDIATE 'DELETE FROM T_SQL WHERE DELTA_VALUE = 0';
  execute immediate 'insert into T_SQL (MODULE_NAME, STAT_NUMBER, DELTA_VALUE)  values ( ''&MODULE_STRING'',  4099,  ' || i_elapsed_time || '  )';
  commit;

END;
/




----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  end of proc 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- start scheduler job
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




DECLARE
  i_instance INTEGER;
 begin

  SELECT INSTANCE_NUMBER INTO i_instance from v$instance;

  for f in (select 1 from dual where exists (select * from user_scheduler_jobs where job_name = 'S_&MODULE_STRING'))
    loop
     DBMS_SCHEDULER.DROP_JOB(JOB_NAME => 'S_&MODULE_STRING');
    end loop;

    dbms_scheduler.create_job 
    (  
      job_name      =>  'S_&MODULE_STRING',  
      job_type      =>  'PLSQL_BLOCK',  
      job_action    =>  'begin &MODULE_STRING ; end;',  
      start_date    =>  current_timestamp,  
      enabled       =>  FALSE,  
      auto_drop     =>  TRUE,  
      comments      =>  'one-time job');
     dbms_scheduler.set_attribute(name => 'S_&MODULE_STRING' ,attribute=>'INSTANCE_ID', value=> i_instance);  
     dbms_scheduler.enable(name => 'S_&MODULE_STRING' );
end;
/



@scheduler_jobs S_&MODULE_STRING

@SCHEDULER_HIST S_&MODULE_STRING


begin 
dbms_scheduler.stop_job('S_&MODULE_STRING');
drop procedure &MODULE_STRING';
end;


    



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  reports section
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- set the SQL_ID variables 


column module format A40
select   '&MODULE_STRING' AS module,  sql_id AS  TEMP2, sql_exec_id AS TEMP3 , child_number  AS TEMP4 
from 
    (select SM.*, SS.child_number
     from Gv$sql_monitor SM 
    inner join gv$sql SS ON SM.inst_id = SS.inst_id and SS.child_address = SM.sql_child_address
    WHERE SM.module = '&MODULE_STRING'  
    order by sql_exec_start desc
    ) 
where rownum = 1;



prompt 
prompt -------------------- TSQL basic report  ----------------------------------------
prompt 

@reports/tsql_basic_report.sql
 

-------------------- display_cursor   ----------------------------------------


@sql/display_cursor.sql &SQL_ID &SQL_CHILD_NUM "ADVANCED ALLSTATS LAST"


-------------------- SQL monitor reports ----------------------------------------

 
@sql/sql_monitor2 &SQL_ID %


@reports/sql_monitor_report &SQL_ID &SQL_EXEC_ID


@sql/sql_monitor_px &ARG


prompt 
prompt -------------------- SQL statistics report  ----------------------------------------
prompt 

@reports/tsql_exadata_report

prompt 
prompt -------------------- SQL DB time report  ----------------------------------------
prompt


@ash/ash_sql_dbtime &SQL_ID &SQL_EXEC_ID



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- end of reports
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

