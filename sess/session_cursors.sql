

-- Summary report : currently open cursors , summed by username, instance, 

break on inst_id duplicates skip page

with pivot1 as
(
select  s.inst_id,  s.schemaname, sum(a.value) total_cursors
from gv$sesstat a
inner join gv$session s on  s.sid=a.sid and a.inst_id = s.inst_id
inner join v$statname b on a.statistic# = b.statistic#
and b.name = 'opened cursors current'
and a.value != 0
--and a.inst_id = 2
and s.schemaname != 'SYS'
group by s.inst_id, s.schemaname
)
select pivot1.*, sum(total_cursors) over (partition by inst_id) instance_cursors_sum
from pivot1
order by inst_id;


-- currently open cursors, by session :

select * from
(
select S.inst_id, S.sid, serial#, username, osuser, machine, program, type, logon_time, 
      (sysdate - logon_time)*24*60 login_mins, name, value open_cursors
from gv$session S
inner join  gv$sesstat SS on S.inst_id =SS.inst_id and S.sid = SS.sid
INNER JOIN gv$statname SN  ON SS.statistic# = SN.statistic#
WHERE 
 SN.name like 'opened cursors current'
)
where open_cursors > 10
order by open_cursors desc;



