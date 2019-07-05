
set serveroutput on 


define SQL_ID=&1
define SQL_EXEC_ID=&2 

undefine 1
undefine 2


prompt
prompt SQL monitor report for &SQL_ID and &SQL_EXEC_ID
prompt

declare

   c_report CLOB;
   i_linecount INTEGER;
   i_thisline integer;
   i_endofline INTEGER;
   i_lengthofline INTEGER;
   s_oneline varchar2(32767);
   s_oneline2 varchar2(32767);   
   offset INTEGER := 1;
begin


  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
c_report := DBMS_SQLTUNE.report_sql_monitor( sql_id => '&SQL_ID', sql_exec_id => &SQL_EXEC_ID, type   => 'TEXT', report_level => 'TYPICAL ');


select regexp_count(c_report, chr (10)) into i_linecount from dual;

dbms_output.put_line('Number of lines is ' || i_linecount);

for i_thisline IN 1..i_linecount+1
LOOP

  if (i_thisline = i_linecount+1) -- last line situation
  then
    i_endofline :=  dbms_lob.getlength(c_report) +1;
  else
    i_endofline := DBMS_LOB.INSTR( c_report, chr(10), 1 , i_thisline  );
  end if;
 
  i_lengthofline := greatest(i_endofline - offset, 1);

  dbms_lob.read(c_report, i_lengthofline, offset, s_oneline);


   s_oneline2 :=  substr( '|....+....+....+....+....+....+....+....+....+....+....+....+....+....+....+....+', 1, length( regexp_substr( s_oneline, '(\|\ +)', 2 ) ) );
   s_oneline :=  regexp_replace( s_oneline, '(^\|[\ ]+[-> ]*[0-9]+[\ ]+)(\|\ +)(.*)', '\1' || s_oneline2 || '\3' ) ;


  dbms_output.put_line( s_oneline);
  offset := i_endofline+1;
END LOOP;


END;
/


undefine 1
undefine 2
undefine 3

/*
prompt ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

prompt ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


with sql_plan_data as (
        select  plan_line_id, plan_parent_id
        from    gv$sql_plan_monitor
        where   sql_id = '&SQL_ID'
        and     sql_exec_id = &SQL_EXEC_ID
        )
,    hierarchy_data as (
        select  plan_line_id, plan_parent_id
        from    sql_plan_data
        start   with plan_line_id = 0
        connect by prior plan_line_id = plan_parent_id
        order   siblings by plan_line_id desc
        )
,    ordered_hierarchy_data as (
        select plan_line_id
        ,      plan_parent_id as pid
        ,      row_number() over (order by rownum desc) as oid
        ,      max(plan_line_id) over () as maxid
        from   hierarchy_data
        )
,    ALL_MON as (    
        SELECT *   FROM gv$sql_plan_monitor WHERE  sql_id = '&SQL_ID' AND sql_exec_id = &SQL_EXEC_ID 
       )
SELECT  '|' as "|", 
        ordered_hierarchy_data.oid , '|' as "|" ,
        ALL_MON.plan_line_id Id,  '|' as "|", 
        ALL_MON.plan_parent_id Pid, '|' as "|",
        lpad( ' ', plan_depth, ':') || plan_operation || ' ' || Plan_options as operation,  '|' as "|",
        plan_object_name object,     '|' as "|",
        starts execs,               '|' as "|",
        plan_cardinality rows_est,  '|' as "|",
        output_rows rows_actual,    '|' as "|",
        plan_time etime_sec,    '|' as "|",
        plan_partition_start pstart,    '|' as "|",
        plan_partition_stop pstop,    '|' as "|",
        physical_read_requests phy_reads,               '|' as "|",
        plan_cpu_cost CPU_cost,               '|' as "|",
        plan_io_cost  IO_cost,               '|' as "|",
        plan_temp_space TEMP,             '|' as "|"
FROM ALL_MON, ordered_hierarchy_data
WHERE ALL_MON.plan_line_id = ordered_hierarchy_data.plan_line_id
START WITH ALL_MON.plan_line_id = 0
CONNECT by PRIOR ALL_MON.plan_line_id = ALL_MON.plan_parent_id 
ORDER BY ALL_MON.plan_line_id ;
/


prompt ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


*/

