

col USERNAME2 new_value 1
col SQL_ID2 new_value 2
col MINS_AGO2 new_value 3

select null USERNAME2, null SQL_ID2, null MINS_AGO2 from dual where 1=2;
select nvl( '&1','&_USER') USERNAME2, nvl('&2','%') SQL_ID2, nvl('&3','0') MINS_AGO2 from dual ;

define USERNAME=&1     
define SQL_ID=&2
define MINS_AGO=&3


undefine 1
undefine 2
undefine 3

undefine 1



prompt
prompt Getting Currently running SQL from ASH - ie. the end time is within the last &MINS_AGO minutes
prompt


column SESSION_SERIAL#    format 999999                      
column QC_INSTANCE_ID     format 999999                      
column QC_SESSION_ID        format 999999               
column QC_SESSION_SERIAL# format 999999 

COLUMN module format A30
COLUMN sql_opname format A20
COLUMN total_current_temp_mb FORMAT 999,999,999
COLUMN tempsum_per_tablespace_mb FORMAT 999,999,999
COLUMN max_temp_mb FORMAT 999,999,999
COLUMN max_pga_mb FORMAT 999,999,999
COLUMn temporary_tablespace FORMAT A10 heading TEMP_TS
COLUMN etime_mins FORMAT 999,999.9
COLUMN sid FORMAT 9999
COLUMN serial FORMAT 99999
COLUMN username FORMAT A20
COLUMN inst_id FORMAT 99
COLUMN sql_opname FORMAT A10
COLUMN sql_id FORMAT A13
column sql_exec_id format 999999999
column sql_plan_hash_value format 9999999999
column sql_start_time format A21
column in_hard_parse format A16

column sql_end_time format A21


with pivot2 as 
(
select  
      inst_id,
      user_id, 
     session_id,
     session_serial#,
      qc_instance_id,
      qc_session_id, 
      qc_session_serial#,
      sql_opname,
      module,
      sql_id, 
      sql_exec_id,
      SQL_PLAN_HASH_VALUE,
      sql_exec_start , 
      MAX(ash.sample_time) sql_end_time, 
             (CAST(MAX(sample_time)  AS DATE) - CAST( SQL_EXEC_START AS DATE)) * 3600*24 etime_secs ,
       (CAST(MAX(sample_time)  AS DATE) - CAST( SQL_EXEC_START AS DATE)) * 60*24 etime_mins ,
       sum(DELTA_INTERCONNECT_IO_BYTES)/(1024*1024) interconnect_mb,
	     sum(nvl(delta_write_io_bytes, 0) + nvl(delta_read_io_bytes, 0))/(1024*1024)   phys_total_mb,
	     sum(delta_read_io_bytes)/(1024*1024)  phys_read_mb,
       sum(delta_write_io_bytes)/(1024*1024)  phys_write_mb,
       max(temp_space_allocated)/(1024*1024) max_temp_mb,
      row_number() over ( order by sql_exec_start  desc) as start_rank
from gv$active_session_history ASH
WHERE  
     session_type = 'FOREGROUND'
AND  SQL_EXEC_ID IS NOT NULL
and  sql_id  like '&SQL_ID'
--and session_id = 1516
--and session_id in ( 4016)
--and sql_opname = 'INSERT'
--AND USER_ID = 171
and sample_time > sysdate -&MINS_AGO/60/24
and ( user_id in (select user_id from dba_users where username  LIKE '&USERNAME') OR MODULE LIKE '&USERNAME')
group by  inst_id, user_id, session_id, session_serial#,      qc_instance_id,
      qc_session_id, 
      qc_session_serial#, sql_opname, module,  sql_id,  sql_exec_id, SQL_PLAN_HASH_VALUE, sql_exec_start
)
SELECT SM.* , regexp_replace( substr(sql_text, 0, 100), '[[:space:]]+', ' ') sql_text  
from pivot2 SM 
left outer join GV$SQLAREA DHST on DHST.sql_id = SM.sql_id 
order by SM.sql_exec_start, SM.sql_id;


