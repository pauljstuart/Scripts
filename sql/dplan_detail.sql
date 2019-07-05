

COLUMN operation FORMAT A50;
COLUMN cardinality FORMAT 'Est rows';
COLUMN last_starts FORMAT 'Actual Starts';
COLUMN last_output_rows FORMAT 'Actual Rows';


clear screen

define SQL_ID=&1;
define CHILD_NUM=&2;



prompt
prompt SQLID is &SQL_ID
prompt CHILD NUM is &CHILD_NUM
prompt




SELECT DISTINCT sql_id,  child_number, plan_hash_value
FROM gv$sql_plan_statistics_all 
where SQL_ID = '&SQL_ID' AND child_number = &CHILD_NUM;



SELECT id, parent_id, cardinality,last_starts, last_output_rows, last_starts, last_output_rows, last_cr_buffer_gets, last_disk_reads, last_elapsed_time, operation
FROM (
SELECT level lvl, id, parent_id, lpad( ' ', level, ':') || operation || ' ' || options || ' ' || object_name as operation, cardinality, last_starts, last_output_rows, last_cr_buffer_gets, last_disk_reads, last_elapsed_time
FROM (select * from gv$sql_plan_statistics_all where SQL_ID = '&SQL_ID' AND child_number = &CHILD_NUM )
START WITH id = 0
CONNECT by PRIOR id = parent_id )
ORDER BY lvl DESC, id;


