col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10


select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define TASK_NAME=&2     


PROMPT TASKS : &USERNAME - &TASK_NAME

undefine 1
undefine 2

column tASK_COMMENT   format A50
column task_name format a50
COLUMN STATUS FORMAT a30
colum sql_stmt format A300
column parallel_level format 9,999

COLUMN TASK_OWNER FORMAT a20
COLUMN TABLE_OWNER            FORMAT a20                                                                                                      
COLUMN   TABLE_NAME           FORMAT a20          
COLUMN NUMBER_COLUMN       FORMAT a10
COLUMN JOB_PREFIX       FORMAT a10
COLUMN JOB_CLASS       FORMAT a20

SELECT
  TASK_OWNER, TASK_NAME, CHUNK_TYPE, STATUS, TABLE_OWNER, TABLE_NAME, NUMBER_COLUMN, JOB_PREFIX,   PARALLEL_LEVEL, JOB_CLASS,  TASK_COMMENT,  regexp_replace( dbms_lob.substr(sql_stmt, 300), '[[:space:]]+', ' ')  sql_stmt 
FROM
  dba_parallel_execute_tasks
WHERE
  task_owner LIKE '&USERNAME'
AND task_name LIKE '&TASK_NAME';
