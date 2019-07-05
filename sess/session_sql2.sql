

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


column temp_used_gb format 999,999,999.9
column parallel_instances format A20
column service_name format A20
column parallel_deg format A12

with pivot22 as
(
select SESS.Inst_id,
      SESS.username, 
      SESS.osuser,
     CASE WHEN PROGRAM NOT LIKE '%(P%' THEN SESS.INST_ID ELSE 0 END AS  QC_INST_ID,
      CASE WHEN PROGRAM NOT LIKE '%(P%' THEN sid ELSE 0 END AS  QC_SID,
       CASE WHEN PROGRAM NOT LIKE '%(P%' THEN SERIAL# ELSE 0 END AS QC_SERIAL#, 
     (select COMMAND_NAME from v$sqlcommand where command_type = SESS.command) SQL_OPNAME,
      SESS.sql_id, 
      sql_exec_id,
      sql_exec_start , 
     plan_hash_value,
     program,
      terminal,    
      SESS.module,
      service_name,
     nvl(blocks,0)*(select value from v$parameter where name = 'db_block_size')/(1024*1024*1024) temp_gb, 
    regexp_replace( substr(sql_text, 0, 200), '[[:space:]]+', ' ') as sql_text
from gv$session SESS
INNER JOIN gv$sql sql on (SESS.SQL_ADDRESS = sql.ADDRESS AND sess.SQL_HASH_VALUE = sql.HASH_VALUE and sess.SQL_CHILD_NUMBER = sql.CHILD_NUMBER AND SESS.INST_ID = sql.inst_id )
left outer join gv$tempseg_usage TSU on TSU.inst_id = SESS.inst_id and TSU.session_num = SESS.serial#
WHERE  SESS.sql_id is not null AND  SESS.SQL_EXEC_ID IS NOT NULL
and status = 'ACTIVE'
and type = 'USER'
AND (SESS.USERNAME LIKE '&USERNAME' OR SESS.MODULE LIKE '&USERNAME')
AND SESS.SQL_ID LIKE '&SQL_ID'
and SESS.USERNAME != 'SYS'
and  NOT ( SID = dbms_debug_jdwp.current_session_id and sess.username = USER)
)
select username, MAX(QC_INST_ID) AS INST_ID,  MAX(QC_SID) AS SID, MAX(QC_SERIAL#) AS SERIAL#, SQL_OPNAME, sql_id,sql_exec_id, plan_hash_value, sql_exec_start,  (trunc(sysdate, 'MI') - trunc(SQL_EXEC_START, 'MI')) * 60*24 etime_mins , osuser, terminal, module, service_name , sum(temp_gb) temp_used_gb, count(*) as parallel_deg,     LISTAGG(inst_id, '') WITHIN GROUP (ORDER BY inst_id) parallel_instances, sql_text
from pivot22
where sql_id != '18ksfugcspc9h'
group by username, sql_id, SQL_OPNAME, sql_exec_id, sql_exec_start, terminal, module, osuser,service_name, plan_hash_value, sql_text
order by (trunc(sysdate, 'MI') - trunc(SQL_EXEC_START, 'MI'))  desc;
