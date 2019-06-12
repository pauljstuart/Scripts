
--
-- logs.sql
--
-- Paul Stuart
-- Nov 2004

alter session set NLS_DATE_FORMAT='DD-MON-YY HH24:MI';

column member format a60;
column first_change# format 99999999999999


column thread# format 99
column group# format 99
column member format A80 truncate
column sequence# format 99999999999
column bytes format 999,999,999,999,999;
column status format A8



select * from v$log
order by group#;

select * from v$logfile
order by group#;



select v1.*,   v2.status, v2.type, v2.member
from v$log v1, v$logfile v2
where v1.group#=v2.group#
order by v1.group#;
