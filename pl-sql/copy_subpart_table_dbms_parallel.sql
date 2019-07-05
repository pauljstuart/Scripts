
set serveroutput on

ALTER SESSION SET optimizer_adaptive_features=FALSE;
ALTER SESSION SET optimizer_adaptive_plans=FALSE;     
ALTER SESSION SET optimizer_adaptive_reporting_only=FALSE;    
ALTER SESSION SET optimizer_adaptive_statistics=FALSE;          
ALTER SESSION SET optimizer_inmemory_aware=FALSE;    


----------------------------------------------------------------------------------------------------------
-- this proc copies a list of partitions from one table into one single partition in the target table :
----------------------------------------------------------------------------------------------------------


@objects MVDS COPY_SUBPART_TABLE



create or replace procedure copy_subpart_table( s_source_table IN VARCHAR2 )
AS
  type myarray is table of varchar2(32) index by binary_integer;
  v_workflows myarray;
  already_exists exception; 

  pragma exception_init( already_exists, -955 );

  s_create_text VARCHAR2(32000);
  --  s_source_table VARCHAR2(32) := 'POSTING';
   s_source_schema VARCHAR2(64) := 'MVDS';
  s_postfix VARCHAR2(5) := '_WF';
  s_target_schema VARCHAR2(32) := USER;
  s_target_table varchar2(128) := s_source_table || s_postfix;
  s_target_tablespace VARCHAR2(128) := 'MERIVAL_DATA_LIVE';
s_px_task_name VARCHAR2(256) ;
   s_high_value VARCHAR2(64);
   s_part_create_text VARCHAR2(32000);

CONCURRENT_DEGREE number := 10;
  l_chunk_sql CLOB ;
   l_sql_stmt  CLOB ; 
  i_num_chunks NUMBER; 
s_status  VARCHAR2(256);
  i_count INTEGER;


begin

    OUTPUT_PKG.SETUP( p_process_name => s_source_table, p_log_level => 0);
   execute immediate 'alter session enable parallel dml';

  -- generate the DDL to create the target table
  dbms_metadata.set_transform_param (dbms_metadata.session_transform,'TABLESPACE',false);
  dbms_metadata.set_transform_param (dbms_metadata.session_transform,'SEGMENT_ATTRIBUTES', false);
  dbms_metadata.set_transform_param (dbms_metadata.session_transform,'STORAGE',false);
  dbms_metadata.set_transform_param (dbms_metadata.session_transform,'REF_CONSTRAINTS', false);
  dbms_metadata.set_transform_param (dbms_metadata.session_transform,'CONSTRAINTS', false);
  dbms_metadata.set_transform_param (dbms_metadata.session_transform,'PARTITIONING', false);
  s_create_text := dbms_metadata.get_ddl( object_type => 'TABLE', name =>  s_source_table  , schema => s_source_schema  );
  s_create_text := regexp_replace( s_create_text, '   \)',', "LOCATION" VARCHAR2(64 CHAR)' || CHR(13) || '   )' );
  IF ( s_source_table = 'GRS_RECORD' )
    THEN
       s_create_text := regexp_replace( s_create_text, '\"SUB_PARTITION_ID\" VARCHAR2\(20 CHAR\)'  ,   ' SUB_PARTITION_ID VARCHAR2(20 CHAR),   WORKFLOW_ID  NUMBER'  );
    END IF;
  -- put new name :
  s_create_text := replace( s_create_text,  s_source_schema || '"."' || s_source_table, s_target_schema || '"."' || s_target_table ) ;
  -- add new partitioning
  s_create_text := s_create_text || '
    TABLESPACE ' || s_target_tablespace || '
    COMPRESS FOR QUERY HIGH
    PARTITION BY LIST (PARTITION_ID) 
    SUBPARTITION BY LIST (SUB_PARTITION_ID) 
    (PARTITION WORKFLOW1 VALUES(''DEFAULT'') ( SUBPARTITION WORKFLOW0DUMMY_0  VALUES (''0'')  ) 
     )';

  -- now create the target table
  BEGIN
     -- DBMS_OUTPUT.PUT_LINE( s_create_text );
    OUTPUT_PKG.output('Creating ' || s_target_table );
    execute immediate s_create_text;
    OUTPUT_PKG.output('created ' || s_target_table );
   -- now gather global stats
   dbms_stats.gather_table_stats( ownname => USER, tabname => s_target_table , 
                method_opt => 'FOR ALL COLUMNS SIZE 1', 
                DEGREE => 16, 
                estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                granularity => 'GLOBAL AND PARTITION' );
  EXCEPTION 
    when already_exists then 
    OUTPUT_PKG.output( s_target_table || ' already exists');
  END;

  l_chunk_sql  := q'#
  
            SELECT WORKFLOW_ID as start_id, WORKFLOW_ID AS END_ID
            FROM
                  (
                  SELECT DISTINCT
                    workflow_id,
                    region_code 
                FROM
                    MVDS.neutral_control
                WHERE
                    reporting_date = '20190131'
                    AND run_type IN (
                        'BATCH',
                        'INTRA',
                        'GGAT'
                    )
                    AND frequency = 'M' 
                 )  WHERE WORKFLOW_ID IS NOT NULL 
               --   AND ROWNUM < 3
                   ORDER BY WORKFLOW_ID

  #';



   l_sql_stmt        := q'# 

DECLARE
  s_source_table            VARCHAR2(256) := '#' || s_source_table  || q'#';
  s_source_schema           VARCHAR2(256) := '#' || s_source_schema || q'#';
  s_workflow_id             VARCHAR2(256) ;
  s_target_table            VARCHAR2(256) := '#' || s_target_table  || q'#';
  s_temp_table             VARCHAR2(256);
  s_subpartition_name         VARCHAR2(256);
  i_chunk_number INTEGER;
  i_count   integer;
    i_source_count number;
    i_target_count  number;
  s_source_column_list CLOB;
  s_part_create_text CLOB;
 s_final_ctas_text CLOB;
  s_command varchar2(4000);
  value_already_exists exception;
  pragma exception_init( value_already_exists, -14312 );
begin

  :end_id := :end_id;
  :start_id := :start_id;

  SELECT :start_id into s_workflow_id from dual;

  OUTPUT_PKG.SETUP( p_process_name => s_source_table || '_CHUNK' || s_workflow_id , p_log_level => 0);
  OUTPUT_PKG.output( 'Starting workflow ' || s_workflow_id ,0, s_workflow_id );
  dbms_application_info.set_module(s_source_table || ' ' || s_workflow_id , null);

  select count(*) INTO i_count from dba_tab_partitions where TABLE_NAME = s_source_table AND TABLE_OWNER = s_source_schema AND  partition_name like 'WORKFLOW' || s_workflow_id || '%';
  OUTPUT_PKG.output('There are ' || i_count  || ' partitions in workflow ' || s_workflow_id, 0,s_workflow_id );


    -- create the target WORKFLOW_ID partition
    BEGIN
        OUTPUT_PKG.output('Creating partition ' || s_workflow_id, s_workflow_id  );
        s_part_create_text := 'alter table ' || s_target_table || ' add partition WORKFLOW' || s_workflow_id || '  VALUES(' ||  s_workflow_id || ')'  ;
        OUTPUT_PKG.output( s_part_create_text,0, s_workflow_id );
        execute immediate s_part_create_text;

    EXCEPTION 
        when value_already_exists then 
        OUTPUT_PKG.output( 'Partition WORKFLOW' ||  s_workflow_id || ' already exists', 0, s_workflow_id);
        -- check source and target rowcounts
        i_count := 0;
        i_source_count := 0;
        i_target_count := 0;
        s_command := 'select /*+ parallel(4) */ count(*)  from ' || s_target_table || ' partition(WORKFLOW' || s_workflow_id || ')  ';
        execute immediate  s_command into i_target_count;
        OUTPUT_PKG.output('target row count for ' || s_target_table || ' workflow ' || s_workflow_id || ' is ' || i_target_count, 0, s_workflow_id);
        -- get the source rowcount :
        for  C3 in  (select partition_name from user_tab_partitions where table_name = s_source_table and partition_name like 'WORKFLOW' || s_workflow_id || '%')
          loop
            s_command := 'select /*+ parallel(4) */ count(*) from  ' || s_source_table || ' PARTITION(' || C3.partition_name  || ')   ';
            execute immediate  s_command into i_count;
            i_source_count := i_source_count + i_count;
          end loop;
        OUTPUT_PKG.output('source row count for ' || s_source_table || ' workflow ' || s_workflow_id || ' is ' || i_source_count,0, s_workflow_id);
        if ( i_target_count = i_source_count)  
          THEN
             OUTPUT_PKG.output('The rowcounts are the same - this workflow ' || s_workflow_id  || ' has been done already. Skipping. ',0, s_workflow_id );
             RETURN;
          ELSE 
              OUTPUT_PKG.output('The rowcounts are not the same  - this workflow ' || s_workflow_id  || ' needs to be repeated ' ,0,s_workflow_id);
              OUTPUT_PKG.output('truncating this target partition WORKFLOW' || s_workflow_id, 0, s_workflow_id ); 
              execute immediate 'alter  table ' || s_target_table || ' truncate  partition WORKFLOW' || s_workflow_id ;
          END IF;
      END;

    -- get the subpartition name
    select subpartition_name into s_subpartition_name from USER_tab_subpartitions where table_name = s_target_table and partition_name = 'WORKFLOW' || s_workflow_id;
    OUTPUT_PKG.output('The subpartition name is ' || s_subpartition_name,0, s_workflow_id );
    -- now rename the subpartition
    OUTPUT_PKG.output('Now renaming subpartition ' || s_subpartition_name, 0, s_workflow_id );
    OUTPUT_PKG.output('alter table ' || s_target_table || ' rename  subpartition ' || s_subpartition_name || ' to ' ||  'WORKFLOW' ||s_workflow_id || '_N0', 5 );
    EXECUTE IMMEDIATE 'alter table ' || s_target_table || ' rename  subpartition ' || s_subpartition_name || ' to ' ||  'WORKFLOW' ||s_workflow_id || '_N0'   ;
    s_subpartition_name := 'WORKFLOW' ||s_workflow_id || '_N0';

          ------------------------------------------ CREATE THE CTAS  -----------------------------------------------------------------------
           s_temp_table := s_target_table || '_WORKFLOW' || s_workflow_id;
            -- insert target column list :
            s_source_column_list := '';
            s_final_ctas_text := '';
        
            -- source column list :
             FOR C4 in (select  column_name   
                    from dba_tab_columns
                    where table_name = s_source_table and owner = s_source_schema
                    order by column_id
              )
            LOOP
             s_source_column_list := s_source_column_list || C4.column_name || ',';
            end LOOP;
            OUTPUT_PKG.output('SOURCE COLUMN LIST ' || s_source_column_list, 5);
            s_source_column_list := REPLACE(s_source_column_list,',PARTITION_ID,',    q'@ , regexp_substr(PARTITION_ID,'([0-9]+)\_[a-zA-Z\-]+', 1,1,'i', 1)  as PARTITION_ID, @');
            s_source_column_list :=  s_source_column_list || q'@ CAST( regexp_substr(PARTITION_ID,'[0-9]+\_([a-zA-Z0-9\-]+)', 1,1,'i', 1) AS VARCHAR2(64 CHAR)) as LOCATION   @' ;
            IF ( s_source_table = 'GRS_RECORD' )
               THEN
                s_source_column_list :=   REPLACE(s_source_column_list,'SUB_PARTITION_ID,',    q'@ SUB_PARTITION_ID , CAST( regexp_substr(PARTITION_ID,'([0-9]+)\_[a-zA-Z\-]+', 1,1,'i', 1) AS NUMBER ) as WORKFLOW_ID , @');
               END IF;
              OUTPUT_PKG.output('source column list ' || s_source_column_list, 5);
        
            s_final_ctas_text := 'CREATE TABLE ' || s_temp_table || ' parallel 8 COMPRESS FOR QUERY HIGH AS  SELECT  /*+ FULL(G) CARDINALITY(G,10E6) parallel(G,8) NO_GATHER_OPTIMIZER_STATISTICS */ ' || s_source_column_list || ' FROM ' || s_source_schema || '.' || s_source_table || ' G   
                  where partition_id in (SELECT  PARTITION_ID FROM neutral_control WHERE workflow_id = ' || s_workflow_id  || ')';
             OUTPUT_PKG.output( 'workflow ' || s_workflow_id || ' - ' ||   s_final_ctas_text , 5);

           ------------------------------------------ -----------------------------------------------------------------------
    for i in (select 1 from user_tables where table_name  = s_temp_table )
     loop
        execute immediate 'drop table ' || s_temp_table ;
     end loop;

    OUTPUT_PKG.output('Running CTAS statement for ' || s_workflow_id, 0,   s_workflow_id ); 
    execute immediate s_final_ctas_text;
    commit;

    OUTPUT_PKG.output('Gathering stats on CTAS for ' || s_workflow_id,  0, s_workflow_id ); 
    dbms_stats.gather_table_stats( ownname => USER, tabname => s_temp_table, 
        method_opt => 'FOR ALL COLUMNS SIZE 1', 
        DEGREE => 4, 
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
        granularity => 'ALL' );

    -- do the subpartition exchange 
      OUTPUT_PKG.output('Doing partition exchange for ' || s_workflow_id || '  -  ALTER TABLE ' || s_target_table || ' EXCHANGE SUBPARTITION ' || s_subpartition_name || '  WITH TABLE '  || s_temp_table, 0,  s_workflow_id ); 
    EXECUTE IMMEDIATE 'ALTER TABLE ' || s_target_table || ' EXCHANGE SUBPARTITION ' || s_subpartition_name || '  WITH TABLE '  || s_temp_table;
     OUTPUT_PKG.output('Workflow ' || s_workflow_id ||  ' completed exchange', 0, s_workflow_id );

   DBMS_APPLICATION_INFO.SET_MODULE( null ,NULL );  
end;
 #';  
  
    -- iterate through all workflows :

  s_px_task_name := s_target_table ;
  --
  -- Creating the parallel execute task  :
  --
  for i in (select 1 from USER_PARALLEL_EXECUTE_TASKS where task_name = s_px_task_name )
  loop
      DBMS_PARALLEL_EXECUTE.stop_TASK(task_name => s_px_task_name);
      DBMS_PARALLEL_EXECUTE.drop_TASK(task_name => s_px_task_name);
  end loop;


   OUTPUT_PKG.output('Creating task ' || s_px_task_name );
  DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => s_px_task_name);

  --
  -- Creating the chunks :
  --
   OUTPUT_PKG.output('Creating chunks ' || s_px_task_name, 0 );
  DBMS_PARALLEL_EXECUTE.DROP_CHUNKS(task_name => s_px_task_name);

  DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL(task_name => s_px_task_name,sql_stmt => l_chunk_sql, by_rowid => false);

  select COUNT(*) INTO i_num_chunks
  from user_parallel_execute_CHUNKS
  WHERE TASK_NAME = s_px_task_name ;
  
   OUTPUT_PKG.output('Created ' || i_num_chunks || ' chunks.');
  --
  -- Now run the task :
  --
   -- dbms_output.put_line('>> ' || l_sql_stmt);
   DBMS_PARALLEL_EXECUTE.RUN_TASK( task_name => s_px_task_name,  sql_stmt => l_sql_stmt ,language_flag => DBMS_SQL.NATIVE, parallel_level => CONCURRENT_DEGREE);  

  SELECT  status INTO s_status
  FROM   user_parallel_execute_tasks where task_name = s_px_task_name ;
  OUTPUT_PKG.output('The task status is ' || s_px_task_name || ' : ' || s_status );

   OUTPUT_PKG.output('Gathering stats on ' || s_target_table);
  dbms_application_info.set_module('Gather stats ' || s_target_table, null);

  dbms_stats.gather_table_stats( ownname => USER, tabname => s_target_table, 
                method_opt => 'FOR ALL COLUMNS SIZE 1', 
                DEGREE => 16, 
                estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                granularity => 'GLOBAL' );
  
   OUTPUT_PKG.output('Finished ' || s_target_table);

  dbms_application_info.set_module(NULL,null);

END;
/
----------------------------------------------------------------------------------------------------------

alter session set current_schema=MVDS;



------------ SPACE USAGE ----------------------------------------
SELECT SEGMENT_NAME, COUNT(*), TRUNC(SUM(BYTES)/(1024*1024)) SIZE_MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'MERIVAL_DATA_LIVE'
GROUP BY SEGMENT_NAME
ORDER BY 3 DESC;

@instances

@ts_size
@TS_USAGE MERIVAL_DATA_LIVE
    

@asm_dg DATA


SET SERVEROUTPUT ON
BEGIN
FOR C1 IN (SELECT table_name from user_tables where table_name like 'ICDLRD_WF_WORKFLOW%' )
  LOOP
  DBMS_OUTPUT.PUT_LINE('>> ' || C1.TABLE_NAME );
   EXECUTE IMMEDIATE 'DROP TABLE ' || C1.TABLE_NAME;
  END LOOP;
END;
/

COLUMN NAME FORMAT a30

select * from dba_part_key_columns
where owner = 'MVDS'
AND COLUMN_NAME = 'PARTITION_ID'
AND OBJECT_TYPE = 'TABLE';



@LOGIN

SET SERVEROUTPUT ON
exec  copy_subpart_table( 'ICDCAP');



-------------------------------------------------

-- MONITORING 


@user_privs MVDS

@PX_CHUNKS MVDS GRS_RECORD_WF

 UNASSIGNED

 PROCESSED

@TABLES
@PX_scheduler MVDS ICDLRD_WF

@sess/session_sql2

@reports/sql_monitor_report 32bna6rfjsfgy     16777216

@ash/ash_sqlstats_all MVDS % 1
@sql/dplan  9xg7kjxd7a0tb    0

@TAB_PARTITIONS MVDS GRS_RECORD_WF

@PART_TABLE MVDS ICDLRD

@sess/session_sql2

@COLUMNS MVDS GRS_RECORD_WF

exec DBMS_PARALLEL_EXECUTE.stop_TASK(task_name => 'ICDLRD_WF');

@PX_TASKS MVDS ICDLRD_WF


@PX_CHUNKS MVDS GRS_RECORD_WF

@PX_SCHEDULER MVDS GRS_RECORD_WF

EXEC DBMS_SCHEDULER.STOP_JOB('TASK$_16940_5');

CREATE TABLE WORKFLOW1292 parallel 12 AS 
SELECT /*+  parallel(G,8) NO_GATHER_OPTIMIZER_STATISTICS */ *
FROM GRS_RECORD g
where partition_id in (SELECT  PARTITION_ID FROM neutral_control WHERE workflow_id = 1292) ;


@instances

@ash/ash_sqlstats_all

@io/io_sysmetric

EXEC SYS.KILL_SESSION( 2340,     63623, 'MVDS', 1, 'PERF_ANALYSIS');

@TABLES


@SESS/SESSION_sql2
@tab_SUBpartitions MVDS ICDLRD_WF

@ash/ash_sqlstats_all MVDS

ddjjn4ckxm1gx     16777216 
@SQL/DPLAN_AWR ddjjn4ckxm1gx                804284881

@columns MVDS GRS_RECORD

@sql/show_sqltext 6v68g6va9dr6n

-------------------- OUTPUT LOG :

SELECT *
FROM
(
select LOG_DATE, CHUNK_NUMBER, LOG_TEXT, ROW_NUMBER() OVER (ORDER BY LOG_DATE DESC) ROW_NUM
 from outputlog 
order by log_date
)
WHERE ROW_NUM < 20; 





select LOG_DATE, CHUNK_NUMBER, LOG_TEXT, ROW_NUMBER() OVER (ORDER BY LOG_DATE DESC) ROW_NUM
 from outputlog 
where chunk_number = 922
order by log_date


----------------------------- reporting_control stuff ---------------------------


--DROP TABLE REPORTING_CONTROL_WF;
--truncate table REPORTING_CONTROL_WF;

  CREATE TABLE REPORTING_CONTROL_WF 
   (	"ID" NUMBER(38,0) NOT NULL ENABLE, 
	"REPORTING_DATE" VARCHAR2(8 CHAR), 
	"REGION_CODE" VARCHAR2(4 CHAR), 
	"WORKFLOW_ID" NUMBER(38,0), 
	"INTRADAY_LOCATION_ID" VARCHAR2(16 CHAR), 
	"PARTITION_ID" VARCHAR2(16 CHAR), 
    LOCATION  VARCHAR2(16 CHAR),
	"FREQUENCY" VARCHAR2(1 CHAR), 
	"CREATED_DATE" DATE, 
	"RUN_TYPE" VARCHAR2(16 CHAR), 
	"RUN_SUBTYPE" VARCHAR2(4 CHAR), 
	"MANUAL_LOAD_ID" VARCHAR2(10 CHAR) DEFAULT '-', 
	"GC_LOAD_ONLY" VARCHAR2(1 CHAR) DEFAULT 'N', 
	"MV_UUID" VARCHAR2(32 CHAR) DEFAULT '-', 
	"SOURCE_REFERENCE_VERSION" NUMBER(38,0) DEFAULT 0, 
	"GCR_COMPANY_CODE" VARCHAR2(4 CHAR), 
	"REP_START_DT" DATE, 
	"REP_END_DT" DATE, 
	"VAL_END_DT" DATE DEFAULT TO_DATE('01/01/2000 00:00:00','DD/MM/YYYY hh24:mi:ss'), 
	"TRANSFORMATION_TYPE" VARCHAR2(8 CHAR), 
	"GCR_CONS_RUN_VERSION" NUMBER(4,0) DEFAULT 0, 
	"REP_UPDATED_DT" DATE DEFAULT TO_DATE('01/01/2000 00:00:00','DD/MM/YYYY hh24:mi:ss'), 
	"REPORTING_TARGET" VARCHAR2(10 CHAR) DEFAULT '-', 
	"ADJUSTMENT_SCOPE" VARCHAR2(4 CHAR) DEFAULT '-', 
	"AS_OF_DATE" VARCHAR2(8 CHAR) DEFAULT '-', 
	"AXIOM_LOAD" VARCHAR2(1 CHAR) DEFAULT '-', 
	"POSTING_DATE" VARCHAR2(8 CHAR) DEFAULT '-', 
	"CONS_RUN_VERSION_LATEST_FLAG" VARCHAR2(1 CHAR) DEFAULT '-', 
	 CONSTRAINT "PK_REPORTING_CONTROL_WF" PRIMARY KEY ("ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS  ENABLE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING;

INSERT INTO REPORTING_CONTROL_WF 
     (ID, 
	REPORTING_DATE,
	REGION_CODE  ,
	WORKFLOW_ID ,
	INTRADAY_LOCATION_ID, 
	PARTITION_ID ,
    LOCATION  ,
	FREQUENCY ,
	CREATED_DATE, 
	RUN_TYPE ,
	RUN_SUBTYPE ,
	MANUAL_LOAD_ID,  
	GC_LOAD_ONLY,
	MV_UUID,
	SOURCE_REFERENCE_VERSION,
	GCR_COMPANY_CODE ,
	REP_START_DT , 
	REP_END_DT , 
	VAL_END_DT , 
	TRANSFORMATION_TYPE , 
	GCR_CONS_RUN_VERSION, 
	REP_UPDATED_DT ,
	REPORTING_TARGET , 
	ADJUSTMENT_SCOPE  ,
	AS_OF_DATE , 
	AXIOM_LOAD,
	POSTING_DATE ,
	CONS_RUN_VERSION_LATEST_FLAG)
SELECT   distinct   ID, 
	REPORTING_DATE,
	REGION_CODE  ,
	WORKFLOW_ID ,
	INTRADAY_LOCATION_ID, 
	 workflow_id as PARTITION_ID ,
    INTRADAY_LOCATION_ID AS LOCATION  ,
	FREQUENCY ,
	CREATED_DATE, 
	RUN_TYPE ,
	RUN_SUBTYPE ,
	MANUAL_LOAD_ID,  
	GC_LOAD_ONLY,
	MV_UUID,
	SOURCE_REFERENCE_VERSION,
	GCR_COMPANY_CODE ,
	REP_START_DT , 
	REP_END_DT , 
	VAL_END_DT , 
	TRANSFORMATION_TYPE , 
	GCR_CONS_RUN_VERSION, 
	REP_UPDATED_DT ,
	REPORTING_TARGET , 
	ADJUSTMENT_SCOPE  ,
	AS_OF_DATE , 
	AXIOM_LOAD,
	POSTING_DATE ,
	CONS_RUN_VERSION_LATEST_FLAG 
FROM REPORTING_CONTROL;
@LOGIN

@COLUMNS MVDS REPORTING_CONTROL_WF

alter table REPORTING_CONTROL_WF ADD (WORKFLOW_LOCATION VARCHAR2(48) );

UPDATE REPORTING_CONTROL_WF SET WORKFLOW_LOCATION = WORKFLOW_ID || '_' || LOCATION;
SELECT DISTINCT WORKFLOW_ID, LOCATION, WORKFLOW_LOCATION FROM REPORTING_CONTROL_WF;

select count(*) from reporting_control;

 EXEC DBMS_STATS.GATHER_TABLE_STATS( USER, 'REPORTING_CONTROL_WF');

select * from reporting_control;

select distinct partition_id from reporting_control
order by partition_id;

SELECT COUNT(*)
FROM 
        POSTING_WF Z,   reporting_control_WF NC
 WHERE  nc.partition_id = z.partition_id
AND NC.REPORTING_DATE = '20190131';

SELECT COUNT(*)
FROM 
        POSTING Z,   reporting_control NC
 WHERE  nc.partition_id = z.partition_id
AND NC.partition_id = '975_WMUS1';




SELECT DISTINCT LOCATION, INTRADAY_LOCATION_ID FROM 
REPORTING_CONTROL_WF;

UPDATE REPORTING_CONTROL_WF
SET LOCATION = INTRADAY_LOCATION_ID;


select * from reporting_control_WF
where reporting_date = '20190131';


select * from posting_wf;

----------------------------- storage indexes ----------------------------------------------------------


@DAYS 7
column end_time format A21
with pivot1 as
(
select snap_id, 
       stat_name, 
       instance_number,
       (select end_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) end_time, 
       greatest ( value -  lag(value,1) over (partition by instance_number, stat_name order by snap_id) , 0 ) as value_change
FROM DBA_HIST_SYSSTAT AWR
where  stat_name  like 'cell physical IO bytes saved by storage index'
and dbid = (select dbid from v$database)
and dbid = (select dbid from v$database)
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
)
select snap_id, stat_name, end_time,  sum(value_change) value_change_db
from pivot1
group by snap_id, stat_name, end_time
order by snap_id;

column name format A50
column value format 999
select inst_id, name, value
from gv$sysstat where
name like 'cell physical IO bytes saved by storage index';

INST_ID NAME                                               VALUE
------- -------------------------------------------------- -----
      1 cell physical IO bytes saved by storage index          0

1 row selected. 


@services


set termout off
SELECT /*+ PARALLEL(16) */  count(*)
FROM POSTING_WF partition(WORKFLOW1161)
WHERE partition_id = '1161'
and location = 'LDNBR';
set termout on

@instances

select
    decode(name,
    'cell physical IO bytes saved by storage index',
    'Storage index Savings',
    'cell physical IO interconnect bytes returned by smart scan',
    'Smart Scans'
    ) as stat_name,
    value/1024/1024 as stat_value
from v$mystat s, v$statname n
where
    s.statistic# = n.statistic#
and
    n.name in (
    'cell physical IO bytes saved by storage index',
    'cell physical IO interconnect bytes returned by smart scan'
    )
/


---------------------------------- synonyms and views ---------------------------------------------------------------------------

@synonyms % MERIVAL_POSTING_S

@synonyms % MERIVAL_GRS_RECORD_S

@show_view    MVDS                 POSTING_V35     


@show_view    MVDS                 GRS_RECORD_V03  



PARTITION_ID     LOCATION                                                             COUNT(*)
---------------- ---------------------------------------------------------------- ------------
1161             LDNBR                                                              39,520,711
1161             JOBRG                                                               1,143,825
1161             PRS                                                                   332,930
1161             GAMLU                                                                  13,308
1161             SMID                                                                   11,265
1161             LDN                                                                     7,317
1161             GAMEU                                                                   5,560
1161             MENA                                                                    3,632
1161             ZURAM                                                                   3,016
1161             STKHM                                                                   2,627
1161             AMS                                                                     1,662                                                   


select  PARTITION_ID, LOCATION, COUNT(*)
FROM POSTING_WF PARTITION(WORKFLOW1161)
GROUP BY PARTITION_ID, LOCATION
ORDER BY 3 DESC;

@TAB_PARTITIONS MVDS POSTING_WF

SELECT /*+ PARALLEL(4) */  partition_id , location
FROM POSTING_WF partition 
WHERE partition_id = '2640'
and location = 'SGSU'


SELECT
    COUNT(*)
FROM
    posting_wf             z,
    reporting_control_wf   nc
WHERE
    nc.partition_id = z.partition_id 
and nc.gcr_company_code = z.company_code 
and nc.location = z.location
and nc.transformation_type = 'CFT/GFT'
and nc.REPORTING_DATE = '20190131'



SELECT COUNT(*)
FROM 
        POSTING_WF Z,   
        ( select distinct partition_id from reporting_control_WF 
        where REPORTING_DATE = '20190131' ) nc
 WHERE  nc.partition_id = z.partition_id


-- a simple block, which includes the session stats and the +...+ section:

SET SERVEROUTPUT ON

alter session set "_SERIAL_DIRECT_READ"=true;
DECLARE

	TYPE             ASSOC_ARRAY_T IS TABLE OF INTEGER  INDEX BY VARCHAR2(256);
	StatArray        ASSOC_ARRAY_T;
	l_index          VARCHAR2(256);
	cursor_name      INTEGER;
	i_total_fetches  INTEGER := 0;
  i_timestart      NUMBER := dbms_utility.get_time();
  i_elapsed_time   NUMBER;
	sql_text_string  CLOB;
  myReport        CLOB;
	ret              INTEGER;
  adjusted_value   NUMBER;
  s_SQL_ID VARCHAR2(13);
  i_CHILD_NO integer;
  i_SQL_EXEC_ID integer;

BEGIN

sql_text_string  := q'#



SELECT /*+ PARALLEL(4) */ *
FROM POSTING_wf 
WHERE partition_id = '1070' and location = 'WMCH1'

#';

/*
SELECT  *
FROM POSTING
WHERE partition_id = '1070_WMCH1'
*/
----------------------------- 1st stats snapshot --------------------------------------------------

FOR r IN (select SN.name, SS.value FROM v$mystat SS, v$statname SN WHERE SS.statistic# = SN.statistic#) 
  LOOP
     --dbms_output.put_line('loading ' || r.name );
    StatArray(r.name) := r.value;
  END LOOP;


----------------- now execute the SQL ------------------------------------------------

cursor_name := DBMS_SQL.OPEN_CURSOR;

DBMS_SQL.PARSE(cursor_name, sql_text_string, DBMS_SQL.NATIVE);

ret := DBMS_SQL.EXECUTE(cursor_name);

LOOP                                        
  ret := DBMS_SQL.FETCH_ROWS(cursor_name);
  EXIT WHEN ret = 0;
  i_total_fetches := i_total_fetches + 1;
END LOOP;

DBMS_SQL.CLOSE_CURSOR(cursor_name);

-------------Now get the SQL_ID and SQL_EXEC_ID for the statement --------------------

  begin
    select  prev_sql_id, prev_child_number ,prev_exec_id into s_SQL_ID, i_CHILD_NO, i_SQL_EXEC_ID
    from v$session
    where sid = dbms_debug_jdwp.current_session_id and serial#  = dbms_debug_jdwp.current_session_serial ;
  EXCEPTION
    when NO_DATA_FOUND THEN
      dbms_output.put_line( 'Problems finding the SQL_ID  - ' || SQLERRM);
  end;
  
  i_elapsed_time := (dbms_utility.get_time() - i_timestart)/100;


------- display the execution plan ----------------------------------------------------


   myReport := dbms_sqltune.report_sql_monitor( sql_id => s_SQL_ID, sql_exec_id => i_SQL_EXEC_ID, type => 'TEXT', report_level => 'TYPICAL +ACTIVITY +ACTIVITY_HISTOGRAM +PLAN_HISTOGRAM');

  
  dbms_output.put_line( myReport );

------------- Output the stats, adjusting for the existing values in v$mystat and getting the parallel process SIDs from gv$sql_monitor -------------------------

for stats_cursor in (
                  select /*+ PUSH_PRED(SS) */ sn.name, sum(value) as value
                  from gv$sesstat ss
                  inner join v$statname sn on sn.statistic# = ss.statistic#
                  inner join  gv$sql_monitor sm on sm.inst_id = ss.inst_id and sm.sid = ss.sid  and sm.sql_id =  s_SQL_ID and sm.sql_exec_id = i_SQL_EXEC_ID 
                  and value != 0
                  group by sn.name
                  order by sn.name
                )
  loop
  adjusted_value := stats_cursor.value -  StatArray(stats_cursor.name);
  if ( adjusted_value != 0) then
  dbms_output.put_line( rpad(stats_cursor.name, 60) || ' : ' || lpad(to_char(adjusted_value,'999,999,999,999,999'),35)  );
  end if;
  end loop;

  DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Back to basics report : ' || chr(10));

  for stats_cursor in (
                  select /*+ PUSH_PRED(SS) */ sn.name, sum(value) as value
                  from gv$sesstat ss
                  inner join v$statname sn on sn.statistic# = ss.statistic#
                  inner join  gv$sql_monitor sm on sm.inst_id = ss.inst_id and sm.sid = ss.sid  and sm.sql_id =  s_SQL_ID and sm.sql_exec_id = i_SQL_EXEC_ID 
              --    and value != 0
                 and sn.name in ('cell physical IO bytes saved by storage index','session logical reads', 
                      'consistent gets',
                      'physical reads' ,
                      'session uga memory',
                      'session pga memory',
                      'CPU used by this session',
                      'redo size', 
                      'temp space allocated (bytes)',
                      'parse time elapsed' ,
                      'bytes sent via SQL*Net to client',
                      'bytes received via SQL*Net from client')     
                  group by sn.name
                )
  loop
  adjusted_value := stats_cursor.value -  StatArray(stats_cursor.name);

  dbms_output.put_line( rpad(stats_cursor.name, 40) || ' : ' || lpad(to_char(adjusted_value,'999,999,999,999,999'),35)  );

  end loop;
------------------------------- some output ---------------------------------------------------------
  DBMS_OUTPUT.PUT_LINE( chr(10) || 'Fetched : ' || i_total_fetches || ' rows in '|| i_elapsed_time || ' secs.' || chr(10) );
  DBMS_OUTPUT.PUT_LINE(chr(13) ||'SQL_ID=' || s_SQL_ID );
  DBMS_OUTPUT.PUT_LINE('SQL_EXEC_ID=' || i_SQL_EXEC_ID );
  DBMS_OUTPUT.PUT_LINE('SQL_CHILD_NO=' || i_CHILD_NO);
----------------------------------------------------------------------------------------



END;
/




@tab_partitions MVDS POSTING_WF


------------ fixing a segment-----------------------------------------------------



SELECT /*+ PARALLEL(4) */  COUNT(*)
FROM POSTING_WF partition(WORKFLOW1161)
WHERE partition_id = '1161'
and location = 'LDNBR';

@sess/session_sql2 %

create table WORKFLOW1161 as select *
FROM POSTING_WF partition(WORKFLOW1161);

rename pjs_temp to WORKFLOW1161;

alter table posting_wf TRUNCATE  PARTITION WORKFLOW1161;

ALTER SESSION ENABLE PARALLEL DML;
insert /*+ PARALLEL(16) */ into posting_wf partition( WORKFLOW1161 )
select *
from WORKFLOW1161 order by location;

WHERE partition_id = '1161'
and location = 'LDNBR';

@sess/session %



-------------------------------------------------------------------------
-- create indexes

@indexes MVDS ICDLRD

  CREATE UNIQUE INDEX  PK_GCR_CORE_WF ON GRS_RECORD_WF ("PARTITION_ID", "SUB_PARTITION_ID", "GCR_CORE_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 
  TABLESPACE MERIVAL_DATA_LIVE  LOCAL;


CREATE UNIQUE INDEX PK_ICDCAP_WF ON icdcap_WF (WORKFLOW_ID, ID, PARTITION_ID,SUB_PARTITION_ID) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 
  TABLESPACE "MERIVAL_DATA_LIVE"  LOCAL;

CREATE UNIQUE INDEX PK_ICDLRD_WF ON ICDLRD_WF (WORKFLOW_ID, ID, PARTITION_ID,SUB_PARTITION_ID) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 
  TABLESPACE "MERIVAL_DATA_LIVE"  LOCAL;


-- gather index stats :

begin
  dbms_stats.gather_index_stats( ownname => USER, indname => 'PK_GCR_CORE', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL AND PARTITION' );
end;
/



begin
  dbms_stats.gather_index_stats( ownname => USER, indname => 'PK_ICDCAP', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL AND PARTITION' );
end;
/
begin
  dbms_stats.gather_index_stats( ownname => USER, indname => 'PK_ICDLRD', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL AND PARTITION' );
end;
/

------------------------
begin
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'GRS_RECORD_WF', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'PARTITION' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'ICD_WF', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'PARTITION' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'ICDLRD_WF', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'PARTITION' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'ICDCAP_WF', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'PARTITION' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'POSTING_WF', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'PARTITION' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'REPORTING_CONTROL', 
                    DEGREE => 24, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL' );
end;
/

-------- global stats ------------------


begin
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'GRS_RECORD', 
                    DEGREE => 24, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'ICD', 
                    DEGREE => 24, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'ICDLRD', 
                    DEGREE => 24, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'ICDCAP', 
                    DEGREE => 24, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'POSTING', 
                    DEGREE => 24, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL' );
  dbms_stats.gather_table_stats( ownname => USER, tabname => 'REPORTING_CONTROL', 
                    DEGREE => 24, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL' );
end;
/


begin
  dbms_stats.gather_schema_stats( ownname => 'SHARED_REFDATA', 
                    DEGREE => 24, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'ALL' );

BEGIN
  dbms_stats.gather_schema_stats( ownname => 'APP_BO_STAGE', 
                    DEGREE => 24, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'ALL' );
END;
/



begin
  dbms_stats.gather_index_stats( ownname => USER, indname => 'PK_ICDCAP', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL AND PARTITION' );
end;
/
begin
  dbms_stats.gather_index_stats( ownname => USER, indname => 'PK_ICDLRD', 
                    DEGREE => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL AND PARTITION' );
end;
/



-- adding grants


define USER=APP_BO_ONSHORE_NEW
define USER=APP_BO_PERF_TEST
define USER=APP_BO_LCR_STAGE
define USER=APP_BO_ONSHORE

grant select  on POSTING_WF to &USER;
grant select  on GRS_RECORD_WF TO &USER;
grant select  on ICD_WF to &USER;
grant select  on ICDCAP_WF to &USER;
grant select  on ICDLRD_WF to &USER;


@users APP_BO%

  
