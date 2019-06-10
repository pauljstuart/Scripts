/*
create view  PERF_ALERTLOG
as
select * from sys.X$DBGALERTEXT;

grant select on PERF_ALERTLOG TO PERF_SUPPORT;



column message_text format A100 truncate
column originating_timestamp format A30

alter session set nls_timestamp_tz_format='DY DD-MON-YYYY HH24:MI TZD';

select * from
(
select inst_id, originating_timestamp, message_text, row_number() over ( order by indx desc) as rank
from sys.perf_alertlog
order by indx
)
where rank < 1000;

*/

clear screen

set termout off
begin
  sqltxadmin.sqlt$a.reset_directories;
end;
/
set termout on
set serveroutput on

prompt grant read on directory SQLT$BDUMP to SQLT_USER_ROLE;

define MAX_LENGTH=5000000


DECLARE

  s_instance_name   VARCHAR2(1024);
  s_alert_log_name VARCHAR2(1024);
  src_clob            BFILE  ;  
  dest_clob   CLOB;
  i_offset        number := 1;
  i_amount      integer;
  lc_buffer     varchar2(32767);
  warning             int;
  dest_off            int:=1;
  src_off             int:=1;
  lang_ctx            int:=0;
  i_length integer;

BEGIN
  
  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 

  select instance_name into s_instance_name from v$instance;
  s_alert_log_name := 'alert_' || s_instance_name || '.log';

  dbms_output.put_line('Getting ' || s_alert_log_name );
  src_clob := BFILENAME('SQLT$BDUMP', s_alert_log_name );

  DBMS_LOB.FILEOPEN(src_clob, DBMS_LOB.LOB_READONLY);
  DBMS_LOB.CREATETEMPORARY(dest_clob,true);

  i_length := dbms_lob.getlength( src_clob);
  src_off := greatest(1, i_length - &MAX_LENGTH);
 
 WHILE ( src_off < i_length )
 LOOP

    dest_off := 1;
    i_offset := 1;
    i_amount := least(32676 , i_length - src_off) ;
    DBMS_LOB.LoadCLOBFromFile( dest_lob => dest_clob,
         src_bfile  => src_clob,
         amount => i_amount ,  
          dest_offset => dest_off, 
         src_offset => src_off, 
         bfile_csid => 0, 
         lang_context => lang_ctx, 
        warning => warning );
   
   DBMS_LOB.READ ( lob_loc => dest_clob, amount => i_amount,  offset => i_offset, buffer => lc_buffer);
   dbms_output.put_line(lc_buffer  );
    --dbms_output.put_line('>> src_off ' || src_off );

  END LOOP;


  dbms_output.put_line('The total size is ' ||  to_char(i_length,'999,999,999,999,999') || ' bytes.');
  dbms_output.put_line('Displayed the last ' ||  to_char( '&MAX_LENGTH','999,999,999,999,999') || ' bytes. ');

  DBMS_LOB.FILECLOSE(src_clob);
  
exception
    when UTL_FILE.INVALID_FILENAME THEN
       DBMS_OUTPUT.PUT_LINE('INVALID FILE NAME : The file name parameter is invalid.');
    when utl_file.invalid_path then
    raise_application_error(-20001,
    'INVALID PATH: File location or filename was invalid.');
    when utl_file.invalid_mode then
    raise_application_error(-20002,
    'INVALID MODE: The open_mode parameter in FOPEN was invalid');
    when utl_file.invalid_filehandle then
    raise_application_error(-20003,
    'INVALID OPERATION:The file could not be opened or operated on as requested.');
    when utl_file.read_error then
       raise_application_error(-20004,'READ_ERROR:An operating system error occured during the read operation.');
    when utl_file.write_error then
    raise_application_error(-20005,
    'WRITE_ERROR: An operating system error occured during the write operation.');
    when utl_file.internal_error then
    raise_application_error(-20006,
    'INTERNAL_ERROR: An unspecified error in PL/SQL');
    when others then
    DBMS_OUTPUT.PUT_LINE('OTHER ERROR - ' || SQLERRM);
END;
/


