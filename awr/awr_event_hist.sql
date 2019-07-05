column 1 format 999,999.99 heading inst_1
column 2 format 999,999.99 heading inst_2
column 3 format 999,999.99 heading inst_3
column 4 format 999,999.99 heading inst_4
column 5 format 999,999.99 heading inst_5
column 6 format 999,999.99 heading inst_6
column begin_time format A21

column event_name format A30

-- dba_hist_system_event, for each instance :

with pivot1 as
(
select snap_id, 
       event_name, 
       instance_number,
       (select distinct begin_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) begin_time, 
       total_waits_fg,
       greatest ( total_waits_fg -  lag(total_waits_fg,1) over (partition by instance_number, event_name order by snap_id) , 0 ) as waits_delta,
       time_waited_micro_fg,
      greatest ( time_waited_micro_fg -  lag(time_waited_micro_fg,1) over (partition by instance_number, event_name order by snap_id) , 0 ) as time_waited_delta
FROM DBA_HIST_SYSTEM_EVENT AWR
where  event_name  like 'enq: KO - fast object checkpoint'
and dbid = (select dbid from v$database)
)
,pivot2 as
(
select snap_id, begin_time, event_name, instance_number,  
      decode(waits_delta, 0, 0, time_waited_delta/(1000*waits_delta) ) avg_time_ms
from pivot1
)
select * from pivot2 
pivot
( sum(avg_time_ms) 
  for instance_number in (1,2,3,4)
)
order by snap_id;
