


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2, nvl('&3','EXECUTING') PARAM3 from dual ;


define USERNAME=&1
define SQL_ID=&2     
define STATUS=&3

undefine 1
undefine 2
undefine 3

column temp_used_gb format 999,999,999
column parallel_instances format A20
column etime_mins format 999,999
column module format A40
column username format A20
column sql_id format A14
column sql_exec_id format 99999999
column sql_exec_start format A20
column terminal format A20
column service_name format A20
column parallel_deg format A12
column sql_command format A15

SELECT DISTINCT
  username,
  osuser,
  s1.inst_id,
  Sid,
  serial#,
  s1.sql_id,
  sql_exec_id,
  TO_CHAR(sql_exec_start,'DY YYYY-MM-DD HH24:MI') AS sql_exec_start,
  (select command_name from v$sqlcommand where command_type = S1.command)  SQL_COMMAND,
  PROGRAM,
  s1.module,
 TRUNC( (sysdate - SQL_EXEC_START) * 60*24) etime_mins, 
regexp_replace(dbms_LOB.substr(sql_text, 200), '[[:cntrl:]]',null) sql_text
FROM
  gv$session S1
LEFT OUTER JOIN GV$SQLAREA t ON T.SQL_ID = S1.SQL_ID and T.inst_id = S1.inst_id
WHERE  S1.sql_id  IS NOT NULL
AND    S1.SQL_EXEC_ID  IS NOT NULL
AND    status     = 'ACTIVE'
AND    type       = 'USER'
AND USERNAME LIKE '&USERNAME'
AND S1.SQL_ID LIKE '&SQL_ID'
--and not regexp_like( program, '\(P[0-9]+\)')
order by 11  desc;
