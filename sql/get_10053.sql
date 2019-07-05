set echo off



define SQL_ID=&1
define  CHILD_NUM=&2

alter session set max_dump_file_size='UNLIMITED';

whenever sqlerror exit SQL.SQLCODE;

clear screen

prompt you need this :  grant read on directory SQLT$DIAG to SQLT_USER_ROLE;

prompt
prompt ================================  &SQL_ID 10053 =======================================================
prompt


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



--@"P:\Documents\PJS\scripts\sess\spool_trace.sql" &TRACE_FILE_NAME

