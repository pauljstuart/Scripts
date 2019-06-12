
set numwidth 18
set wrap off

break on wait_class page skip 1 dup


col wait_class for a15
col event for a30
col total_waits format 999,999,999
col total_timeouts format 999,999,999
col a.time_waited*10 format 999,999,999,999 heading "time_waited (ms)"
col a.average_wait*10 format 999,999,999,999 heading "average_wait (ms)"

select a.wait_class, a.event, a.total_waits, a.total_timeouts, 
       a.time_waited*10 , 
      a.average_wait*10 , c.startup_time
from v$system_event a,
	v$event_name b,
	v$instance c
where a.event = b.name
order by b.wait_class, a.time_waited desc;

