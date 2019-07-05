

set serveroutput on

ALTER SESSION SET  statistics_level='ALL';
ALTER SESSION SET  nls_date_format='dd/mm/yyyy hh24:mi:ss';
alter session set "_sqlmon_threshold"=5;
alter session set "_sqlmon_max_planlines" = 9000;
alter session set max_dump_file_size='UNLIMITED';
--alter session set optimizer_dynamic_sampling = 2;
--alter session set "_SERIAL_DIRECT_READ"=true;
--ALTER SESSION SET  OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=TRUE ;
--ALTER SESSION SET  _nlj_batching_enabled=0;   /* Vector IO : 1 = DEFAULT, 0 = disabled */
--ALTER SESION SET "_use_nosegment_indexes"=TRUE;  /* use virtual indexes */
--alter session force parallel query ;
--ALTER SESSION SET  OPTIMIZER_USE_SQL_PLAN_BASELINES=TRUE;
--ALTER SESSION SET  sqltune_category='&CATEGORY_NAME';
--ALTER SESSION SET OPTIMIZER_USE_PENDING_STATISTICS=TRUE;
--alter session set "_optimizer_cartesian_enabled"=false
--alter session set events '10104 trace name context off'; /* HASH join tracing */
--alter session set "_OPTIMIZER_USE_FEEDBACK"=FALSE;
--alter session set OPTIMIZER_USE_INVISIBLE_INDEXES=true;
--alter session set "_kcfis_storageidx_disabled"=true;
--alter session set "_subquery_pruning_enabled" = false;

-- alter session enable parallel dml;

clear screen

define MY_SCHEMA=PERF_SUPPORT
define APP_SCHEMA=PERF_SUPPORT

alter session set current_schema=&APP_SCHEMA ;
declare

  cursor_name      INTEGER;
  module_string   VARCHAR2(64) := 'PJS_'  || to_char(mod(abs(dbms_random.random),100000)+1) ;
  sql_text_clob  CLOB := q'#


WITH "SQL_Underlying_OS_RiskPnL"
     AS (  SELECT /*+ leading(f vf fv lc cl )  cardinality(400E6) full(VW_OV_CALC_FACT_NEW_V02.vf) swap_join_inputs(VW_OV_CALC_FACT_NEW_V02.fv) swap_join_inputs(VW_OV_CALC_FACT_NEW_V02.vf) swap_join_inputs(VW_OV_CALC_FACT_NEW_V02.cl) swap_join_inputs(VW_OV_CALC_FACT_NEW_V02.lc) use_hash(VW_OV_CALC_FACT_NEW_V02.lc)
              use_hash(VW_OV_CALC_FACT_NEW_V02.cl) use_hash(VW_OV_CALC_FACT_NEW_V02.f) full(VW_OV_CALC_FACT_NEW_V02.f) parallel(VW_OV_CALC_FACT_NEW_V02.f,4) */
                 user_sec.ENTITY,
                  MARKET_DATASET.ALT_INSTRUMENT_ID,
                  ATTRIBUTE_HIERARCHY.L4_ATTRIBUTE,
                  ATTRIBUTE_HIERARCHY.L5_ATTRIBUTE,
                  ATTRIBUTE_HIERARCHY.L5_ATTRIBUTE_DISPLAY_ORDER,
                  SUM (VW_OV_CALC_FACT_NEW_V02.AMOUNT_USD_DLY) Daily_USD,
                  VW_REPORTING_DATE.T1_REPORTING_DATE,



#';

BEGIN

  --select sql_text INTO SQL_TEXT_CLOB from dba_hisT_SQLtext where sql_id = 'ak0h9u3jham13' and dbid = (select dbid from v$database);

  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
  dbms_application_info.set_module( module_string,'parse');

  cursor_name := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(cursor_name, '/* ' || module_string || ' */ ' ||  sql_text_clob   , DBMS_SQL.NATIVE);
  DBMS_SQL.CLOSE_CURSOR(cursor_name);

  dbms_application_info.set_module( NULL, NULL);
  dbms_application_info.set_client_info(module_string);
  COMMIT;
  for output_line in (
       with xplan_data0 as
        (
        select plan_table_output,  substr( '|....+....+....+....+....+....+....+....+....+....+....+....+', 1, length( regexp_substr( plan_table_output, '(\|\ +)', 2 ) ) ) as paul_string
        from  v$sql S, table(dbms_xplan.display_cursor( s.sql_id , s.child_number, 'ADVANCED ALLSTATS LAST -PROJECTION'))
        WHERE S.module = module_string
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

  dbms_output.put_line('Module : ' || module_string  );

END;
/

alter session set current_schema=&MY_SCHEMA;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  end of parsing
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  run it
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
alter session set current_schema=&APP_SCHEMA ;
set worksheetname  (running)
 
DECLARE
  TYPE             ASSOC_ARRAY_T IS TABLE OF INTEGER  INDEX BY VARCHAR2(256);
  StatArray        ASSOC_ARRAY_T;
  s_SQL_ID VARCHAR2(13);
  i_CHILD_NO integer;
  i_SQL_EXEC_ID integer;
  cursor_name      INTEGER;
  s_service_name   VARCHAR2(256);
  total_fetches    INTEGER := 0;
  timestart        NUMBER := dbms_utility.get_time();
  i_elapsed_time    NUMBER;
  adjusted_value   NUMBER;
  s_tracefile_name  VARCHAR2(256);
  ret              INTEGER;
  sql_id_cur      SYS_REFCURSOR;
  module_string VARCHAR2(64) ;
  sql_text_clob  CLOB ;

-------------- Insert the Bind Variables here ---------------------------------

	B1  VARCHAR(32) := 'GMIA2' ;
	B2  NUMBER      :=  1481929235 ;

BEGIN

----------------------------- 1st stats snapshot --------------------------------------------------

FOR r IN (select SN.name, SS.value FROM v$mystat SS, v$statname SN WHERE SS.statistic# = SN.statistic#) 
  LOOP
     --dbms_output.put_line('loading ' || r.name );
    StatArray(r.name) := r.value;
  END LOOP;

----------------- now execute the SQL ------------------------------------------------

  dbms_application_info.read_client_info( module_string);
  BEGIN
    select sql_fulltext into sql_text_clob from  v$sql where module = module_string AND ROWNUM = 1;
  EXCEPTION
    when NO_DATA_FOUND then
    DBMS_OUTPUT.PUT_LINE('Couldnt find ' || module_string || ' in cursor cache - ' || SQLERRM );
    RAISE_APPLICATION_ERROR(-20002,'Couldnt find ' || module_string || ' in cursor cache - ' || SQLERRM );
  END;

   begin
     --execute immediate 'alter session set tracefile_identifier=' || module_string ;
     --DBMS_SESSION.SESSION_TRACE_ENABLE(waits => TRUE, binds => FALSE);
     dbms_application_info.set_module( module_string, 'execute');

     cursor_name := DBMS_SQL.OPEN_CURSOR;
     DBMS_SQL.PARSE(cursor_name,  sql_text_clob , DBMS_SQL.NATIVE);
    --DBMS_SQL.BIND_VARIABLE_CHAR(cursor_name,      ':1', B1 );
    --DBMS_SQL.BIND_VARIABLE(cursor_name,   ':2', B2 );
    ret := DBMS_SQL.EXECUTE(cursor_name);
   
  EXCEPTION
      WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ISSUES compiling SQL - ' || SQLERRM);
   end ;

   LOOP                                        
    ret := DBMS_SQL.FETCH_ROWS(cursor_name);
    EXIT WHEN ret = 0;
    total_fetches := total_fetches + 1;
  END LOOP;

   dbms_application_info.set_module( NULL, NULL);
  DBMS_SQL.CLOSE_CURSOR(cursor_name);
  DBMS_SESSION.SESSION_TRACE_DISABLE();

  i_elapsed_time := (dbms_utility.get_time() - timestart)/100;


-------------Now get the SQ_EXEC_ID for the statement --------------------


  begin
    select  prev_sql_id, prev_child_number ,prev_exec_id into s_SQL_ID, i_CHILD_NO, i_SQL_EXEC_ID
    from v$session
    where sid = dbms_debug_jdwp.current_session_id and serial#  = dbms_debug_jdwp.current_session_serial ;
    DBMS_OUTPUT.PUT_LINE('SQL_ID : ' || s_SQL_ID || ' SQL_EXEC_ID : ' || i_SQL_EXEC_ID || ' SQL_CHILD_NO : ' || i_CHILD_NO);
  EXCEPTION
    when NO_DATA_FOUND THEN
      dbms_output.put_line( 'Problems finding the SQL_ID  - ' || SQLERRM);
    when TOO_MANY_ROWS then
       dbms_output.put_line('Module ' || module_string || ' has duplicate SQL!');
  end;
  

  DBMS_OUTPUT.PUT_LINE( chr(10) || 'Fetched : ' || total_fetches || ' rows in '|| i_elapsed_time || ' secs.' || chr(10) );

----------------------------- Output the stats, adjusting for the existing values in v$mystat --------------------------------------------------

for stats_cursor in (
                  select /*+ PUSH_PRED(SS) */ sn.name, sum(value) as value
                  from gv$sesstat ss
                  inner join v$statname sn on sn.statistic# = ss.statistic#
                  inner join  gv$sql_monitor sm on sm.inst_id = ss.inst_id and sm.sid = ss.sid  and sm.sql_id =  s_SQL_ID and sm.sql_exec_id = i_SQL_EXEC_ID 
                  and value != 0
                  group by sn.name
                  order by sn.name
                )
  loop
  adjusted_value := stats_cursor.value -  StatArray(stats_cursor.name);
  if ( adjusted_value != 0) then
  dbms_output.put_line( rpad(stats_cursor.name, 40) || ' : ' || lpad(to_char(adjusted_value,'999,999,999,999,999'),35)  );
  end if;
  end loop;

  DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Back to basics report : ' || chr(10));

  for stats_cursor in (
                  select /*+ PUSH_PRED(SS) */ sn.name, sum(value) as value
                  from gv$sesstat ss
                  inner join v$statname sn on sn.statistic# = ss.statistic#
                  inner join  gv$sql_monitor sm on sm.inst_id = ss.inst_id and sm.sid = ss.sid  and sm.sql_id =  s_SQL_ID and sm.sql_exec_id = i_SQL_EXEC_ID 
                  and value != 0
                 and sn.name in ('session logical reads', 
                      'consistent gets',
                      'physical reads' ,
                      'session uga memory',
                      'session pga memory',
                      'CPU used by this session',
                      'redo size', 
                      'temp space allocated (bytes)',
                      'parse time elapsed' ,
                      'bytes sent via SQL*Net to client',
                      'bytes received via SQL*Net from client')     
                  group by sn.name
                )
  loop
  adjusted_value := stats_cursor.value -  StatArray(stats_cursor.name);
  if ( adjusted_value != 0) then
  dbms_output.put_line( rpad(stats_cursor.name, 40) || ' : ' || lpad(to_char(adjusted_value,'999,999,999,999,999'),35)  );
  end if;
  end loop;



  DBMS_OUTPUT.PUT_LINE(chr(13) ||'define SQL_ID=' || s_SQL_ID );
  DBMS_OUTPUT.PUT_LINE('define SQL_EXEC_ID=' || i_SQL_EXEC_ID );
  DBMS_OUTPUT.PUT_LINE('define SQL_CHILD_NUM=' || i_CHILD_NO);
  DBMS_OUTPUT.PUT_LINE('define MODULE=' || module_string );


END;
/

alter session set current_schema=&MY_SCHEMA;
set worksheetname  done

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  end of run 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  reports section
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- set the SQL_ID variables 





-------------------- SQL monitor reports ----------------------------------------


@reports/sql_monitor_report &SQL_ID &SQL_EXEC_ID


-------------------- stats report on each query table ------------------------------

@object_stats/sql_stats_report.sql &MODULE_STRING


-------------------- here is the Session event report ------------------------------

@ash/ash_sql_events.sql  &SQL_ID &SQL_EXEC_ID


------------------ SQL stats ------------------------------------------------


@sql/sqlstats ('&SQL_ID')


-------------------- display_cursor   ----------------------------------------


@sql/display_cursor.sql &SQL_ID &SQL_CHILD_NUM "ADVANCED ALLSTATS LAST"

-- a nice simple display cursor :
@sql/display_cursor.sql &SQL_ID &SQL_CHILD_NUM "TYPICAL +IOSTATS -PARALLEL -BYTES LAST -PROJECTION"


-------------------- SQL DB time report  ----------------------------------------



@ash/ash_sql_dbtime &SQL_ID &SQL_EXEC_ID


-------------------- Optimizer settings report  ----------------------------------------


SELECT name, value 
FROM v$sql_optimizer_env 
WHERE sql_id = '&SQL_ID'
AND isdefault = 'NO';



 -------------------- SQL statistics report  ----------------------------------------


@reports/tsql_exadata_report &SQL_ID &SQL_EXEC_ID





----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- end of reports
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


