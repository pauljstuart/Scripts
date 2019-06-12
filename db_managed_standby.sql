
column client_dbid format A10
column client_pid  format A10
column status format A15


clear screen

break on inst_id    page skip 1 dup


select inst_id, process, pid, status, thread#, sequence#,delay_mins, block#, blocks , known_agents, active_agents
from gv$managed_standby;

