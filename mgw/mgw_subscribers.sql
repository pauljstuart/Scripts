
COLUMN last_error_msg FORMAT A50
COLUMN queue_name FORMAT A40
COLUMN destination FORMAT A40
COLUMN subscriber_id FORMAT A25
COLUMN failures FORMAT 99999;

clear screen


select subscriber_id,queue_name, destination, status, failures, propagated_msgs, exceptionq_msgs,last_error_msg 
from mgw_subscribers;

