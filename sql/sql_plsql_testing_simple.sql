


-- simplest, display_cursor without the +..+ in the report :



set serveroutput on
DECLARE
  cursor_name      INTEGER;
   total_fetches    INTEGER;
   ret              INTEGER;

-------------- Insert the Bind Variables here ---------------------------------

  delivery_id  NUMBER      :=  7864 ;

-------------- Insert the SQL text here ---------------------------------

  sql_text_string  CLOB := q'#

select /*+ monitor */ count(*) from dba_objects
#';

BEGIN

----------------- now execute the SQL ------------------------------------------------

cursor_name := DBMS_SQL.OPEN_CURSOR;

DBMS_SQL.PARSE(cursor_name, sql_text_string, DBMS_SQL.NATIVE);

--DBMS_SQL.BIND_VARIABLE(cursor_name,   ':p_delivery_id', delivery_id );

ret := DBMS_SQL.EXECUTE(cursor_name);


total_fetches := 0;

LOOP                                        
  ret := DBMS_SQL.FETCH_ROWS(cursor_name);
  EXIT WHEN ret = 0;
  total_fetches := total_fetches + 1;
END LOOP;


DBMS_SQL.CLOSE_CURSOR(cursor_name);

DBMS_OUTPUT.PUT_LINE('Fetched : ' || total_fetches);
  
------- display the execution plan ----------------------------------------------------

FOR r IN ( SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR( NULL, NULL, 'ROWS IOSTATS MEMSTATS ALLSTATS ALL +NOTE +PARTITION +REMOTE')) )
   loop

   dbms_output.put_line(r.plan_table_output );
   END loop;



END;
/






--  a simple PL/SQL to run a statement, and then get the SQL monitor report



set serveroutput on
set linesize  32767
set long 1000000
ALTER SESSION SET CURRENT_SCHEMA=APP_BO;
DECLARE

	cursor_name      INTEGER;
	total_fetches    INTEGER := 0;
  i_elapsed_time   INTEGER := 0;
  timestart        NUMBER := dbms_utility.get_time();
	ret              INTEGER;
  myReport        CLOB;
  s_sql_id        VARCHAR2(15);
  s_exec_id       INTEGER;
  s_child_no      INTEGER;
	sql_text_clob  CLOB := q'#

SELECT  /*+ monitor */ count(*)
from dba_objects

#';  
begin

select sql_text INTO sql_text_clob from dba_hisT_SQLTEXT where sql_id = '73bwzc948mn99' and dbid = (select dbid from v$database);

   begin
     cursor_name := DBMS_SQL.OPEN_CURSOR;
     DBMS_SQL.PARSE(cursor_name,  sql_text_clob , DBMS_SQL.NATIVE);
    --DBMS_SQL.BIND_VARIABLE(cursor_name,   ':2', B2 );
     ret := DBMS_SQL.EXECUTE(cursor_name);
  EXCEPTION
      WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20000, 'Compile failed  - '||SQLERRM);
   end ;
  
  LOOP                                        
    ret := DBMS_SQL.FETCH_ROWS(cursor_name);
    EXIT WHEN ret = 0;
    total_fetches := total_fetches + 1;
  END LOOP;

  DBMS_SQL.CLOSE_CURSOR(cursor_name);

  begin
    select  prev_sql_id, prev_child_number ,prev_exec_id into s_sql_id, s_child_no, s_exec_id
    from v$session
    where sid = dbms_debug_jdwp.current_session_id and serial#  = dbms_debug_jdwp.current_session_serial ;
    DBMS_OUTPUT.PUT_LINE('SQL_ID : ' || s_sql_id || ' SQL_EXEC_ID : ' || s_exec_id || ' SQL_CHILD_NO : ' || s_child_no);
  EXCEPTION
    when NO_DATA_FOUND THEN
      dbms_output.put_line( 'Problems finding the SQL_ID  - ' || SQLERRM);
  end;


  i_elapsed_time := (dbms_utility.get_time() - timestart)/100;
  DBMS_OUTPUT.PUT_LINE( chr(10) || 'Fetched : ' || total_fetches || ' rows in '|| i_elapsed_time || ' secs.' || chr(10) );

   myReport := dbms_sqltune.report_sql_monitor( sql_id => s_sql_id, sql_exec_id => s_exec_id, type => 'TEXT', report_level => 'TYPICAL +ACTIVITY +ACTIVITY_HISTOGRAM +PLAN_HISTOGRAM');

  
  dbms_output.put_line( myReport );

    
    
end;
/





-- a simple block, which includes the session stats and the +...+ section:

DECLARE

	TYPE             ASSOC_ARRAY_T IS TABLE OF INTEGER  INDEX BY VARCHAR2(256);
	StatArray        ASSOC_ARRAY_T;
	l_index          VARCHAR2(256);
	cursor_name      INTEGER;
	i_total_fetches  INTEGER := 0;
  i_timestart      NUMBER := dbms_utility.get_time();
  i_elapsed_time   NUMBER;
	sql_text_string  CLOB;
	ret              INTEGER;
  adjusted_value   NUMBER;
  s_SQL_ID VARCHAR2(13);
  i_CHILD_NO integer;
  i_SQL_EXEC_ID integer;

BEGIN

sql_text_string  := q'#

select /*+ monitor parallel(2) */ count(*) from dba_segments

#';

----------------------------- 1st stats snapshot --------------------------------------------------

FOR r IN (select SN.name, SS.value FROM v$mystat SS, v$statname SN WHERE SS.statistic# = SN.statistic#) 
  LOOP
     --dbms_output.put_line('loading ' || r.name );
    StatArray(r.name) := r.value;
  END LOOP;


----------------- now execute the SQL ------------------------------------------------

cursor_name := DBMS_SQL.OPEN_CURSOR;

DBMS_SQL.PARSE(cursor_name, sql_text_string, DBMS_SQL.NATIVE);

ret := DBMS_SQL.EXECUTE(cursor_name);

LOOP                                        
  ret := DBMS_SQL.FETCH_ROWS(cursor_name);
  EXIT WHEN ret = 0;
  i_total_fetches := i_total_fetches + 1;
END LOOP;

DBMS_SQL.CLOSE_CURSOR(cursor_name);

-------------Now get the SQL_ID and SQL_EXEC_ID for the statement --------------------

  begin
    select  prev_sql_id, prev_child_number ,prev_exec_id into s_SQL_ID, i_CHILD_NO, i_SQL_EXEC_ID
    from v$session
    where sid = dbms_debug_jdwp.current_session_id and serial#  = dbms_debug_jdwp.current_session_serial ;
  EXCEPTION
    when NO_DATA_FOUND THEN
      dbms_output.put_line( 'Problems finding the SQL_ID  - ' || SQLERRM);
  end;
  
  i_elapsed_time := (dbms_utility.get_time() - i_timestart)/100;


------- display the execution plan ----------------------------------------------------


FOR r IN ( SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR( s_SQL_ID, i_CHILD_NO, 'ROWS IOSTATS MEMSTATS ALLSTATS ALL +NOTE +PARTITION +REMOTE')) )
   loop

   dbms_output.put_line(r.plan_table_output );
   END loop;


  -- version with the +...+

  for output_line in (
       with xplan_data0 as
        (
        select plan_table_output,  substr( '|....+....+....+....+....+....+....+....+....+....+....+', 1, length( regexp_substr( plan_table_output, '(\|\ +)', 2 ) ) ) as paul_string
        from  table(dbms_xplan.display_cursor( s_SQL_ID, i_CHILD_NO, 'ADVANCED ALLSTATS LAST'))
        ),
        xplan_data1 as
        (
        select regexp_replace( plan_table_output, '(^\|[\* 0-9]+)(\|\ +)(.*)', '\1' || paul_string || '\3' ) as plan_table_output
        from xplan_data0
        )
      select plan_table_output from xplan_data1
  )
  loop
    dbms_output.put_line( output_line.plan_table_output );
  end loop;

------------- Output the stats, adjusting for the existing values in v$mystat and getting the parallel process SIDs from gv$sql_monitor -------------------------

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
------------------------------- some output ---------------------------------------------------------
  DBMS_OUTPUT.PUT_LINE( chr(10) || 'Fetched : ' || i_total_fetches || ' rows in '|| i_elapsed_time || ' secs.' || chr(10) );
  DBMS_OUTPUT.PUT_LINE(chr(13) ||'SQL_ID=' || s_SQL_ID );
  DBMS_OUTPUT.PUT_LINE('SQL_EXEC_ID=' || i_SQL_EXEC_ID );
  DBMS_OUTPUT.PUT_LINE('SQL_CHILD_NO=' || i_CHILD_NO);
----------------------------------------------------------------------------------------



END;
/
