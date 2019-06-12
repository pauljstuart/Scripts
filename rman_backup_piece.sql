
column handle format A80
clear screen

select set_stamp, piece#,status, start_time,
    trunc(bytes/(1024*1024) ) MB,
    compressed, 
    handle 
from  v$backup_piece
order by 4 desc;

