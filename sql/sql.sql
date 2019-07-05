

prompt
prompt =====================================
prompt



col USERNAME2 new_value 1 format A10
col SQL_ID2 new_value 2 format A10
col SQL_TEXT2 new_value 3 format A10

select null USERNAME2, null SQL_ID2, null SQL_TEXT2 from dual where 1=2;
select nvl( '&1','&_USER') USERNAME2, nvl('&2','%') SQL_ID2, nvl('&3','%') SQL_TEXT2 from dual ;


define USERNAME=&1
define SQL_ID=&2     
define SQL_TEXT=&3

undefine 1
undefine 2
undefine 3

COLUMN sql_text FORMAT A20

COLUMN  concurrency_wait_time_ms FORMAT 999,999,999,999 
COLUMN  cluster_wait_time_ms FORMAT 999,999,999,999 
COLUMN  user_io_wait_ms FORMAT 999,999,999,999 
COLUMN  etime_avg_ms FORMAT 999,999,999,999 
COLUMN  cpu_ms FORMAT 999,999,999,999 
column  users_executing format 999,999
COLUMN  lio_avg FORMAT 999,999,999,999
COLUMN  rows_avg FORMAT 999,999,999,999
column    is_bind_sensitive format A15
column    is_bind_aware format A15
column    is_shareable format A15
column avg_mb_sec format 999,999,999.9
column phys_io_mb_per_exec format 999,999,999,999
column executions format 999,999,999,999
column invalidations format 999,999
column last_active_time format A20
COLUMN FORCE_MATCHING_SIGNATURE FORMAT 999999999999999999999
COLUMN SQL_TEXT FORMAT a100
COLUMN SQL_COMMAND FORMAT a10



select inst_id,
     sql_id, 
    child_number,
    plan_hash_value,
     (select command_name from v$sqlcommand where command_type = S1.command_type)  SQL_COMMAND,
    module,   
    sql_profile,
    sql_plan_baseline,
    exact_matching_signature,
    FORCE_matching_signature,
    invalidations,
    users_executing,
    executions,    
    last_active_time,
    is_bind_sensitive,
    is_bind_aware, 
    is_shareable,
    decode( executions, 0, 0, (physical_read_bytes/executions/(1024*1024))  )  phys_io_mb_per_exec,
 --   decode( executions, 0, 0, (elapsed_time/executions)/1000 ) etime_avg_ms,
 --   decode( executions, 0, 0, buffer_gets/executions ) lio_avg,
 --   decode( executions, 0, 0, rows_processed/executions) rows_avg,
    sql_text
 --   (physical_read_bytes/(elapsed_time/1000000))/(1024*1024) avg_MB_sec
FROM gv$sql S1
  WHERE sql_id like '&SQL_ID'
  and  ( module like '&USERNAME' or parsing_schema_name like '&USERNAME')
  and sql_text like '&SQL_TEXT'
--  and plan_hash_value != 0
--  and sql_profile is not null
--    and executions != 0
--where rownum < 100
order by inst_id, sql_id, child_number ;

