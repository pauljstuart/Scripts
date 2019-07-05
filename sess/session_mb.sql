
prompt
prompt physical reads from all sessions, foreground and background
prompt


column login_mins format 999,999
column mb_per_sec format 999,999
column phys_reads_mb format 999,999,999
column machine format A20
colum name format A20


select * from
(
select S.inst_id, S.sid, serial#, username, osuser, machine, program, type, logon_time, 
      (sysdate - logon_time)*24*60 login_mins, name, value/(1024*1024) phys_reads_mb,(sysdate - logon_time)*24*60*60 login_secs
, value/((sysdate - logon_time)*24*60*60)/(1024*1024) MB_per_sec
from gv$session S
inner join  gv$sesstat SS on S.inst_id =SS.inst_id and S.sid = SS.sid
INNER JOIN v$statname SN  ON SS.statistic# = SN.statistic#
WHERE 
 SN.name like 'physical read total bytes'
and (sysdate - logon_time ) != 0
)
where MB_per_sec > 1
order by MB_per_sec desc;



