

SET TERMOUT OFF
alter session set nls_date_format='YYYYMMDD HH24:MI';

select null P_INSTANCE, null P_START, null P_END from dual where 1=2;

select nvl( '&1', instance_number)  P_INSTANCE from v$instance;
SELECT nvl('&2', sysdate - 1/24) P_START from dual;
SELECT nvl('&3', sysdate ) P_END from dual;


define INSTANCE=&1
define START_TIME=&2     
define END_TIME=&3
define SPOOL_NAME=ash_report_inst&INSTANCE..html

undefine 1
undefine 2
undefine 3
SET TERMOUT ON


prompt Global ASH Report:
prompt
prompt Start : &START_TIME
prompt End :   &END_TIME
prompt Instance : &INSTANCE
prompt Output :  &SPOOL_NAME
prompt



Set echo off
set feedback off
SET heading off
set arraysize 5000
set long 10000000
set serveroutput on
set termout off


SPOOL &SPOOL_NAME

declare
  i_dbid number;
  i_inst_id NUMBER;
begin

  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 

  select dbid into i_dbid from v$database;
  select instance_number into i_inst_id from v$instance;

  for cursor1 in 
  (
  select * from table( DBMS_WORKLOAD_REPOSITORY.ASH_GLOBAL_REPORT_html( l_dbid => i_dbid, l_inst_num => &INSTANCE,   l_btime => '&START_TIME',  l_etime =>  '&END_TIME'  ))
  )
    LOOP
    DBMS_OUTPUT.PUT_LINE( cursor1.output);
    END LOOP;


end;
/

set termout on
spool off
set feedback on
set heading on
set wrap off

prompt Done
