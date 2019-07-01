
col USERNAME2 new_value 1 FORMAT a20


select null USERNAME2, null SQL_ID2, null MIN_TIME2 from dual where 1=2;
select nvl( '&1','%') USERNAME2  from dual ;

define USERNAME=&1     


undefine 1
undefine 2
undefine 3



column READ_IO_REQUESTS format 999,999,999,999
column  WRITE_IO_REQUESTS format 999,999,999,999
column num_samples format 999,999,999,999
colum waiting_sess format 999,999,999
column cpu_sess format 999,999,999
column aas format 999,999
column sample_day format A14
prompt
prompt Looking back &DAYS_AGO days
prompt 
prompt



WITH 
pivot2 as
(
select  
   (select '&USERNAME' from dual ) as username, 
  trunc(sample_time, 'DD') sample_day, 
  count(*) num_samples,
    sum( CASE  WHEN session_type = 'FOREGROUND' AND session_state = 'WAITING'  then 1 else 0 END )as waiting_sess ,
    sum( CASE  WHEN session_type = 'FOREGROUND' and session_state = 'ON CPU'  then 1 else 0 END  )as cpu_sess,
    sum( CASE  WHEN session_type = 'FOREGROUND' and session_state in ('ON CPU',  'WAITING')   then 1 else 0 END  )/(24*60*6) as aas,
	     sum(nvl(delta_write_io_bytes, 0) + nvl(delta_read_io_bytes, 0))/(1024*1024)   phys_total_mb,
	     sum(delta_read_io_bytes)/(1024*1024)  phys_read_mb,
       sum(delta_write_io_bytes)/(1024*1024)  phys_write_mb,
                     sum(DELTA_READ_IO_REQUESTS) read_io_requests,
                    sum(DELTA_WRITE_IO_REQUESTS) write_io_requests
from dba_hist_active_sess_history 
WHERE  
        session_type = 'FOREGROUND'
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
--and session_id = 4016
--and sql_opname = 'INSERT'
and ( user_id in (select user_id from dba_users where username  LIKE '&USERNAME') OR MODULE LIKE '&USERNAME')
group by    trunc(sample_time, 'DD') 
)
select * 
from pivot2 
order by 2;
