





set serveroutput on


define USERNAME=MVDS
define CONCURRENT_DEGREE=10
define PX_TASK_NAME=PX_STATS_&USERNAME
define STATS_DEGREE=16


PROMPT
PROMPT Gathering stats on all objects in &USERNAME, with task name &PX_TASK_NAME
prompt


declare 
  already_exists exception; 
  pragma exception_init( already_exists, -955 ); 
begin 
   execute immediate 'create table STATS_LOG_MESSAGES (log_date DATE, chunk_number INTEGER, log_text VARCHAR2(1024) )';
   dbms_output.put_line( 'created stats_log_messages' ); 
 
 exception 
 when already_exists then 
 dbms_output.put_line( 'truncated stats_log_messages' ); 
 execute immediate 'TRUNCATE table STATS_LOG_MESSAGES';
end; 
/ 



----------------------- setup the parallel task ---------------------------------------------

prompt
prompt Creating the parallel execute task  :
prompt


begin

  for i in (select 1 from USER_PARALLEL_EXECUTE_TASKS where task_name = '&PX_TASK_NAME' )
  loop
      DBMS_PARALLEL_EXECUTE.stop_TASK(task_name => '&PX_TASK_NAME');
      DBMS_PARALLEL_EXECUTE.drop_TASK(task_name => '&PX_TASK_NAME');
  end loop;

  DBMS_OUTPUT.PUT_LINE('Creating task' );
  DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => '&PX_TASK_NAME');
end;
/



prompt
prompt Creating the chunks :
prompt


SET SERVEROUTPUT ON 
DECLARE
  i_num_chunks INTEGER;
  l_chunk_sql CLOB := q'#
  
SELECT
chunk_number as start_id,
chunk_number as end_id
from 
(
        select OWNER, TABLE_NAME, partitioned, row_number() over (order by partitioned) chunk_number
        from all_tables
        where owner = '&USERNAME'
        AND TEMPORARY = 'N'
        order by partitioned
)
order by chunk_number

  #';

BEGIN
  DBMS_PARALLEL_EXECUTE.DROP_CHUNKS(task_name => '&PX_TASK_NAME');
  DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL(task_name => '&PX_TASK_NAME',sql_stmt => l_chunk_sql, by_rowid => false);

  select COUNT(*) INTO i_num_chunks
  from dba_parallel_execute_CHUNKS
  WHERE TASK_NAME = '&PX_TASK_NAME' and TASK_OWNER = USER;
  
  dbms_output.put_line('Created ' || i_num_chunks || ' chunks.' );
END;
/




prompt
prompt Executing the task :
prompt



SET serveroutput on
DECLARE 
   l_task VARCHAR2(24) := '&PX_TASK_NAME';
   l_sql_stmt             CLOB;        
BEGIN 

  l_sql_stmt := q'# 


DECLARE
  s_table_name       VARCHAR2(256);
  s_partition_name       VARCHAR2(256);
  s_subpartition_name       VARCHAR2(256);
  s_index_name VARCHAR2(256);
  s_table_name2       VARCHAR2(256);
  i_chunk_number INTEGER;
  i_count   integer;
  C1     SYS_REFCURSOR;
  C2     SYS_REFCURSOR;
  C3     SYS_REFCURSOR;
  C4     SYS_REFCURSOR;
begin

  :end_id := :end_id;
  :start_id := :start_id;

  SELECT :start_id into i_chunk_number from dual;
  SELECT table_name into s_table_name from 
  (
            select OWNER, TABLE_NAME, partitioned, row_number() over (order by partitioned) chunk_number
            from all_tables
            where owner = '&USERNAME'
            AND TEMPORARY = 'N'
            order by partitioned
  )
  where chunk_number = :start_id and chunk_number = :end_id;
  
  insert into stats_log_messages values (sysdate, i_chunk_number, 'starting table ' || s_table_name );
  commit;

-- global table stats :

  OPEN C1 FOR ' select table_name   
                     from all_tab_statistics
                     where owner = ''&USERNAME''
                     and table_name = ''' || s_table_name || ''' AND (STALE_STATS IS NULL or stale_stats = ''YES'' )
                    AND object_type = ''TABLE''  ';

  LOOP                                        
     FETCH C1 INTO s_table_name2;
  
     EXIT WHEN C1%NOTFOUND; 
  

     insert into stats_log_messages values (sysdate, i_chunk_number, 'gathering  table ' || s_table_name2 );
     commit;

     DBMS_APPLICATION_INFO.SET_MODULE( 'tab: ' || s_table_name2 ,NULL );
     dbms_stats.gather_table_stats( ownname => '&USERNAME', 
                      tabname => s_table_name2, 
                      method_opt => 'FOR ALL COLUMNS SIZE 1', 
                      DEGREE => &STATS_DEGREE, 
                      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                      no_invalidate => FALSE,
                      granularity => 'GLOBAL' );
  
  END LOOP;
  CLOSE C1;
  
  
  -- partition stats :
  
  OPEN C2 FOR ' select partition_name   
                       from all_tab_statistics
                       where owner = ''&USERNAME''
                       and table_name = ''' || s_table_name || ''' AND (STALE_STATS IS NULL or stale_stats = ''YES'' )
                      AND object_type = ''PARTITION''  ';
  
  LOOP                                        
     FETCH C2 INTO s_partition_name;
  
     EXIT WHEN C2%NOTFOUND; 
  
       insert into stats_log_messages values (sysdate, i_chunk_number, 'gathering  table ' || s_table_name || ' partition ' || s_partition_name);
       commit;
       
       DBMS_APPLICATION_INFO.SET_MODULE( 'part: ' || s_table_name ||  '/' || s_partition_name ,NULL );

       dbms_stats.gather_table_stats( ownname => '&USERNAME', 
                      tabname => s_table_name, 
                      partname => s_partition_name,
                      method_opt => 'FOR ALL COLUMNS SIZE 1', 
                      DEGREE => &STATS_DEGREE, 
                      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                      no_invalidate => TRUE,
                      granularity => 'PARTITION' );
  
  END LOOP;
  CLOSE C2;
  
  -- subpartition table stats :
  
  OPEN C3 FOR ' select subpartition_name   
                       from all_tab_statistics
                       where owner = ''&USERNAME''
                       and table_name = ''' || s_table_name || ''' AND (STALE_STATS IS NULL or stale_stats = ''YES'' )
                      AND object_type = ''SUBPARTITION''  ';
  
  LOOP                                        
     FETCH C3 INTO s_subpartition_name;
  
     EXIT WHEN C3%NOTFOUND; 
  
     insert into stats_log_messages values (sysdate, i_chunk_number, 'gathering  table ' || s_table_name || ' subpartition ' || s_subpartition_name);
     commit;
     DBMS_APPLICATION_INFO.SET_MODULE( 'subpart: ' || s_table_name ||  '/' || s_subpartition_name ,NULL );
  
     dbms_stats.gather_table_stats( ownname => '&USERNAME',  
                      tabname => s_table_name, 
                      partname => s_subpartition_name,
                      method_opt => 'FOR ALL COLUMNS SIZE 1', 
                      DEGREE => &STATS_DEGREE, 
                      estimate_percent => 0.05 ,
                      no_invalidate => TRUE,
                      granularity => 'SUBPARTITION' );
  
  END LOOP;
  CLOSE C3;




  -- partition index stats :
  
  OPEN C3 FOR ' select partition_name , INDEX_NAME     
                       from all_ind_statistics
                       where owner = ''&USERNAME''
                       and table_name = ''' || s_table_name || ''' AND (STALE_STATS IS NULL or stale_stats = ''YES'' )
                      AND object_type = ''PARTITION''  ';
  
  LOOP                                        
     FETCH C3 INTO s_partition_name, s_index_name;
  
     EXIT WHEN C3%NOTFOUND; 
  
       insert into stats_log_messages values (sysdate, i_chunk_number, 'gathering  index part ' || s_index_name || ' partition ' || s_partition_name);
       commit;
       
       DBMS_APPLICATION_INFO.SET_MODULE( 'indpart: ' || s_index_name ||  '/' || s_partition_name ,NULL );

       dbms_stats.gather_index_stats( ownname => '&USERNAME', 
                      indname => s_index_name, 
                      partname => s_partition_name,
                      DEGREE => &STATS_DEGREE, 
                      granularity => 'PARTITION' );
  
  END LOOP;
  CLOSE C3;


  -- subpartition indexes :
  
  OPEN C4 FOR ' select subpartition_name , INDEX_NAME     
                       from all_ind_statistics
                       where owner = ''&USERNAME''
                       and table_name = ''' || s_table_name || ''' AND (STALE_STATS IS NULL or stale_stats = ''YES'' )
                      AND object_type = ''SUBPARTITION''  ';
  
  LOOP                                        
     FETCH C4 INTO s_subpartition_name, s_index_name;
  
     EXIT WHEN C4%NOTFOUND; 
  
       insert into stats_log_messages values (sysdate, i_chunk_number, 'gathering  index subpart ' || s_index_name || ' subpartition ' || s_subpartition_name);
       commit;
       
       DBMS_APPLICATION_INFO.SET_MODULE( 'indsubpart: ' || s_index_name ||  '/' || s_subpartition_name ,NULL );

       dbms_stats.gather_index_stats( ownname => '&USERNAME', 
                      indname => s_index_name, 
                      partname => s_subpartition_name,
                      DEGREE => &STATS_DEGREE, 
                      granularity => 'SUBPARTITION' );
  
  END LOOP;
  CLOSE C4;


  DBMS_APPLICATION_INFO.SET_MODULE( null ,NULL );

  
end;


 #';  
 
DBMS_PARALLEL_EXECUTE.RUN_TASK(l_task, l_sql_stmt , DBMS_SQL.NATIVE, parallel_level => &CONCURRENT_DEGREE);  

dbms_output.put_line(DBMS_PARALLEL_EXECUTE.TASK_STATUS(l_task));  

END;
/



