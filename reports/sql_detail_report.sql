
define SQL_ID=&1;


undefine 1
undefine 2

prompt
prompt => sqlmon_detail_&SQL_ID..html
prompt


set trimspool on 
set linesize 32000
set long 1000000 longchunksize 1000000


--set termout off
set feedback off
set serveroutput on
set heading off
spool 'sqlmon_detail_&SQL_ID..html'

DECLARE

    src_clob CLOB;
       src_off        number := 1;
       i_amount      integer;
       lc_buffer     varchar2(32767);
    i_length integer;
BEGIN
  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 

 -- dbms_output.put_line('Starting');

  src_clob := dbms_sqltune.report_sql_detail(sql_id => '&SQL_ID', report_level => 'ALL');
 
  i_length := dbms_lob.getlength( src_clob);

 -- dbms_output.put_line('Length is ' || i_length);
  
  src_off := 1;

  while (src_off <  i_length )
    LOOP
    i_amount := least(32676 , i_length - src_off) ;
   
   DBMS_LOB.READ ( lob_loc => src_clob, amount => i_amount,  offset => src_off, buffer => lc_buffer);
   dbms_output.put_line(lc_buffer  );
 --  dbms_output.put_line('>> src_off ' || src_off );
   src_off := src_off + i_amount;
  END LOOP;

END;
/

spool off
set termout on
set feedback on
set heading on

prompt done
