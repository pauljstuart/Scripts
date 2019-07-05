col P_USERNAME new_value 1 format A10
col P_SQL_ID new_value 2  format A10
col P_INST new_value 3 format A10

select null P_USERNAME, null P_SQL_ID, null P_INST from dual where 1=2;
select nvl( '&1','&_USER') P_USERNAME, nvl('&2','%') P_SQL_ID, nvl('&3','%') P_INST from dual ;

define USERNAME=&1     
define SQL_ID=&2
define INSTANCE=&3


undefine 1
undefine 2
undefine 3

--
-- session.sql
--
-- Paul Stuart
-- Nov 2004
-- Nov 2013


break on inst_id skip page duplicates

column idle_mins    format 999,999
column wait_time_ms format 999,999,999
column tracefile_name format A70
column tracefile format A100
column active_mins format 999,999,999

				      
SELECT s.inst_id,
      s.username, 
      s.sid, 
      s.serial#, 
      TO_CHAR(logon_time,'DD/MM/RR HH24:MI') LOGON_TIME, 
  --    floor(last_call_et/3600)||':'|| floor(mod(last_call_et,3600)/60)||':'|| mod(mod(last_call_et,3600),60) as idle_time,
      case WHEN status = 'INACTIVE' then last_call_et/60 else null end  as idle_mins,
      p.SPID , 
      osuser, 
      status, 
     server,
      command,
      sql_id, 
      s.terminal, 
      s.machine host,
      S.client_info,     
      s.program,  
      S.module
FROM  gv$session s 
LEFT OUTER JOIN  gv$process p ON  s.paddr = p.addr and S.inst_id = P.inst_id
WHERE 
   (S.username like '&USERNAME' or S.module like '&USERNAME')
AND s.inst_id like '&INSTANCE'
and (SQL_ID like '&SQL_ID' or sql_id is null)
and S.type = 'USER'
order by s.inst_id,s.sid;



