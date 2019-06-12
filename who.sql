


define gname=idle

COLUMN global_name NEW_VALUE gname noprint;
SELECT substr( global_name, 1, decode( dot, 0, length(global_name), dot-1) ) || '-' || (select lower(to_CHAR( SYSDATE, 'DY-DDMONYY')) from dual)  global_name
FROM (SELECT global_name, instr(global_name, '.') dot from global_name );

prompt
prompt setting worksheet name to &gname
prompt

set worksheetname &gname


alter session set nls_timestamp_format='DY DD-MM-YYYY HH24:MI';
alter session set nls_date_format='DY DD-MM-YYYY HH24:MI';



SELECT dbms_debug_jdwp.current_session_id sid,
       dbms_debug_jdwp.current_session_serial serial#,
       (select instance_number from v$instance) inst_id,
       (select instance_name from v$instance) instance_name,
       (select host_name from v$instance) host,
       (select service_name from v$session where sid =  dbms_debug_jdwp.current_session_id ) service_name
FROM dual;


select username, user_id, default_tablespace, temporary_tablespace from user_users;

set wrap off
set verify off
set serveroutput off
