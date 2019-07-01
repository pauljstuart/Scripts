


col P_USERNAME new_value 1 format A10
col P_INST_ID new_value 2 format A10

select null P_INST_ID, null P_USERNAME from dual where 1=2;
select nvl( '&1','%') P_USERNAME, nvl('&2','%') P_INST_ID from dual ;

define USERNAME=&1
define INST_ID=&2
     


undefine 1
undefine 2







PROMPT 
PROMPT top sql (like OEM) from &MINS_AGO mins ago
prompt


-----------------------------------------------
--- basic like OEM, just showing total wait events and %
------------------------------------------------


define MINS_AGO=5;

column phys_read_mb format 999,999,999

with pivot as 
(
select sql_ID, SQL_OPNAME, DU.username, count(*) wait_count, sum(count(*)) over () as grand_total
from gv$active_session_history ASH
inner join dba_users DU on DU.user_id = ASH.user_id
where sample_time >  SYSDATE - &MINS_AGO/(24*60)
and session_type = 'FOREGROUND'
and SQL_ID is not null
group by sql_id, SQL_OPNAME, DU.username
)
select pivot.sql_id, username, SQL_OPNAME, pivot.wait_count, round( pivot.wait_count*100/pivot.grand_total, 1 ) pct
from pivot
where wait_count > 1
order by wait_count desc;




-- the new query, showing cumulative totals :

define HOURS_AGO=3

column phys_read_mb format 999,999,999
column phys_write_mb format 999,999,999
column total_temp_mb format 999,999,999
column min_period format A20
column username format A30
column instance_list format A15

break on min_period duplicates skip page
with
pivot1 as
(
select  inst_id, 
     to_char(sample_time, 'DY DD-MM-YYYY HH24:')  ||
       (case WHEN  extract( minute from sample_time) < 15 THEN '15'
             WHEN  extract( minute from sample_time) < 30 THEN '30'
             WHEN  extract( minute from sample_time) < 45 THEN '45'
             WHEN  extract( minute from sample_time) < 60 THEN '59'
             END) min_period, username, sql_opname, sql_exec_start, sql_exec_id,sql_id, 
             DELTA_READ_IO_BYTES, DELTA_WRITE_IO_BYTES,TEMP_SPACE_ALLOCATED, (case when qc_session_id is not null then 'PQ' else 'SERIAL' end) session_type
from gv$active_session_history ash
inner join dba_users DU on DU.user_id = AsH.user_id
where sql_id is not null and sql_exec_id is not null
and inst_id like '&INST_ID'
and username like '&USERNAME'
--and session_type = 'FOREGROUND'
and sample_time > sysdate - &HOURS_AGO/24 
),
pivot2 as
(
select  min_period, username, session_type,  inst_id,   sQL_ID , sql_exec_id, sql_exec_start, sql_opname, sum(nvl(DELTA_READ_IO_BYTES,0))/(1024*1024) read_mb, sum(nvl(DELTA_WRITE_IO_BYTES,0))/(1024*1024) write_mb,  max(nvl(TEMP_SPACE_ALLOCATED,0))/(1024*1024) temp_mb,  (to_date(min_period, 'DY DD-MM-YYYY HH24:MI') - cast(sql_exec_start as date) ) *60*24 etime_mins 
from pivot1
group by min_period, inst_id, username, sql_id, sql_exec_id, sql_exec_start, sql_opname, session_type
having sum(nvl(DELTA_READ_IO_BYTES,0)) > 0 or  max(nvl(TEMP_SPACE_ALLOCATED,0)) > 0 or sum(nvl(DELTA_WRITE_IO_BYTES,0)) > 0
)
,
pivot3 as
(
select /*+ materialize */ distinct min_period, username,     ash.SQL_ID , ash.sql_exec_id, ash.sql_exec_start, ash.sql_opname,      etime_mins, 
     (select  sum( read_mb ) from pivot2 P1 where P1.min_period <= ash.min_period and P1.sql_id = ash.sql_id and P1.sql_exec_id = ash.sql_exec_id and P1.sql_exec_start = ash.sql_exec_start) phys_read_mb  ,
     (select  sum(write_mb ) from pivot2 P1 where P1.min_period <= ash.min_period and P1.sql_id = ash.sql_id and P1.sql_exec_id = ash.sql_exec_id and P1.sql_exec_start = ash.sql_exec_start) phys_write_mb  ,
     (select  sum( temp_mb ) from pivot2 P1 where P1.min_period = ash.min_period and P1.sql_id = ash.sql_id and P1.sql_exec_id = ash.sql_exec_id and P1.sql_exec_start = ash.sql_exec_start)  total_temp_mb,
      (select  distinct listagg(inst_id, ',') within group (order by inst_id) instance_list  from pivot2 P1 where P1.min_period = ash.min_period and P1.sql_id = ash.sql_id and P1.sql_exec_id = ash.sql_exec_id and P1.sql_exec_start = ash.sql_exec_start group by ash.SQL_ID , ash.sql_exec_id, ash.sql_exec_start)  instance_list
from pivot2 ash
),
pivot4 as
(
select pivot3.* ,  rank() over (partition by  min_period order by  GREATEST(total_temp_mb,PHYS_READ_MB,PHYS_WRITE_MB) desc) my_rank
from pivot3
--where phys_read_mb > 100
)
select /* parallel(8) */ *
from pivot4
where my_rank < 10
order by to_date(min_period), GREATEST(total_temp_mb,PHYS_READ_MB,PHYS_WRITE_MB) desc;

