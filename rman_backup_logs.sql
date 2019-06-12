

column filesize_display format A20
column first_change# format 999999999999
column next_change#  format 999999999999



select btype, id1 "stamp",thread#, sequence#, first_change#, first_time, next_change#, next_time, filesize_display 
from v$backup_archivelog_details
order by 3,4;


