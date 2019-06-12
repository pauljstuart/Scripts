
select  start_time, end_time,status,
  (CAST(end_time  AS DATE) - CAST( start_time AS DATE)) * 60*24 etime_mins ,
        sid, stamp, output_bytes/(1024*1024)  size_MB, object_type, output_device_type 
from v$rman_status
order by start_time;
