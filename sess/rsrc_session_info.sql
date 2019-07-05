


column state format A10

SELECT se.sid sess_id, co.name consumer_group, 
 se.state, 
 se.cpu_waits,
 se.current_cpu_wait_time,
 se.cpu_wait_time,
 se.current_queued_time, 
 se.queued_time, 
 se.current_yields,
 se.sql_canceled
FROM 
v$rsrc_session_info se, v$rsrc_consumer_group co
WHERE se.current_consumer_group_id = co.id;

