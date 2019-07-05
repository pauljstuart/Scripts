set echo off
set feedback off
set linesize 5000
set pagesize 5000
set wrap off




prompt
prompt =====================================
prompt



col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','%') PARAM1, nvl('&2','%') PARAM2, nvl('&3','EXECUTING') PARAM3 from dual ;


define USERNAME=&1
define SQL_ID=&2     
define STATUS=&3

undefine 1
undefine 2
undefine 3



column total_io_mb format 999,999,999
column avg_mb_persec format 999,999,999
column db_io_mb_persec format 999,999,999

COLUMN  PX_SERVERS_REQUESTED format 9,999
column  PX_SERVERS_ALLOCATED format 9,999

--
--
-- get AVG MB/SEC for all queries running right now :
--

select SM.*, sum(avg_mb_persec) over (  ) db_io_mb_persec
from
(
select      
  sql_id, 
  sql_exec_id,
  sql_exec_start,  
     max(elapsed_time)/1000000/60 etime_min, 
  --    ( max(last_refresh_time) - min(first_refresh_time) )*60*24 total_etime_mins
     sum(buffer_gets)  px_buffer_gets , 
      sum(physical_read_bytes+SM.physical_write_bytes)/(1024*1024) total_io_mb,
  sum(physical_read_bytes + physical_write_bytes)/(1024*1024)/(max(elapsed_time)/1000000) avg_mb_persec, 
  PX_SERVERS_REQUESTED ,
  PX_SERVERS_ALLOCATED
from gv$sql_monitor SM
WHERE      sql_id like '&SQL_ID'
AND        status like 'EXECUTING'
AND   sid in (SELECT     sid FROM  gv$session  WHERE   username like '&USERNAME'  )
group by      SM.sql_id, SM.sql_exec_id, SM.sql_exec_start,   PX_SERVERS_REQUESTED ,PX_SERVERS_ALLOCATED
) SM
order by 7 desc;






