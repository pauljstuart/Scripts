
-- latest code to print clob, one line at a time :

 
set serveroutput on
declare

   c_report CLOB;
   i_linecount INTEGER;
   i_thisline integer;
   i_endofline INTEGER;
   i_lengthofline INTEGER;
   s_oneline varchar2(32767);
   
   offset INTEGER := 1;
begin
 
c_report := DBMS_SQLTUNE.report_sql_monitor( sql_id => '&SQL_ID', sql_exec_id => &SQL_EXEC_ID, type   => 'TEXT', report_level => 'TYPICAL +ACTIVITY +ACTIVITY_HISTOGRAM +PLAN_HISTOGRAM');

select regexp_count(c_report, chr (10)) into i_linecount from dual;

dbms_output.put_line('Number of lines is ' || i_linecount);

for i_thisline IN 1..i_linecount+1
LOOP

  if (i_thisline = i_linecount+1) -- last line situation
  then
    i_endofline :=  dbms_lob.getlength(c_report);
  else
    i_endofline := DBMS_LOB.INSTR( c_report, chr(10), 1 , i_thisline  );
  end if;
 
  i_lengthofline := greatest(i_endofline - offset, 1);

  dbms_lob.read(c_report, i_lengthofline, offset, s_oneline);
  dbms_output.put_line( s_oneline);
  offset := i_endofline+1;
END LOOP;


END;
/



-- print clob, max linesize at a time :


DECLARE

    src_clob CLOB;
       src_off        number := 1;
       i_amount      integer;
       lc_buffer     varchar2(32767);
    i_length integer;
BEGIN
  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
  dbms_output.put_line('Starting');

  src_clob := dbms_sqltune.report_sql_detail(sql_id => '&SQL_ID', report_level => 'ALL');
  i_length := dbms_lob.getlength( src_clob);

  dbms_output.put_line('Length is ' || i_length);
  
  src_off := 1;

  while (src_off <  i_length )
    LOOP
    i_amount := least(32676 , i_length - src_off) ;
   
   DBMS_LOB.READ ( lob_loc => src_clob, amount => i_amount,  offset => src_off, buffer => lc_buffer);
   dbms_output.put_line(lc_buffer  );
   src_off := src_off + i_amount;
  END LOOP;

END;
/

spool off
set feedback on


-- print out a clob by seeking the end of line characters 

     procedure printCLOB
        (p_clob in out nocopy clob) is
       offset        number := 1;
       line_length    number := 0;
       endof_line    number := 32767;
       total_length  number := dbms_lob.getlength(p_clob);
       lc_buffer     varchar2(32767);
      
     begin
       if ( dbms_lob.isopen(p_clob) != 1 ) then
         dbms_lob.open(p_clob, 0);
       end if;
       
       endof_line := dbms_lob.instr(p_clob, CHR(10), offset);
       while ( endof_line != 0 )
       loop
            line_length := least( 32767, endof_line - offset );
            --dbms_output.put_line('length : ' || line_length) ;
            if ( line_length > 0 ) 
            then
              dbms_lob.read(p_clob, line_length, offset, lc_buffer);
              dbms_output.put_line(lc_buffer);
            else 
              dbms_output.put_line('');
            end if;
            offset := offset + line_length +1 ;
            endof_line := dbms_lob.instr(p_clob, CHR(10), offset);
       end loop; 
       line_length := total_length - offset +1;
       if ( line_length > 0 ) 
       then
         dbms_lob.read(p_clob, line_length, offset, lc_buffer);
         dbms_output.put_line(lc_buffer);
       else 
              dbms_output.put_line('');
       end if;
       if ( dbms_lob.isopen(p_clob) = 1 ) then
         dbms_lob.close(p_clob);
       end if; 
     exception
       when others then
          dbms_output.put_line('Error : '||sqlerrm);
     end printCLOB;
