
col USERNAME2 new_value 1 FORMAT a20
col SQL_ID2 new_value 2 FORMAT a20
col MIN_TIME2 new_value 3 FORMAT a20

select null USERNAME2, null SQL_ID2, null MIN_TIME2 from dual where 1=2;
select nvl( '&1','&_USER') USERNAME2, nvl('&2','%') SQL_ID2, nvl('&3','0') MIN_TIME2 from dual ;

define USERNAME=&1     
define SQL_ID=&2
define MIN_TIME=&3

undefine 1
undefine 2
undefine 3


-- including some other SQL stats columns to get general SQL stats too


prompt
prompt Looking back &DAYS_AGO days
prompt 
prompt



WITH 
pivot2 as
(
select  
      instance_number as inst_id,
      user_id, 
      session_id,
      session_serial#,
      sql_opname,
      module,
      sql_id, 
      sql_exec_id,
      SQL_PLAN_HASH_VALUE,
      sql_exec_start , 
      MAX(sample_time) sql_end_time, 
       (CAST(MAX(sample_time)  AS DATE) - CAST( SQL_EXEC_START AS DATE)) * 60*24 etime_mins ,
        (CAST(MAX(sample_time)  AS DATE) - CAST( SQL_EXEC_START AS DATE)) * 3600*24 etime_secs ,
       sum(DELTA_INTERCONNECT_IO_BYTES)/(1024*1024) interconnect_mb,
	     sum(nvl(delta_write_io_bytes, 0) + nvl(delta_read_io_bytes, 0))/(1024*1024)   phys_total_mb,
	     sum(delta_read_io_bytes)/(1024*1024)  phys_read_mb,
       sum(delta_write_io_bytes)/(1024*1024)  phys_write_mb,
                     sum(DELTA_READ_IO_REQUESTS) read_io_requests,
                    sum(DELTA_WRITE_IO_REQUESTS) write_io_requests,
       max(temp_space_allocated)/(1024*1024) max_temp_mb,
    max(pga_allocated)/(1024*1024) max_pga_mb
from dba_hist_active_sess_history 
WHERE  
        session_type = 'FOREGROUND'
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
AND  SQL_EXEC_ID IS NOT NULL
and  sql_id  like '&SQL_ID'
--and session_id = 4016
--and sql_opname = 'INSERT'
and ( user_id in (select user_id from dba_users where username  LIKE '&USERNAME') OR MODULE LIKE '&USERNAME')
group by  instance_number, user_id, session_id, session_serial#, sql_opname, module,  sql_id,  sql_exec_id, SQL_PLAN_HASH_VALUE, sql_exec_start
)
select
      (select username from dba_users where SM.user_id = user_id ) as username, 
      sql_opname,
      SM.sql_id, 
      sql_exec_id,
      SQL_PLAN_HASH_VALUE,
      SM.module,
      count(*)-1 parallel_deg,
      LISTAGG(SM.inst_id, '') WITHIN GROUP (ORDER BY SM.inst_id) as parallel_instances,
      sql_exec_start as px_start_time, 
      max(sql_end_time) as px_end_time,
   -- extract(day from 24*60*60*(max( sql_end_time) - min(sql_exec_start)) )   px_etime_secs ,
    --  extract(day from 24*60*(max( sql_end_time) - min(sql_exec_start)) )   px_etime_mins ,
      max(etime_mins) px_etime_mins,
      max(etime_secs) px_etime_secs,
    sum( interconnect_mb) px_interconnect_mb,
    sum(   phys_total_mb ) px_phys_total_mb,
    sum(  phys_read_mb ) px_phys_read_mb,
    sum(phys_write_mb )  px_phys_write_mb,
    sum(read_io_requests) px_read_io_requests,
    sum(write_io_requests) px_write_io_requests,
    sum(max_temp_mb)   px_temp_mb,
   sum(max_pga_mb) px_pga_mb,
   	regexp_replace(dbms_LOB.substr(sql_text, 200), '[[:cntrl:]]',null)
from pivot2 SM 
    left outer join dba_hist_sqltext DHST on DHST.sql_id = SM.sql_id   
group by user_id, sql_opname, module, SM.sql_id, sql_exec_id, SQL_PLAN_HASH_VALUE, sql_exec_start ,regexp_replace(dbms_LOB.substr(sql_text, 200), '[[:cntrl:]]',null)
having extract(day from 24*60*(max( sql_end_time) - min(sql_exec_start)) ) >= &MIN_TIME
order by sql_exec_start
/


