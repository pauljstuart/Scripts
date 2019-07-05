


prompt
prompt IO Stats from the last &DAYS_AGO days ago
prompt

COLUMN mbps_max format 999,999 heading MBsec_max
COLUMN mbps_avg format 999,999 heading MBsec_avg
COLUMN iops_max FORMAT 999,999 HEADING IOPs_max
COLUMN iops_avg FORMAT 999,999 HEADING IOPs_avg
column end_interval_time format A20


break on inst_id duplicates skip page

SELECT snap_id, 
        max(trunc(end_time, 'MI')) AS end_interval_time,
       (SUM(CASE METRIC_NAME WHEN 'Physical Read Total Bytes Per Sec' THEN AVERAGE END) + SUM(CASE METRIC_NAME WHEN 'Physical Write Total Bytes Per Sec' THEN AVERAGE END))/(1024*1024)   MBPS_avg,
       (SUM(CASE METRIC_NAME WHEN 'Physical Read Total Bytes Per Sec' THEN maxval END) + SUM(CASE METRIC_NAME WHEN 'Physical Write Total Bytes Per Sec' THEN maxval END))/(1024*1024)   MBPS_max, '|' as PP,
       sum(case metric_name when 'Physical Read Total IO Requests Per Sec' then average end) + sum(case metric_name when 'Physical Write Total IO Requests Per Sec' then average end)   iops_avg,
    sum(case metric_name when 'Physical Read Total IO Requests Per Sec' then maxval end) + sum(case metric_name when 'Physical Write Total IO Requests Per Sec' then maxval end)   iops_max
from dba_hist_sysmetric_summary
where  begin_time >= trunc(sysdate) - &DAYS_AGO
and dbid = (select dbid from v$database)
GROUP BY SNAP_ID
order by snap_id;

prompt
prompt IO Stats per-instance from the last &DAYS_AGO days ago
prompt

SELECT snap_id, 
        max(trunc(end_time, 'MI')) AS end_interval_time,
        instance_number inst_id,
       (SUM(CASE METRIC_NAME WHEN 'Physical Read Total Bytes Per Sec' THEN AVERAGE END) + SUM(CASE METRIC_NAME WHEN 'Physical Write Total Bytes Per Sec' THEN AVERAGE END))/(1024*1024)   MBPS_avg,
       sum(case metric_name when 'Physical Read Total IO Requests Per Sec' then average end) + sum(case metric_name when 'Physical Write Total IO Requests Per Sec' then average end)   iops_avg
from dba_hist_sysmetric_summary
where  begin_time >= trunc(sysdate) - &DAYS_AGO
and dbid = (select dbid from v$database)
GROUP BY SNAP_ID, instance_number
order by instance_number, snap_id;
