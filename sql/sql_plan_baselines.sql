


COLUMN created FORMAT A20
COLUMN module FORMAT A30
COLUMN sql_text FORMAT A300 nowrap



col p1 new_value 1
col p2 new_value 2

select null p1, null p2 from dual where 1=2;
select nvl( '&1','%') p1, nvl('&2','%') p2 from dual ;

define SQL_HANDLE=&1
define PLAN_NAME=&2

undefine 1
undefine 2
undefine 3




prompt
prompt SQL_HANDLE = &SQL_HANDLE
prompt SQL_PLAN_NAME = &PLAN_NAME
prompt

SELECT sql_handle, 
     plan_name,
     module,
     parsing_schema_name, 
     creator,
     origin,
     created, 
     enabled, 
     fixed,
     accepted, 
     reproduced,
     executions, 
     signature,
     cpu_time,
     buffer_gets, 
    disk_reads, 
    rows_processed, 
    fetches
   --sql_text
FROM dba_sql_plan_baselines
WHERE 
     plan_name like '&PLAN_NAME'
AND sql_handle like '&SQL_HANDLE'
ORDER BY created asc;

