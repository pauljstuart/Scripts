-----------------------------------------------------------------------------------------------
-- sysmetric (last 60 secs)
-----------------------------------------------------------------------------------------------

prompt
prompt v$sysmetric at database level - Last 60 Seconds 
prompt

column time_delta format A20
COLUMN mtime              FOR a14                  HEAD 'Interval'
COLUMN mbps               FOR 999,999.9               HEAD 'MBytes/s'
COLUMN iops               FOR 9999,999               
COLUMN rsp                FOR 999.99               HEAD 'Random|Read|Latency'
COLUMN metric_name        FOR a60              
COLUMN inst1              FOR 99,999.99              HEAD 'Inst|1'
COLUMN inst2              FOR 99,999.99              HEAD 'Inst|2'
COLUMN inst3              FOR 99,999.99              HEAD 'Inst|3'
COLUMN inst4              FOR 99,999.99              HEAD 'Inst|4'
COLUMN inst5              FOR 99,999.99              HEAD 'Inst|5'
COLUMN inst6              FOR 99,999.99              HEAD 'Inst|6'
COLUMN begin_time         FOR a19                  HEAD 'Begin Time'
COLUMN end_time           FOR a19                  HEAD 'End Time'

COLUMN inst_id            FOR 9                   
COLUMN name               FOR a64                  HEAD 'Event Name'
COLUMN time_waited        FOR 9999999              HEAD 'Time|Waited'
COLUMN wait_count         FOR 9999999              HEAD 'Wait|Count'
COLUMN avgms              FOR 999.99               HEAD 'Avg|(ms)'
COLUMN name               FOR a64     WORD_WRAPPED HEAD 'Name'
COLUMN average_read_time  FOR 999.99               HEAD 'Avg|Read|Time'
COLUMN average_write_time FOR 999.99               HEAD 'Avg|Write|Time'
COLUMN physical_reads     FOR 9999999              HEAD 'Physical|Reads'
COLUMN physical_writes    FOR 9999999              HEAD 'Physical|Writes'
column total format 999,999,999


select to_char(min(begin_time), 'hh24:mi:ss') || ' /' || round(avg(intsize_csec/100), 0) || 's' as Time_Delta
     , (sum(case metric_name when 'Physical Read Total Bytes Per Sec' then value end) +
       sum(case metric_name when 'Physical Write Total Bytes Per Sec' then value end))/(1024*1024) mbps
     , sum(case metric_name when 'Physical Read Total IO Requests Per Sec' then value end) +
       sum(case metric_name when 'Physical Write Total IO Requests Per Sec' then value end) iops
     , max(case metric_name when 'Average Synchronous Single-Block Read Latency' then value end) rsp
from   gv$sysmetric
where  metric_name in ( 'Physical Read Total IO Requests Per Sec'
                      , 'Physical Write Total IO Requests Per Sec'
                      , 'Physical Read Total Bytes Per Sec'
                      , 'Physical Write Total Bytes Per Sec'
                      , 'Average Synchronous Single-Block Read Latency');


prompt
prompt v$sysmetric at instance level - Last 60 Seconds 
prompt


column inst1 format 999,999.9;
column inst2 format 999,999.9;
column inst3 format 999,999.9;
column inst4 format 999,999.9;
column total format 999,999.9;

with pivot as 
(
select
     inst_id,
     'MB/sec' metric_name, 
     sum( value)/(1024*1024) value2
from   gv$sysmetric
where  metric_name in ( 'Physical Read Total Bytes Per Sec' , 'Physical Write Total Bytes Per Sec')
group by inst_id
union
select
     inst_id,
     'IOPS' metric_name, 
     sum( value) value2
from   gv$sysmetric
where  metric_name in ( 'Physical Read Total IO Requests Per Sec' , 'Physical Write Total IO Requests Per Sec')
group by inst_id
union
select 
   inst_id,
   'Average Synchronous Single-Block Read Latency',
    max(value)
FROM gv$sysmetric
where metric_name = 'Average Synchronous Single-Block Read Latency'
group by inst_id
),
pivot2 as
(
select pivot.metric_name,
        CASE pivot.inst_id WHEN 1 THEN pivot.value2 ELSE 0 END as value_inst1,
        CASE pivot.inst_id WHEN 2 THEN pivot.value2 ELSE 0 END as value_inst2,
        CASE pivot.inst_id WHEN 3 THEN pivot.value2 ELSE 0 END as value_inst3, 
        CASE pivot.inst_id WHEN 4 THEN pivot.value2 ELSE 0 END as value_inst4,
        CASE pivot.inst_id WHEN 5 THEN pivot.value2 ELSE 0 END as value_inst5,
        CASE pivot.inst_id WHEN 6 THEN pivot.value2 ELSE 0 END as value_inst6
FROM pivot
)
select 
      pivot2.metric_name,
     sum(value_inst1) as inst1,
     sum(value_inst2) as inst2,
     sum(value_inst3) as inst3,
     sum(value_inst4) as inst4,
     sum(value_inst5) as inst5,
     sum(value_inst6) as inst6,
     sum(value_inst1 + value_inst2 + value_inst3 + value_inst4 +  value_inst6 + value_inst6) Total
from pivot2
group by pivot2.metric_name;


 
 
prompt
prompt v$sysmetric - other IO metrics :
prompt

column time_delta format A25 TRUNCATE
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

with pivot1 as
(
select to_char(begin_time,'hh24:mi:ss')||' /'||round(intsize_csec/100)||'s' Time_Delta,inst_id, metric_name, value 
 from gv$sysmetric
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
order by inst_id;
