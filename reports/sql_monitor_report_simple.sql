set echo off
set feedback off
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
c_report := DBMS_SQLTUNE.report_sql_monitor( sql_id => '&SQL_ID', sql_exec_id => &SQL_EXEC_ID, type   => 'TEXT', report_level => 'TYPICAL +XPLAN -METRICS -SQL_TEXT  ');


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


   s_oneline2 :=  substr( '|....+....+....+....+....+....+....+....+....+....+....+....+...+...+', 1, length( regexp_substr( s_oneline, '(\|\ +)', 2 ) ) );
   s_oneline :=  regexp_replace( s_oneline, '(^\|[\ ]+[-> ]*[0-9]+[\ ]+)(\|\ +)(.*)', '\1' || s_oneline2 || '\3' ) ;


  dbms_output.put_line( s_oneline);
  offset := i_endofline+1;
END LOOP;


END;
/


undefine 1
undefine 2
undefine 3



