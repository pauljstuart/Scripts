


define TRACE_FILE_NAME=&1

define MAX_SIZE=600000000
define DIRECTORY=SQLT$UDUMP

prompt
prompt ================================  &TRACE_FILE_NAME =======================================================
prompt

prompt from directory : &DIRECTORY
prompt
prompt Pointing the oracle directories to the correct path for this instance :

--set termout off
begin
  sqltxadmin.sqlt$a.reset_directories;
end;
/
set termout on
set serveroutput on

prompt
prompt Getting the size :
prompt

declare

 src_clob            BFILE  ;  
 i_length     INTEGER;
BEGIN
  
  src_clob := BFILENAME('&DIRECTORY', '&TRACE_FILE_NAME' );

  DBMS_LOB.FILEOPEN(src_clob, DBMS_LOB.LOB_READONLY);
  i_length := dbms_lob.getlength( src_clob);

  dbms_output.put_line('Length of &TRACE_FILE_NAME is ' || to_char(i_length,'999,999,999,999,999') || ' bytes');
   DBMS_LOB.FILECLOSE(src_clob);
   dbms_output.put_line('Max size is set to ' || to_char(&MAX_SIZE,'999,999,999,999,999')  || ' bytes.');
end;
/




prompt
prompt Dumping the trace for &TRACE_FILE_NAME :
prompt


ALTER SESSION SET MAX_DUMP_FILE_SIZE=UNLIMITED;

Set echo off
set feedback off
set arraysize 5000
set long 10000000
set linesize 500
set serveroutput on
set termout off
spool &TRACE_FILE_NAME 



DECLARE

  l_trace_file_name   VARCHAR2(32767);
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
-------------------------------

BEGIN
  
    DBMS_OUTPUT.ENABLE (buffer_size => NULL); 

  src_clob := BFILENAME('&DIRECTORY', '&TRACE_FILE_NAME' );

  DBMS_LOB.FILEOPEN(src_clob, DBMS_LOB.LOB_READONLY);
  DBMS_LOB.CREATETEMPORARY(dest_clob,true);

   dbms_output.put_line('Getting &TRACE_FILE_NAME' );

  i_length := dbms_lob.getlength( src_clob);

  dbms_output.put_line('Length is ' || i_length);
  
  dest_off := 1;
  src_off := 1;
 
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

 -- a simple way of limiting the size :
  if src_off >= least(&MAX_SIZE , i_length)
   then
  exit;

end if;


  END LOOP;

  dbms_output.put_line('The size was ' || to_char(src_off,'999,999,999,999,999') || ' bytes.' );

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


spool off
set feedback on
set termout on

prompt Done







/*
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
     
     dbms_output.put_line('The length is ' || i_clob_length );
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


*/
