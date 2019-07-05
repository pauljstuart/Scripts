column time_waited_ms format 999,999.9
column avg_wait_ms format 999,999.9
column max_wait_ms format 999,999.9
column event format A30
column value format 999,999,999,999,999


select EVENT, TOTAL_WAITS ,TIME_WAITED*10 time_waited_ms,AVERAGE_WAIT*10 avg_wait_ms, max_wait*10 max_wait_ms
from gv$session_event
and event like '%temp%';
