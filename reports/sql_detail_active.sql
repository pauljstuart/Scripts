

define SQL_ID=&1;


clear screen

prompt
prompt SQL detail HTML report for &SQL_ID  : sqldetail_active_&SQL_ID..html
prompt


set serveroutput on 
set feedback off

spool 'sqldetail_active_&SQL_ID..html'


DECLARE
 myReport  CLOB;
 myReport2 CLOB;
 
 l_offset number := 1;

     -------------------------------
     procedure printout
        (p_clob in out nocopy clob) is
       offset number := 1;
       read_bytes number := 0;
       amount number := 32767;
       len    number := dbms_lob.getlength(p_clob);
       lc_buffer varchar2(32767);
       i pls_integer := 1;
       
     begin
       if ( dbms_lob.isopen(p_clob) != 1 ) then
         dbms_lob.open(p_clob, 0);
       end if;
       
       while ( offset < len )
       loop
            amount := dbms_lob.instr(p_clob, CHR(10), offset);
            if ( amount = 0 ) then
                read_bytes := len - offset;
            else 
                read_bytes := amount - offset;
            end if;
            if ( read_bytes != 0 ) then
              dbms_lob.read(p_clob, read_bytes, offset, lc_buffer);
              dbms_output.put_line(lc_buffer);
            end if ;
            offset := offset + read_bytes + 1;
            i := i + 1;
       end loop; 
       
       if ( dbms_lob.isopen(p_clob) = 1 ) then
         dbms_lob.close(p_clob);
       end if; 
     exception
       when others then
          dbms_output.put_line('Error : '||sqlerrm);
     end printout;
    ---------------------------
    
    
    
BEGIN


  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
  myReport := DBMS_SQLTUNE.report_sql_detail (sql_id => '&SQL_ID', type => 'ACTIVE', report_level => 'ALL');
 

 printout( myReport );

  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(Substr(SQLERRM,1,255));
 raise;
END;
/

spool off




