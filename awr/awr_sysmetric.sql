


COLUMN inst1_avg FORMAT 999,999,999,999,999.0
COLUMN inst1_max FORMAT 999,999,999,999,999.0
COLUMN inst2_avg FORMAT 999,999,999,999,999.0
COLUMN inst3_avg FORMAT 999,999,999,999,999.0
COLUMN inst4_avg FORMAT 999,999,999,999,999.0
COLUMN inst5_avg FORMAT 999,999,999,999,999.0
COLUMN inst6_avg FORMAT 999,999,999,999,999.0
COLUMN snap_id NEW_VALUE starting_snap_id 
column begin_time format A21
COLUMN sum_avg FORMAT 999,999,999,999,999.0


--define METRIC_NAME='Physical Read Total Bytes Per Sec';
--define METRIC_NAME='Total PGA Allocated'
--define METRIC_NAME='Host CPU Utilization (%)';
--define METRIC_NAME='Buffer Cache Hit Ratio';
define METRIC_NAME='Current Logons Count';
--define METRIC_NAME='Current OS Load' ;
--define METRIC_NAME='Session Count' ;

prompt 
prompt sysmetric : &METRIC_NAME
prompt


prompt
prompt per instance report :
prompt

with pivot1 as (
SELECT
      (select distinct begin_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) begin_time , 
       snap_id,
      instance_number,
      average,
      maxval
FROM
      dba_hist_sysmetric_summary  AWR
WHERE metric_name  = '&METRIC_NAME'  
and
    dbid = (select dbid from v$database)
)
select * from pivot1
pivot
( 
   sum(average) as avg, sum(maxval) as max
  for instance_number in (1 as inst1,2 as inst2,3 as inst3 ,4 as inst4,5 as inst5,6 as inst6)
) 
order by snap_id;

Prompt
prompt database report :
prompt

/*

with pivot1 as (
SELECT
      (select distinct begin_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) begin_time , 
       snap_id,
      instance_number,
      average
FROM
      dba_hist_sysmetric_summary  AWR
WHERE metric_name  = '&METRIC_NAME'  
and
    dbid = (select dbid from v$database)
)
select snap_id, begin_time, sum(average) sum_avg
from 
pivot1
 group by snap_id, begin_time
 order by snap_id;

*/
