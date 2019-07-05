
column begin_interval_time format A20
column end_interval_time format A20

prompt ==> &GNAME.snapshots.sql

spool &GNAME.snapshots.sql

select distinct dbid,snap_id,  begin_interval_time, end_interval_time 
from dba_hist_snapshot 
where begin_interval_time > trunc(sysdate) - &DAYS_AGO
AND  dbid = (select dbid from v$database)
AND instance_number = (select instance_number from v$instance)
order by 4 asc;

