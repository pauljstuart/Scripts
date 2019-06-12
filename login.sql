
prompt Logging in.


set wrap off
set verify off
set serveroutput off
set linesize 5000
set pagesize 5000
set trimout on
set trimspool on
set echo off
set feedback on

column temporary format A10
column instance_number format 999
column inst_id format 999
column owner format A15
column segment_name format A30
column table_name format A30
column partition_name format A20
column subpartition_name format A20
column index_name format A20
COLUMN column_name FORMAT a30
COLUMN index_name FORMAT a30
COLUMN tablespace_name FORMAT a20
column object_name FORMAT A30
COLUMN last_analyzed format A20
column partition_position format 999,999,999
column count(*) format 999,999,999,999
COLUMN NUM_ROWS FORMAT 999,999,999,999
COLUMN NUM_NULLS FORMAT 999,999,999,999
COLUMN NUM_DISTINCT FORMAT 999,999,999,999
COLUMN density FORMAT 999999.999999;
column role format a20
column grantee format A20
column privilege format a20;
COLUMN NO_INVALIDATE FORMAT A30
COLUMN DISTINCT_KEYS FORMAT 999,999,999,999,999
column AVG_LEAF_BLOCKS_PER_KEY format 999,999,999
column AVG_DATA_BLOCKS_PER_KEY format 999,999,999
column interval format A30
COLUMN BLOCKS FORMAT 999,999,999,999,999
column size_mb format 999,999,999,999
column size_gb format 999,999,999,999

COLUMN etime_secs format 999,999,999
COLUMN etime_mins format 999,999.9
COLUMN sid FORMAT 9999
COLUMN "serial#" FORMAT 99999
COLUMN username FORMAT A20
COLUMN sql_opname FORMAT A10
COLUMN sql_id FORMAT A13
column sql_start_time format A20
column sql_end_time format A20
COLUMN sql_exec_id format 999999999
column SQL_EXEC_START format A21
column module      format A30
column sql_plan_hash_value format 9999999999
column plan_hash_value format 9999999999
COLUMN IN_HARD_PARSE FORMAT A14
COLUMN Degree FORMAT 999,999 
COLUMN BLVL FORMAT 99
COLUMN status FORMAT A30
COLUMN density FORMAT 9.9999
column stale_stats format A10
column global_stats format a10
column avg_col_len format 999,999
column user_stats format A10
column num_buckets format 999,999
column partitioned format A10
column empty_blocks format 999,999,999
column avg_row_len format 999,999,999,999
column clustering_factor format 999,999,999,999
column partitioned format A11
column segment_created format A15
column created format A15
COLUMN r_owner FORMAT A20;
COLUMN itran FORMAT 99999;
COLUMN mtran FORMAT 99999;
column partition_position format 999,999
column subpartition_position format 999,999
column subpartition_count format 999,999
COLUMN data_type FORMAT A30
column constraint_source format A60
column references_column format A60
column data_default format A15
column data_type format A10
COLUMN TRIGGERING_EVENT FORMAT a30
COLUMN LAST_DDL_TIME FORMAT a21
column search_condition format A25
column constraint_type format A5

column username format a18
column osuser format a15
column program format a28 truncate
column sid format 9999
column terminal format A12
column SPID format A6 justify right
column client_info format A50
column service_name format A30 truncate
column host format A30
column BLOCKING_INSTANCE format 999
column BLOCKING_SESSION  format 99999
column signature format 999999999999999999999
column exact_matching_signature format 999999999999999999999
column sql_profile format A30
column sql_plan_baseline format A20
COLUMN child_number FORMAT 999 
COLUMN sql_child_number FORMAT 999 
COLUMN category FORMAT a15
COLUMN sql_text FORMAT a200 truncate
column count(*) format 999,999,999,999,999

-- common to all ash scripts :

COLUMN phys_total_mb format   999,999,999,999
column phys_read_mb format    999,999,999,999
column phys_write_mb format   999,999,999,999
column interconnect_mb format 999,999,999,999
COLUMN max_temp_mb format     999,999,999,999
COLUMN max_pga_mb format      999,999,999,999
column etime_mins format 999,999.9
column etime_secs format 999,999,999

column px_start_time format A20
column px_end_time format A20
column px_interconnect_mb format 999,999,999,999
column px_phys_total_mb format 999,999,999,999
column px_phys_read_mb format 999,999,999,999
column px_phys_write_mb format 999,999,999,999
column px_temp_mb format 999,999,999,999
column px_pga_mb format  999,999,999,999
column parallel_deg format 999
COLUMN PX_ETIME_MINS FORMAT 999,999.9
COLUMN PX_ETIME_SECS FORMAT 999,999
column PX_READ_IO_REQUESTS   format 999,999,999,999                 
column PX_WRITE_IO_REQUESTS format 999,999,999,999
column parallel_instances format A20


define DAYS_AGO=7

define gname=idle

COLUMN global_name NEW_VALUE gname noprint;
SELECT substr( global_name, 1, decode( dot, 0, length(global_name), dot-1) ) || '-' || (select lower(to_CHAR( SYSDATE, 'DY-DDMONYY')) from dual)  global_name
FROM (SELECT global_name, instr(global_name, '.') dot from global_name );

whenever sqlerror EXIT

prompt
prompt setting worksheet name to &gname
prompt

set worksheetname &gname

column created format A20

alter session set nls_timestamp_format='DY DD-MM-YYYY HH24:MI.SS';
alter session set nls_date_format='DY DD-MM-YYYY HH24:MI';


SELECT dbms_debug_jdwp.current_session_id sid,
       dbms_debug_jdwp.current_session_serial serial#,
       (select instance_number from v$instance) instance_num,
       (select instance_name from v$instance) instance_name,
       (select host_name from v$instance) hostname
FROM dual;


select username, user_id, default_tablespace, temporary_tablespace from user_users;








