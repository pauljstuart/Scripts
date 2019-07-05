column 1 format 999,999.99 heading inst_1
column 2 format 999,999.99 heading inst_2
column 3 format 999,999.99 heading inst_3
column 4 format 999,999.99 heading inst_4
column 5 format 999,999.99 heading inst_5
column 6 format 999,999.99 heading inst_6
column begin_time format A21
column aas_total format 999,999,999



prompt
prompt per instance report :
prompt

with pivot1 as (
SELECT
      (select distinct end_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) end_time , 
       snap_id,
      instance_number,
      average,
     maxval
FROM
      dba_hist_sysmetric_summary  AWR
WHERE metric_name  = 'Average Active Sessions'  
and snap_id > (select min(snap_id) from dba_hist_snapshot  where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD') )
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


Prompt
prompt database report :
prompt


with pivot1 as (
SELECT
      (select distinct begin_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) begin_time , 
       snap_id,
      instance_number,
      average
FROM
      dba_hist_sysmetric_summary  AWR
WHERE metric_name  = 'Average Active Sessions'  
and
    dbid = (select dbid from v$database)
)
select snap_id, begin_time, sum(average) aas_total ,
       (select sum(value)  from   gv$osstat where  stat_name = 'NUM_CPU_CORES') cores
from 
pivot1
 group by snap_id, begin_time
 order by snap_id;
