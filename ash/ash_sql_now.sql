

col p1 new_value 1

select null p1  from dual where 1=2;
select null p2  from dual where 1=2;
select nvl( '&1','%') p1 from dual ;

define USERNAME_PATTERN=&1     


undefine 1



prompt
prompt Getting Currently running SQL from ASH - ie. the end time is within the last 30 secs
prompt


COLUMN phyio_kb_persec FORMAT 999,999,999.9;
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


with sql_initial as
(
SELECT ASH.inst_id, ASH.user_id, ASH.session_id, ASH.session_serial#, ASH.sql_id, ASH.sql_opname,ASH.sql_exec_id,ASH.sql_plan_hash_value, ASH.in_hard_parse,   
        NVL(ASH.sql_exec_start, min(sample_time)) sql_start_time, 
        MAX(ASH.sample_time) sql_end_time, 
        (CAST(MAX(sample_time)  AS DATE) - CAST( NVL(ASH.sql_exec_start, min(sample_time)) AS DATE)) * 60*24 etime_mins ,
        max(temp_space_allocated)/(1024*1024) max_temp_mb,
        max(pga_allocated)/(1024*1024)  max_pga_mb,
        row_number() over (partition by session_id, session_serial# order by MAX(ASH.sample_time) desc ) sid_sql_rank
from gv$active_session_history ASH
WHERE  
     ASH.session_type = 'FOREGROUND'
and  ASH.sql_id is not null
group by  ASH.inst_id, ASH.user_id, ASH.session_id, ASH.session_serial#, ASH.sql_id, ASH.sql_opname, ASH.sql_exec_id, ASH.sql_plan_hash_value,  ASH.in_hard_parse, ASH.sql_exec_start
having MAX(ASH.sample_time) > sysdate - 30/(24*60*60) 
)
select  
        inst_id, 
         session_id as sid,
         session_serial# as serial,
         T1.username ,
        sql_id, 
        sql_exec_id,
        sql_plan_hash_value, 
        in_hard_parse,
        sql_opname,
        sql_start_time,   
        sql_end_time, 
        etime_mins, 
        max_pga_mb,
        T1.temporary_tablespace, 
         max_temp_mb,
        sum(max_temp_mb) over ( partition by T1.temporary_tablespace) tempsum_per_tablespace_mb
from sql_initial P
inner join dba_users T1 on T1.user_id = P.user_id 
where sid_sql_rank = 1
and  USERNAME LIKE '%&USERNAME_PATTERN%'
order by sql_end_time;



/*
column wait_class format A10
column event format a30;
column username format a20;
column wait_time_ms format 999,999,999.9    

prompt
prompt current session waits :
prompt

select  sw.inst_id, 
        s.username,
        sw.sid, 
	sw.wait_class,
	sw.event, 
	sw.state,  
	sw.seq#, 
	sw.wait_time_micro/1000 wait_time_ms
from gv$session_wait sw
inner join gv$session s on sw.inst_id = S.inst_id and S.sid = sw.sid
where sw.sid = s.sid  and s.username is not NULL 
and sw.wait_class != 'Idle'
order by 2, 8 desc;
*/



/* to find sql running at a particular point in time, use :

where sql_start_start < TO_DATE ('12/12/2013 04:23', 'dd/mm/yyyy HH24:MI')
and   sql_end_time > TO_DATE ('12/12/2013 04:23', 'dd/mm/yyyy HH24:MI') ;

*/




/*
experimental query trying to get the most recent temp, rather than the max temp

with pivot1 as
(
SELECT  ASH.*,
     last_value(temp_space_allocated/(1024*1024)) over ( partition by ASH.user_id,  ASH.sql_id, ASH.sql_opname, ASH.sql_exec_id, ASH.sql_plan_hash_value  order by sample_id) temp_used_mb
from gv$active_session_history ASH
WHERE  
     ASH.session_type = 'FOREGROUND'
and  ASH.sql_id is not null
), 
pivot2 as
(
SELECT ASH.user_id,  ASH.sql_id, ASH.sql_opname,ASH.sql_exec_id,ASH.sql_plan_hash_value, ASH.sql_exec_start,   
        min(ASH.sample_time)  sql_start_time,
        MAX(ASH.sample_time) sql_end_time, 
        ((CAST(MAX(ASH.sample_time)  AS DATE)) - (CAST(ASH.sql_exec_start AS DATE))) * (3600*24) duration_secs ,
        decode( sum(delta_time), 0, 0, (sum(delta_read_io_bytes+delta_write_io_bytes)/1024)/(sum(delta_time)/1000000) ) avg_phyio_kb_sec,
        max(temp_space_allocated)/(1024*1024) max_temp_mb,
        temp_used_mb current_temp_mb
from pivot1 ASH
group by  ASH.user_id,  ASH.sql_id, ASH.sql_opname, ASH.sql_exec_id, ASH.sql_plan_hash_value, ASH.sql_exec_start, temp_used_mb
having  MAX(ASH.sample_time) > sysdate - 30/(24*60*60) 
)
select * from pivot2;

*/

