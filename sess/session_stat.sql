
prompt
prompt getting a particular statistic from all sessions
prompt


column login_mins format 999,999
column machine format A20
colum name format A20



select S.inst_id, S.sid, serial#, username, sql_id, osuser, machine, program, type, logon_time, 
       name, 
       value stat_value,
      (sysdate - logon_time)*24*60*60 login_secs,
      (sysdate - logon_time)*24*60 login_mins
from gv$session S
inner join  gv$sesstat SS on S.inst_id =SS.inst_id and S.sid = SS.sid
INNER JOIN v$statname SN  ON SS.statistic# = SN.statistic# 
WHERE 
    SN.name  like 'Parallel operations downgraded to serial'
and (sysdate - logon_time ) != 0
AND S.status = 'ACTIVE'
and  value > 0
order by value  desc;




-- sql bytes sent over front interface to client summing all parallel processes :

COLUMN MB_SENT FORMAT 999,999.9
COLUMN MB_PER_SEC FORMAT 999,999.9


select sql_id, sql_exec_id, sql_exec_start, username, osuser, machine, program, logon_time,  name AS STATISTIC, 
         sum(value/(1024*1024)) mb_sent, 
        sum(value/(1024*1024))  / ((sysdate - logon_time)*24*60*60) MB_per_sec
from gv$session S
inner join  gv$sesstat SS on S.inst_id =SS.inst_id and S.sid = SS.sid
INNER JOIN gv$statname SN  ON SS.statistic# = SN.statistic#
WHERE 
 SN.name like 'bytes sent via SQL*Net to client'
and sql_id = '9gq084dq58fsp'
and type = 'USER'
group by S.inst_id, sql_id, sql_exec_id, sql_exec_start, S.sid, serial#, username, osuser, machine, program, logon_time,  Name
order by sql_exec_start;

