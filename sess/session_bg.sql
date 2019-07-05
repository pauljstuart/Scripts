


col P_USERNAME new_value 1 format A20
col P_SQL_ID new_value 2  format A20
col P_INST new_value 3 format A20

select null P_USERNAME, null P_SQL_ID, null P_INST from dual where 1=2;
select nvl( '&1','&_USER') P_USERNAME, nvl('&2','%') P_SQL_ID, nvl('&3','%') P_INST from dual ;

define USERNAME=&1     
define SQL_ID=&2
define INSTANCE=&3

undefine 1
undefine 2
undefine 3


select * from Gv$bgprocess
where paddr != hextoraw(0);



break on inst_id skip page duplicates

column idle_hours    format 999,999.9 
column wait_time_ms format 999,999,999
column tracefile_name format A70
column tracefile format A100
column active_mins format 999,999,999.9
column status format A10
column action format A50
column service_name format A15
            
prompt
prompt Active :
prompt

SELECT s.inst_id,
      s.username, 
      s.sid, 
      s.serial#, 
      P.pname,
      command,
     	    sql_id, 
            sql_exec_id, 
            sql_child_number, 
     	    sql_exec_start,
     	    (sysdate - cast(sql_exec_start as date) )*24*60 etime_mins,
      TO_CHAR(logon_time,'DD/MM/RR HH24:MI') LOGON_TIME, 
      p.SPID , 
      osuser, 
      status, 
     server,
      last_call_et/60  active_mins,
      s.terminal, 
      s.program,  
      S.service_name,
      S.module,
      S.action,
--      S.client_info,     
      S.BLOCKING_SESSION_STATUS,
      S.BLOCKING_INSTANCE,     
      S.BLOCKING_SESSION ,
      S.state,
      S.event,
      S.wait_time_micro/1000 wait_time_ms,
      sql_trace,
      sql_trace_waits,
      SQL_TRACE_PLAN_STATS,
      regexp_replace(tracefile, '.*/') tracefile_name
FROM  gv$session s 
left outer JOIN  gv$process p ON  s.paddr = p.addr and S.inst_id = P.inst_id
WHERE 
  s.inst_id like '&INSTANCE'
AND  (SQL_ID like '&SQL_ID' OR SQL_ID IS NULL)
AND  S.status = 'ACTIVE'
AND (S.USERNAME LIKE '&USERNAME' OR S.USERNAME IS NULL)
and S.type = 'BACKGROUND'
order by s.inst_id, sql_id;
