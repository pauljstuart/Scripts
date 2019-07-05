


set serveroutput on


/*
  name : GATHER_CONCURRENT_GLOBAL_STATS()
  written by : Paul Stuart
  Date : 4 Jan 2019
  Explanation :  gathers global statistics concurrently using DBMS_PARALLEL_EXECUTE package.
                 The list of target tables is obtained from MVDS.NDS_STATS_TABLE_LIST.

  Privileges required :
      object privileges : EXECUTE on DBMS_SCHEDULER proc
      system privileges : CREATE JOB

  Outputs :  logging table is  STATS_LOG_MESSAGES, which gets truncated before each new execution

  Parameters :
      CONCURRENT_DEGREE : the number of tables which have stats gathered simultaneously
      STATS_DEGREE : The degree of parallelism which is passed to the DBMS_STATS procedure calls.
*/






create or replace procedure  GATHER_CONCURRENT_GLOBAL_STATS( i_concur_degree IN INTEGER DEFAULT 4,  i_stats_degree  IN INTEGER DEFAULT 64)
AS
  CONCURRENT_DEGREE INTEGER := NVL(i_concur_degree, 10);
  STATS_DEGREE INTEGER := NVL(i_stats_degree, 64);
  s_px_task_name VARCHAR2(32) := 'PX_STATS_' || USER;
  already_exists exception; 
  pragma exception_init( already_exists, -955 );
  i_num_chunks INTEGER;
  s_status VARCHAR2(128);
  l_chunk_sql CLOB := q'#
  
SELECT
chunk_number as start_id,
chunk_number as end_id
from 
(
        select  TABLE_NAME, GROUP_NO,  partitioned, row_number() over (ORDER BY GROUP_NO,PARTITIONED ) chunk_number
        FROM MVDS.NDS_STATS_TABLE_LIST
        ORDER BY GROUP_NO

)
order by chunk_number

  #';


   l_chunk_sql_block       CLOB := q'# 

DECLARE
  s_table_name       VARCHAR2(256);
  i_chunk_number INTEGER;
  i_count   integer;
begin

  :end_id := :end_id;
  :start_id := :start_id;

  SELECT :start_id into i_chunk_number from dual;

  with start1 as
  (
          select /*+ MATERIALIZE  */ TABLE_NAME, GROUP_NO,  partitioned, row_number() over (ORDER BY GROUP_NO,PARTITIONED ) as chunk_number
          FROM MVDS.NDS_STATS_TABLE_LIST
          ORDER BY GROUP_NO
  )
  SELECT table_name into s_table_name 
  from start1 
  where chunk_number = :start_id and chunk_number = :end_id;
  
  insert into stats_log_messages values (sysdate, i_chunk_number, 'starting table ' || s_table_name );
  commit;

-- global table stats :

   DBMS_APPLICATION_INFO.SET_MODULE( 'tab: ' || s_table_name ,NULL );

    IF ( s_table_name = 'POSTING' )
    THEN
      dbms_stats.gather_table_stats( ownname => USER, 
                      tabname => s_table_name, 
                     method_opt => 'FOR COLUMNS size 1 ID,   REPORTING_DT,   SUB_BOOK , GAAP_CODE ,   COMPANY_CODE , LEDGER_ID , GCR_CORE_ID,   TRADE_BALANCE_ID,  TRADE_BALANCE_SOURCE,    NOTIONAL_VALUE_TRADE_BAL_ID,  NOTIONAL_VALUE_TRADE_BAL_SRC,    PARTITION_ID, SUB_PARTITION_ID, WORKFLOW_ID ,   COLLATERAL_ID,  COLLATERAL_FACILITY_ID,  FACILITY_ID,  FACILITY_SOURCE,  INSTRUMENT_SOURCE, INSTRUMENT_ID, BATCH_ID, ADJUSTMENT_ID,  DERIVED_INSTRUMENT_ID, DERIVED_INSTRUMENT_SOURCE, UNDERLYING_INSTRUMENT_ID,  UNDERLYING_INSTRUMENT_SRC,  BOOK_ID,ORIGINAL_GLOBAL_COMPANY_CODE,FACILITY_IPID,  FACILITY_RESTRICTED,  COLLATERAL_FACILITY_IPID, COLLATERAL_FACILITY_RESTRICTED ', 
                      degree => 160, 
                      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                      no_invalidate => FALSE,
                      granularity => 'GLOBAL' );
    ELSIF ( s_table_name = 'ICDLRD' )
      THEN

      dbms_stats.gather_table_stats( ownname => USER, 
                      tabname => s_table_name, 
                     method_opt => 'FOR COLUMNS size 1    ID,        PARTITION_ID,  SUB_PARTITION_ID,   WORKFLOW_ID ,     REPORTING_DT,    ADJUSTMENT_ID,   ADJUSTMENT_INDICATOR,  ALLOC_RULE_ID,   ORIG_GCR_FUNCTION_ID,     APPLIED_PARENT_CRXM_CP_ID,   BATCH_ID,    COMPANY_CODE,  CRXM_COUNTERPARTY_ID,   FAMILY,   GCR_COMPANY_CODE,   GCR_GAAP_CODE,  MANDATE_CODE,  OWNING_UNIT_SAP_COMPANY_CODE,   SUB_BOOK'    ,
                      degree => #' || STATS_DEGREE || q'#, 
                      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                      no_invalidate => FALSE,
                      granularity => 'GLOBAL' );
    ELSIF ( s_table_name = 'ICD' )
      THEN

      dbms_stats.gather_table_stats( ownname => USER, 
                      tabname => s_table_name, 
                     method_opt => 'FOR COLUMNS size 1 ID,  PARTITION_ID,     SUB_PARTITION_ID,  WORKFLOW_ID ,    FACILITY_SOURCE, EXCHANGE_ID ,   ISSUE_START_DT, bATCH_ID,     COMPANY_CODE,   GAAP_CODE,  GCR_COMPANY_CODE,  GCR_GAAP_CODE ,  REPORTING_DT,  SAP_MANAGEMENT_CENTER, ADJUSTMENT_ID,  GCR_INSTRUMENT_ID,  SAP_ACCOUNT_ID',
                      degree => #' || STATS_DEGREE || q'#, 
                      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                      no_invalidate => FALSE,
                      granularity => 'GLOBAL' );
    ELSE
      dbms_stats.gather_table_stats( ownname => USER, 
                      tabname => s_table_name, 
                      method_opt => 'FOR ALL COLUMNS SIZE 1', 
                      degree => #' || STATS_DEGREE || q'#, 
                      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                      no_invalidate => FALSE,
                      granularity => 'GLOBAL' );
    END IF;


  DBMS_APPLICATION_INFO.SET_MODULE( null ,NULL );  
 
end;
 #';  

 
begin 

  BEGIN
    execute immediate 'create table STATS_LOG_MESSAGES (log_date DATE, chunk_number INTEGER, log_text VARCHAR2(1024) )';
    dbms_output.put_line( 'created stats_log_messages' ); 
 
  EXCEPTION 
    when already_exists then 
    dbms_output.put_line( 'truncated stats_log_messages' ); 
    execute immediate 'TRUNCATE table STATS_LOG_MESSAGES';
  END;

  DBMS_OUTPUT.PUT_LINE('CONCURRENT_DEGREE = ' || CONCURRENT_DEGREE );
  DBMS_OUTPUT.PUT_LINE('STATS_DEGREE = ' || STATS_DEGREE );
  execute immediate q'# insert into stats_log_messages values (sysdate, 0, 'CONCURRENT_DEGREE =  #' || CONCURRENT_DEGREE || q'# ') #';
  execute immediate q'# insert into stats_log_messages values (sysdate, 0, 'STATS_DEGREE =  #' || STATS_DEGREE   || q'# ') #';
  commit;
  --
  -- Creating the parallel execute task  :
  --
  for i in (select 1 from USER_PARALLEL_EXECUTE_TASKS where task_name = s_px_task_name )
  loop
      DBMS_PARALLEL_EXECUTE.stop_TASK(task_name => s_px_task_name);
      DBMS_PARALLEL_EXECUTE.drop_TASK(task_name => s_px_task_name);
  end loop;


  DBMS_OUTPUT.PUT_LINE('Creating task ' || s_px_task_name );
  DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => s_px_task_name);

  --
  -- Creating the chunks :
  --

  DBMS_PARALLEL_EXECUTE.DROP_CHUNKS(task_name => s_px_task_name);
  DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL(task_name => s_px_task_name,sql_stmt => l_chunk_sql, by_rowid => false);

  select COUNT(*) INTO i_num_chunks
  from user_parallel_execute_CHUNKS
  WHERE TASK_NAME = s_px_task_name ;
  
  dbms_output.put_line('Created ' || i_num_chunks || ' chunks.' );
  --
  -- Now run the task :
  --
  DBMS_PARALLEL_EXECUTE.RUN_TASK( task_name => s_px_task_name, sql_stmt => l_chunk_sql_block , language_flag => DBMS_SQL.NATIVE, parallel_level => CONCURRENT_DEGREE, job_class => 'MERIVAL_STATS' );  

  SELECT  status INTO s_status
  FROM   user_parallel_execute_tasks where task_name = s_px_task_name ;
  DBMS_OUTPUT.PUT_LINE('The task status is ' || s_status );
   
 
end; 
/ 



