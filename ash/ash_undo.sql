

-- query to show undo reads, compared to total foreground read activity, on an hourly basis.

column undo_pct format 999.9

with pivot1 as 
(
select /*+ parallel(16) */  trunc(sample_time,'HH') sample_hour,      case when current_file# in (select file# from v$datafile where name like '%undo%')  then delta_read_io_bytes else 0 end as undo_bytes , delta_read_io_bytes
from gv$active_session_history ash
WHERE  
     session_type = 'FOREGROUND' and session_state = 'WAITING' AND CURRENT_FILE# IS NOT NULL and sample_time > sysdate - 6/24
)
select sample_hour, sum(delta_read_io_bytes), sum(undo_bytes), sum(undo_bytes)*100/sum(delta_read_io_bytes)  as undo_pct
from pivot1
group by sample_hour
ORDER BY 1;
