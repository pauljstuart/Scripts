



define BEGIN_SNAP=&1
define END_SNAP  =&2
define SPOOL_NAME=awr_global_report_html_&BEGIN_SNAP._&END_SNAP..html


prompt AWR Global Report:
prompt
prompt Begin : &BEGIN_SNAP
prompt End   : &END_SNAP
prompt
prompt spooling to &SPOOL_NAME


Set echo off
set feedback off
set arraysize 5000
set long 10000000
set serveroutput on
set termout off

spool &SPOOL_NAME


declare
  i_dbid number;
 inst_tab dbms_utility.instance_table;
  s_instance_list VARCHAR2(256);
  inst_cnt NUMBER;
begin

  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 

  select dbid into i_dbid from v$database;

  -- setup the instance list :
  IF dbms_utility.is_cluster_database THEN
     dbms_output.put_line('..' ||  inst_tab.LAST);
     dbms_utility.active_instances(inst_tab, inst_cnt);
    for idx in inst_tab.FIRST .. inst_tab.LAST
    loop
      IF ( idx = inst_tab.LAST ) then
        s_instance_list := s_instance_list ||  inst_tab(idx).inst_number ;
      else
         s_instance_list:= s_instance_list || inst_tab(idx).inst_number || ',';
      end if;
    end loop;
  ELSE
    s_instance_list := '1';
  end if;

  dbms_output.put_line( 'instance list ' || s_instance_list);

  for cursor1 in 
  (
  select * from table( DBMS_WORKLOAD_REPOSITORY.AWR_GLOBAL_REPORT_HTML(  l_dbid => i_dbid,  l_bid => &BEGIN_SNAP,  l_eid => &END_SNAP, l_inst_num => s_instance_list ) )
  )
    LOOP
    DBMS_OUTPUT.PUT_LINE( cursor1.output);
    END LOOP;


end;
/
set termout on
spool off

				  

set heading on
set termout on
set wrap off

prompt Done
