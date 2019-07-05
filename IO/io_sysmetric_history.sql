prompt
prompt  GV$SYSMETRIC_HISTORY (1 hour history)
prompt


column time_delta format A20
column host_cpu_pct format 999.9
column cpu_queue format 999,999,999
column phys_write_bytes_persec format 999,999,999,999,999
column phys_read_bytes_persec format 999,999,999,999,999
column write_iops format 999,999,999
column read_iops format 999,999,999
column redo_bytes_persec format 999,999,999,999,999
column gc_avg_current_gettime_ms format 999,999.9
column gc_avg_consistent_gettime_ms format 999,999.9
column avg_sync_single_block_ms format 999,999.9


break on inst_id duplicates skip page

with pivot1 as
(
select to_char(begin_time,'hh24:mi:ss')||' /'||round(intsize_csec/100)||'s' Time_Delta,inst_id, metric_name, value 
 from gv$sysmetric_history
 where  trunc(intsize_CSEC, -2) in ( 6000, 5900)
)
select * 
from pivot1
pivot ( sum(value) for metric_name in ('Host CPU Utilization (%)' as host_cpu_pct,
                                       'Current OS Load' as cpu_queue, 
                                       'Physical Write Total IO Requests Per Sec' as write_iops,
                                      'Physical Read Total IO Requests Per Sec' read_iops,
                                       'Physical Write Total Bytes Per Sec' as phys_write_bytes_persec, 
                                       'Physical Read Total Bytes Per Sec' phys_read_bytes_persec, 
                                      'Redo Generated Per Sec' as redo_bytes_persec,
                                      'Average Synchronous Single-Block Read Latency' as avg_sync_single_block_ms,
                                       'Global Cache Average Current Get Time' as gc_avg_current_gettime_ms,   
                                      'Global Cache Average CR Get Time' as gc_avg_consistent_gettime_ms) 
     )
order by inst_id, time_delta;



prompt
prompt  GV$SYSMETRIC_HISTORY : aggregating read and write IO :
prompt




column begin_time format A21
column value format 999,999,999.9
column IOPS format 999,999,999,999
column total_io_persec format 999,999,999,999

break on inst_id skip page duplicates

with start1 as
(
select  begin_time,inst_id, 'Physical IO Requests per Sec' as metric_name, sum(value) as value
 from gv$sysmetric_history
where   metric_name in (
        'Physical Write Total IO Requests Per Sec',
       'Physical Read Total IO Requests Per Sec' )
and  trunc(intsize_CSEC, -2) in ( 6000, 5900)
group by begin_time,inst_id
union
select  begin_time,inst_id, 'Physical IO Bytes per Sec', sum(value)
 from gv$sysmetric_history
where    metric_name in (
       'Physical Write Total Bytes Per Sec', 
       'Physical Read Total Bytes Per Sec' )
and  trunc(intsize_CSEC, -2) in ( 6000, 5900)
group by begin_time,inst_id
union
select  begin_time,inst_id, metric_name, value
 from gv$sysmetric_history
where     metric_name in (
        'Host CPU Utilization (%)' ,
         'Current OS Load'  )
and  trunc(intsize_CSEC, -2) in ( 6000, 5900)
)
select * 
from start1
pivot ( max( to_char(value , '999,999,999,999,999,999,999')) 
       for metric_name in (
        'Physical IO Requests per Sec' as IOPS,
       'Physical IO Bytes per Sec' as total_IO_persec
 ) )
order by  inst_id, begin_time;

column begin_time format A21
column value format 999,999,999.9
column IOPS format 999,999,999,999
column total_io_mb_persec format 999,999,999,999

with start1 as
(
select  trunc(begin_time, 'MI') begin_time, 
       case when  metric_name in (
        'Physical Write Total IO Requests Per Sec',
       'Physical Read Total IO Requests Per Sec' ) then value else 0 end as total_io_requests,
       case when   metric_name in (
       'Physical Write Total Bytes Per Sec', 
       'Physical Read Total Bytes Per Sec' ) then value else 0 end as total_io_bytes_psec
 from gv$sysmetric_history
where  trunc(intsize_CSEC, -2) in ( 6000, 5900)
)
select begin_time, sum(total_io_requests) iops, sum(total_io_bytes_psec)/(1024*1024) total_io_mb_persec
from start1
group by begin_time
order by begin_time;
