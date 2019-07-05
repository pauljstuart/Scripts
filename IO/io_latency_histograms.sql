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

with pivot1 as
(
select event, wait_time_milli, decode( sum(wait_count) over (partition by event), 0, 0, wait_count*100/(sum(wait_count) over (partition by event))) as wait_pct
from v$event_histogram
where event in ('cell single block physical read','db file sequential read', 'db file scattered read', 'direct path read temp','direct path write temp',
'log file sync', 'log file parallel write')
)
select * 
from pivot1
pivot( sum(wait_pct) for wait_time_milli in (1 ,2 ,4 ,8 ,16 ,32 ,64,128,256,512,1024,2048,4096));
