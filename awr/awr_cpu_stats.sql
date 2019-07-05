column 1_max format 999
column 1_avg format 999 

column end_interval_time format A20



prompt
prompt per instance report :
prompt

with pivot1 as (
SELECT
      (select distinct end_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) end_interval_time , 
       snap_id,
      instance_number,
      average,
     maxval
FROM
      dba_hist_sysmetric_summary  AWR
WHERE metric_name  = 'Host CPU Utilization (%)'  
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and
    dbid = (select dbid from v$database)
)
select * from pivot1
pivot
( 
 sum( round(maxval)) as max, sum(round(average)) as avg
  for instance_number in (1,2,3,4)
) 
order by snap_id;



prompt
prompt per instance report on cpu queue:
prompt

with pivot1 as (
SELECT
      (select distinct end_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) end_interval_time , 
       snap_id,
      instance_number,
      average,
     maxval
FROM
      dba_hist_sysmetric_summary  AWR
WHERE metric_name  = 'Current OS Load'  
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) )
and
    dbid = (select dbid from v$database)
)
select * from pivot1
pivot
( 
 sum( round(maxval)) as max, sum(round(average)) as avg
  for instance_number in (1,2,3,4)
) 
order by snap_id;
