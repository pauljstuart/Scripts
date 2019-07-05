column last_error_msg format A50
column agent_database format A20

CLEAR SCREEN

select agent_status, agent_database, agent_instance, agent_ping, agent_start_time, last_error_date, last_error_msg 
from mgw_gateway;



