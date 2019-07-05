


define INSTANCE=&1
define BEGIN_SNAP=&2
define END_SNAP=&3

define SPOOL_NAME=awr_report_inst&INSTANCE._&BEGIN_SNAP._&END_SNAP..html

prompt => &SPOOL_NAME

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
  select * from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_HTML(  l_dbid => i_dbid,  l_bid => &BEGIN_SNAP,  l_eid => &END_SNAP, l_inst_num => &INSTANCE ) )
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


/*

SELECT * FROM TABLE(
DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT( l_dbid => &DBID2, l_inst_num => &INSTANCE, l_bid => &BEGIN_SNAP, l_eid => &END_SNAP) );
	  
*/

undefine 1
undefine 2
undefine 3
