


define INST_ID=&1

column end_time format A21
column event_name format A30
column wait_pct format 999.9
column 1 format 999 heading 1ms
column 2 format 999 heading 2ms
column 4 format 999 heading 4ms
column 8 format 999 heading 8ms
column 16 format 999 heading 16ms
column 32 format 999 heading 32ms
column 64 format 999 heading 64ms
column 128 format 999 heading 128ms
column 256 format 999 heading 256ms
column 512 format 999 heading 512ms
column 1024 format 999 heading 1024ms
column 2048 format 999 heading 2048ms
column 4096 format 999 heading 4096ms
column end_snap_id format 999999

break on event_name skip page duplicates


PROMPT
PROMPT For IO event histograms for instance &INST_ID
prompt

with
pivot1 as
(
select snap_id, 
       event_name, 
       instance_number as inst_id,
       (select distinct end_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) end_time, 
       wait_time_milli,
   --    wait_count,
       greatest ( wait_count -  lag(wait_count,1) over (partition by instance_number, event_name, wait_time_milli order by snap_id) , 0 ) as wait_count_delta
FROM DBA_HIST_EVENT_HISTOGRAM AWR
where  event_name  in ( 'cell single block physical read', 'log file parallel write', 'log file sync','cell multiblock physical read',  'direct path write',  'direct path read', 'direct path read temp', 'direct path write temp','db file sequential read', 'db file scattered read')
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and instance_number = &INST_ID
order by 2, 5, 1
),
hist_percent as
(
select inst_id, snap_id as end_snap_id, end_time, event_name, wait_time_milli, decode( sum(wait_count_delta) over (partition by inst_id, snap_id, event_name), 0, 0, wait_count_delta*100/(sum(wait_count_delta) over (partition by inst_id, snap_id, event_name))) as wait_pct
from pivot1
)
select * 
from hist_percent
pivot( sum(wait_pct) for wait_time_milli in (1 ,2 ,4 ,8 ,16 ,32 ,64,128,256,512,1024,2048,4096))
order by event_name, end_snap_id;



/*
(for testing)
select * from pivot1
pivot ( sum(wait_count_delta) for  wait_time_milli in (1 ,2 ,4 ,8 ,16 ,32 ,64,128,256,512,1024,2048,4096))
order by 1
*/

