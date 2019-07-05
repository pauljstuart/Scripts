
set echo off

column name format A40


prompt io_latency.sql
prompt
prompt "Instance Average I/O Events in the last 60 Seconds (v$eventmetric)" 
prompt

column begin_time format A21

with pivot1 as 
(
select 
      inst_id,
      EN.name,
      round( 10 * m.time_waited / nullif(m.wait_count, 0), 2) avgms
from   gv$eventmetric m
       inner join v$event_name EN on m.event_id = EN.event_id
where 
      m.wait_count > 10
      and EN.name in ( 'cell single block physical read',
                  'cell multiblock physical read',
                  'db file sequential read',
                  'db file parallel write',
                  'db file scattered read',
                  'db file sequential read',
                  'direct path read',
                  'direct path read temp',
                  'direct path write',
                  'direct path write temp',
                  'log file sync',
                  'log file parallel write') 
order by  name, inst_id
)
select * from pivot1
pivot (sum( avgms ) for inst_id in ( 1,2,3,4,5) );


prompt
prompt Global Cache latency report (avg since startup)
prompt

column gcs_cr_blocks_received format 999,999,999;
column avg_cr_block_receive_time_ms format 999.9;

SELECT b1.inst_id, 
     b2.VALUE gcs_cr_blocks_received,
     b1.VALUE gcs_cr_blocks_received_time,
     decode( b2.VALUE, 0, 0, ((b1.VALUE / b2.VALUE) * 10) ) avg_cr_block_receive_time_ms 
     FROM gv$sysstat b1, gv$sysstat b2
     WHERE b1.name = 'global cache cr block receive time'
     AND b2.name = 'global cache cr blocks received'
     AND b1.inst_id = b2.inst_id OR b1.name = 'gc cr block receive time'
     AND b2.name = 'gc cr blocks received'
     AND b1.inst_id = b2.inst_id;
     
prompt
prompt Database File I/O Response Time - Last 60 Seconds
prompt

column  file_readtime_ms format 999,999,999.99
column file_writetime_ms format 999,999,999.99

select to_char(begin_time, 'hh24:mi:ss') || ' /' || round((intsize_csec/100), 0) || 's' mtime,
      f.name,
      fm.average_read_time*10 file_readtime_ms,
      fm.average_write_time*10 file_writetime_ms,
      fm.physical_reads,
      fm.physical_writes
from   v$filemetric fm,
       v$datafile f
where  fm.file_id = f.file#
and    fm.average_read_time > 8
and    fm.physical_reads > 100;

