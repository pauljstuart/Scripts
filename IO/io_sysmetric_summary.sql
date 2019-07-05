
-----------------------------------------------------------------------------------------------
-- sysmetric_summary (last 60 minutes)
-----------------------------------------------------------------------------------------------


prompt
prompt Database I/O Metrics - v$sysmetric_summary (last 60 minutes)
prompt

COLUMN avgmbps            FOR 999,999               HEAD 'Avg|MBytes/s'
COLUMN avgiops            FOR 999,999              HEAD 'Avg|IOPS'
COLUMN maxmbps            FOR 999,999              HEAD 'Max|MBytes/s'
COLUMN maxiops            FOR 999,999            HEAD 'Max|IOPS'
COLUMN inst_id            FOR 9                    

select to_char(min(begin_time), 'dd/mm/yyyy hh24:mi:ss') begin_time
     , to_char(max(end_time), 'dd/mm/yyyy hh24:mi:ss') end_time
     , (sum(case metric_name when 'Physical Read Total Bytes Per Sec' then average end) +
       sum(case metric_name when 'Physical Write Total Bytes Per Sec' then average end))/(1024*1024) avgmbps
     , sum(case metric_name when 'Physical Read Total IO Requests Per Sec' then average end) +
       sum(case metric_name when 'Physical Write Total IO Requests Per Sec' then average end) avgiops
     , (sum(case metric_name when 'Physical Read Total Bytes Per Sec' then maxval end) +
       sum(case metric_name when 'Physical Write Total Bytes Per Sec' then maxval end))/(1024*1024) maxmbps
     , sum(case metric_name when 'Physical Read Total IO Requests Per Sec' then maxval end) +
       sum(case metric_name when 'Physical Write Total IO Requests Per Sec' then maxval end) maxiops
from gv$sysmetric_summary;
