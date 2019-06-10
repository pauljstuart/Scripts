column target format A10
column destination format A40 wrap on
column dest_name   format A20
column status format A9
column valid_now format A5
column dest_id format 999
column error format A40
column affirm format A6
column verify format A6

clear screen
set wrap off

select dest_id, 
     dest_name,
     db_unique_name, 
     destination, 
     status,binding, 
     target, archiver net_timeout, 
     register, 
     fail_date, 
     fail_sequence, 
     failure_count, 
     max_failure,
     schedule, 
     log_sequence, 
     reopen_secs,
     max_connections "max_conn",  
     process, transmit_mode, 
     affirm , verify "verify",
     valid_now, valid_type, 
     valid_role, 
     error
from v$archive_dest;

select * from v$archive_dest_status;

