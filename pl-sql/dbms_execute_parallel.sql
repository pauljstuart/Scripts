


begin  
DBMS_PARALLEL_EXECUTE.drop_TASK(task_name => 'PX_TEST_TASK');
end;
/


begin  
DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => 'PX_TEST_TASK');
end;
/



DECLARE
  l_chunk_sql VARCHAR2(1000);
BEGIN
  l_chunk_sql := q'#
  
select distinct sub_partition_id as start_id, sub_partition_id as end_id
from mvds.posting@perf_nds
where partition_id = '57672_LDNLT'

  #';
  DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL(task_name => 'PX_TEST_TASK',sql_stmt => l_chunk_sql, by_rowid => false);
END;
/



select * from dba_parallel_execute_CHUNKS;


truncate table vad_trac1


SET serveroutput on
DECLARE 
   l_task VARCHAR2(24) := 'PX_TEST_TASK';
   l_sql_stmt             CLOB;        
   l_sql_stmt2           CLOB;
BEGIN 
--  
  l_sql_stmt := q'#
INSERT
  /* Append */
INTO vad_trac1 A
(


   #';  
--  
DBMS_PARALLEL_EXECUTE.RUN_TASK(l_task, l_sql_stmt || l_sql_stmt2, DBMS_SQL.NATIVE, parallel_level => 10);  
-- 
 dbms_output.put_line(DBMS_PARALLEL_EXECUTE.TASK_STATUS(l_task));  

END;
/


SELECT * FROM DBA_PARALLEL_EXECUTE_TASKS;



SELECT COUNT(*)
FROM 
vad_trac1





SELECT DBMS_PARALLEL_EXECUTE.TASK_STATUS( 'PX_TEST_TASK') FROM DUAL;



select * from dba_scheduler_job_run_details
where log_date > sysdate -1

select * from dba_parallel_execute_CHUNKS;

select * from dba_scheduler_job_run_details
where log_date > sysdate -1
and job_name like 'TASK%' ;


column start_ts format A21
column end_ts format A21
COLUMN TASK_NAME FORMAT a20
column task_owner format A20
select * from dba_parallel_execute_CHUNKS;



exec DBMS_PARALLEL_EXECUTE.STOP_TASK ('PX_TEST_TASK' );

select * from dba_scheduler_job_run_details
where log_date > sysdate -1
and job_name like 'TASK%' 
order by log_date

COLUMN TASK_NAME FORMAT a20
column job_name format A15
select chunk_id, task_name, status, start_id, job_name, start_ts, end_ts
 from dba_parallel_execute_CHUNKS
order by start_ts;

