

@my_tables


begin
  dbms_stats.gather_table_stats( ownname => 'PERF_SUPPORT', tabname => 'MERIDIAN_TEMP3_SEG_USAGE', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 2, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    granularity => 'GLOBAL AND PARTITION' );
end;

drop table pjs_ash_7apr14


SELECT * FROM MVDS_TEMP_SEG_USAGE
where temp_tablespace = 'TEMP1'
order by date_time;



select date_time, max(sum_mb) from 
meridian_temp_seg_usage
group by date_time
order by date_time;






drop table MVDS_TEMP1_SEG_USAGE;

CREATE TABLE PERF_SUPPORT.MVDS_TEMP_SEG_USAGE
  (
    DATE_TIME DATE,
    USERNAME  VARCHAR2(30),
    inst_id   NUMBER,
    seg_type  VARCHAR2(9),
    sql_id    VARCHAR2(13),
    temp_tablespace  VARCHAR2(64),
    size_mb    NUMBER,
    sample_sum_mb     NUMBER,
    v_inst_id NUMBER,
    v_username  VARCHAR2(30),
    v_sid      NUMBER,
    v_serialnum  NUMBER,
    v_OS_USER   VARCHAR2(30),
    v_process  VARCHAR2(64),
    v_machine  VARCHAR2(64),
    v_sql_id   VARCHAR2(13),
    v_prev_sql_id VARCHAR2(13),
    v_module      VARCHAR2(64),
    v_client_info VARCHAR2(64),
      C_SQL_ID VARCHAR2(13) ,
      C_SQL_EXEC_ID  NUMBER ,
      C_ACTIVE_TIME  NUMBER ,
       C_WORK_AREA_SIZE_MB  NUMBER ,
      C_EXPECTED_SIZE_MB  NUMBER ,
       C_ACTUAL_MEM_USED_MB  NUMBER ,
      C_MAX_MEM_USED_MB  NUMBER ,
       C_PASSES  NUMBER,
   C_TEMP_SEG_MB  NUMBER 
  );







alter session set nls_timestamp_format='DD-MON-YYYY HH24:MI';
alter session set nls_date_format='DD-MON-YYYY HH24:MI';
alter session set NLS_TIMESTAMP_TZ_FORMAT="DD-MON-YYYY HH24:MI TZR";



begin

DBMS_SCHEDULER.DROP_JOB (   job_name     => 'MERIVAL_TEMP1_MONITORING' );
end;




begin

DBMS_SCHEDULER.CREATE_JOB (
   job_name             => 'MERIVAL_TEMP_MONITORING',
   job_type             => 'PLSQL_BLOCK',
   job_action           => 'BEGIN 
INSERT INTO PERF_SUPPORT.MVDS_TEMP_SEG_USAGE
SELECT sysdate,
  b.username,
  b.inst_id,
  b.segtype,
  b.sql_id,
  b.tablespace,
  b.blocks    *16384/1048576,
  SUM(b.blocks*16384/1048576) over (partition by b.tablespace) ,
  a.inst_id,
  a.username,
  a.sid,
  a.serial#,
  a.osuser,
  a.process,
  a.machine,
  a.sql_id,
  a.prev_sql_id,
  a.module,
  a.client_info,
  C.SQL_ID,
  C.SQL_EXEC_ID,
  C.ACTIVE_TIME,
  C.WORK_AREA_SIZE/1048576 workarea_size_mb,
  C.EXPECTED_SIZE/1048576 expected_size_mb,
  C.ACTUAL_MEM_USED/1048576 actual_mem_used_mb,
  C.MAX_MEM_USED/1048576 max_mem_used_mb,
  C.NUMBER_PASSES,
  C.TEMPSEG_SIZE/1048576 tempseg_mb
FROM gv$tempseg_usage b
INNER JOIN gv$session a
  ON b.inst_id = a.inst_id AND a.saddr  = b.session_addr
LEFT OUTER JOIN gv$sql_workarea_active C
  ON b.inst_id     = C.inst_id AND b.tablespace = C.tablespace AND b.SEGRFNO#   = C.SEGRFNO# AND b.SEGBLK#    = C.SEGBLK#;
COMMIT;
END;',
   start_date           => '23-MAR-2018 12:04 UTC',
   repeat_interval      => 'FREQ=MINUTELY', 
   end_date             => '25-APR-2018 14:15 UTC',
   enabled              =>  TRUE,
   auto_drop            =>  FALSE,
   comments             => 'Gathers additional info from v$tempseg_usage - Paul Stuart');
END;
/
