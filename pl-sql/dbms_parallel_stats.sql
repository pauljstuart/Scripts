

define WORKFLOW_id=5094

set serveroutput on



begin  
DBMS_PARALLEL_EXECUTE.drop_TASK(task_name => 'PX_TEST_TASK');
end;
/


begin  
DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => 'PX_TEST_TASK');
end;
/



-- create the chunks :

SET SERVEROUTPUT ON 
DECLARE
  i_num_chunks INTEGER;
  l_chunk_sql CLOB := q'#
  
SELECT
row_number() OVER (ORDER BY table_name, partition_name) as start_id,
row_number() OVER (ORDER BY table_name, partition_name) as end_id,
  table_name,
  partition_name
FROM
  dba_tab_statistics
WHERE
  table_name IN
  (
    SELECT
      table_name
    FROM
      MVDS.nds_stats_table_list
    WHERE
      partitioned='Y'
  )
AND PARTITION_NAME LIKE 'WORKFLOW' || &WORKFLOW_ID || '%'
AND object_type = 'PARTITION'

  #';

BEGIN
  DBMS_PARALLEL_EXECUTE.DROP_CHUNKS(task_name => 'PX_TEST_TASK');
  DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL(task_name => 'PX_TEST_TASK',sql_stmt => l_chunk_sql, by_rowid => false);

  select COUNT(*) INTO i_num_chunks
  from dba_parallel_execute_CHUNKS
  WHERE TASK_NAME = 'PX_TEST_TASK';
  
  dbms_output.put_line('Created ' || i_num_chunks || ' chunks.' );
END;
/





-- now execute the chunks :


SET serveroutput on
DECLARE 
   l_task VARCHAR2(24) := 'PX_TEST_TASK';
   l_sql_stmt             CLOB;        
BEGIN 

  l_sql_stmt := q'# 

DECLARE
    s_table_name VARCHAR2(256);
    s_part_name  VARCHAR2(256);
begin

select table_name, partition_name into  s_table_name, s_part_name
from
(
SELECT
row_number() OVER (ORDER BY table_name, partition_name) as start_id,
row_number() OVER (ORDER BY table_name, partition_name) as end_id,
  table_name,
  partition_name
FROM
  dba_tab_statistics
WHERE
  table_name IN
  (
    SELECT
      table_name
    FROM
      MVDS.nds_stats_table_list
    WHERE
      partitioned='Y'
  )
AND PARTITION_NAME LIKE 'WORKFLOW' || &WORKFLOW_ID || '%'
AND object_type = 'PARTITION'
)
where start_id = :start_id and end_id = :end_id;

--where start_id = 5 and end_id = 5;

dbms_output.put_line( 'Doing ' ||  s_table_name || ' ' ||s_part_name );


  dbms_stats.gather_table_stats( ownname => 'MVDS', 
                    tabname => s_table_name, 
                    partname => s_part_name,
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 8, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'PARTITION' ,
                    no_invalidate      => FALSE
                    );
end;

 #';  
 
DBMS_PARALLEL_EXECUTE.RUN_TASK(l_task, l_sql_stmt , DBMS_SQL.NATIVE, parallel_level => 20);  

 dbms_output.put_line(DBMS_PARALLEL_EXECUTE.TASK_STATUS(l_task));  

END;
/



-- look at the results :


column end_ts format A21
COLUMN TASK_NAME FORMAT a20
column task_owner format A20
column error_message format A50

select task_name, status, start_ts, end_ts,  (CAST(end_ts  AS DATE) - CAST( start_ts AS DATE)) * 60*24 etime_mins , error_code, error_message 
from dba_parallel_execute_CHUNKS
where task_name = '&1'
order by END_TS;
