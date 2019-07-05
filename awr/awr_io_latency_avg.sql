column 1 format 999,999.99 heading inst_1
column 2 format 999,999.99 heading inst_2
column 3 format 999,999.99 heading inst_3
column 4 format 999,999.99 heading inst_4
column 5 format 999,999.99 heading inst_5
column 6 format 999,999.99 heading inst_6
column end_time format A21
column event_name format A30

break on event_name duplicates skip page


-- dba_hist_system_event, for each instance :

WITH 
pivot1 as
(
select snap_id, 
       event_name, 
       instance_number,
       (select distinct end_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) end_time, 
       total_waits_fg,
       greatest ( total_waits_fg -  lag(total_waits_fg,1) over (partition by instance_number, event_name order by snap_id) , 0 ) as waits_delta,
       time_waited_micro_fg,
      greatest ( time_waited_micro_fg -  lag(time_waited_micro_fg,1) over (partition by instance_number, event_name order by snap_id) , 0 ) as time_waited_delta
FROM DBA_HIST_SYSTEM_EVENT AWR
where  event_name  in ( 'cell single block physical read', 'log file parallel write', 'log file sync','cell multiblock physical read',  'direct path write',  'direct path read', 'direct path read temp', 'direct path write temp','db file sequential read', 'db file scattered read')
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
)
,pivot2 as
(
select snap_id, end_time, event_name, instance_number,  
      decode(waits_delta, 0, 0, time_waited_delta/(1000*waits_delta) ) avg_time_ms
from pivot1
)
select * from pivot2 
pivot
( sum(avg_time_ms) 
  for instance_number in (1,2,3,4,5,6)
)
order by event_name, snap_id;
