set echo off



define SQL_ID=&1
define  CHILD_NUM=&2


whenever sqlerror exit SQL.SQLCODE;

clear screen


prompt
prompt ================================  &SQL_ID 10053 =======================================================
prompt

prompt Pointing the oracle directories to the correct path for this instance :

set serveroutput off
begin
  sqltxadmin.sqlt$a.reset_directories;
end;
/


set serveroutput on

prompt
prompt Dumping the 10053 for &SQL_ID :
prompt

declare
  rand_string VARCHAR2(128);
begin 

select  mod(abs(dbms_random.random),1000)+1 into rand_string from dual ;

dbms_sqldiag.dump_trace(p_sql_id=>'&SQL_ID', 
                              p_child_number=> &CHILD_NUM, 
                              p_component=>'Compiler', 
                              p_file_id=> 'PJS_' || '&SQL_ID' || '_' || rand_string  );

end;
/

-- now get the name of the trace file just created :

COLUMN INPUT_ARG NEW_VALUE TRACE_FILE_NAME noprint

SELECT REGEXP_SUBSTR(value, '[^/]+$') as INPUT_ARG
FROM   v$diag_info
WHERE  name = 'Default Trace File';


prompt
prompt Dumping the 10053 for &SQL_ID to : &TRACE_FILE_NAME
prompt

set feedback off
spool &TRACE_FILE_NAME 


DECLARE

  l_trace_file_name   VARCHAR2(32767);
  warning             int;
  dest_off            int:=1;
  src_off             int:=1;
  lang_ctx            int:=0;
  dest_clob           CLOB;
  src_clob            BFILE  ;  

-------------------------------
    procedure printCLOB (p_clob in out nocopy clob) 
    is
       i_offset        number := 1;
       i_amount      integer;
       i_clob_length  number := dbms_lob.getlength(p_clob);
       lc_buffer     varchar2(32767);
      
     begin
     if ( dbms_lob.isopen(p_clob) != 1 ) then
         dbms_lob.open(p_clob, 0);
     end if;
       
    DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
    LOOP
    BEGIN
        i_amount := 32676 ;
        DBMS_LOB.READ ( lob_loc => p_clob, amount => i_amount,  offset => i_offset, buffer => lc_buffer);
        dbms_output.put_line(lc_buffer  );
        i_offset := i_offset + i_amount;
        exception
            when no_data_found then exit;
        end;

    END LOOP;

    dbms_lob.close(p_clob);
    
    exception
       when others then
          dbms_output.put_line('Error : '||sqlerrm);
    end printCLOB;
---------------------------

BEGIN
  
  SELECT REGEXP_SUBSTR(value, '[^/]+$') into l_trace_file_name
  FROM   v$diag_info
  WHERE  name = 'Default Trace File';

  dbms_output.put_line('trace created in : ' || l_trace_file_name );
  
  
  src_clob := BFILENAME('SQLT$STAGE', l_trace_file_name);
  DBMS_LOB.FILEOPEN(src_clob, DBMS_LOB.LOB_READONLY);
  DBMS_LOB.CREATETEMPORARY(dest_clob,true);

  DBMS_LOB.LoadCLOBFromFile(
          dest_lob => dest_clob,
         src_bfile  => src_clob,
         amount =>DBMS_LOB.GETLENGTH( src_clob) , 
          dest_offset => dest_off, src_offset => src_off, bfile_csid => 0, lang_context => lang_ctx, warning => warning );
  

  printCLOB( dest_clob );

  DBMS_LOB.FILECLOSE(src_clob);

  
exception
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
    raise_application_error(-20007,SQLERRM);

end;
/

spool off
set feedback on
set echo on


