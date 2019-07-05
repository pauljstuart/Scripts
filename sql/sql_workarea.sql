


column ESTIMATED_OPTIMAL_SIZE format 999,999,999,999
column ESTIMATED_ONEPASS_SIZE  format 999,999,999,999                      
column LAST_MEMORY_USED format 999,999,999,999     
column TOTAL_EXECUTIONS    format 999,999,999,999                  
column OPTIMAL_EXECUTIONS  format 999,999,999,999                    
column ONEPASS_EXECUTIONS  format 999,999,999,999                
column MULTIPASSES_EXECUTIONS format 999,999,999,999                     
column MAX_TEMPSEG_SIZE_MB  format 999,999,999,999                  
column LAST_TEMPSEG_SIZE_MB format 999,999,999,999

prompt
prompt v$sql_workarea :
prompt

SELECT inst_id, 
  operation_type OPERATION,
  estimated_optimal_size,
  estimated_onepass_size,
  last_memory_used,
  last_execution,
  TOTAL_EXECUTIONS,
  OPTIMAL_EXECUTIONS ,
  ONEPASS_EXECUTIONS ,
  MULTIPASSES_EXECUTIONS,
  max_TEMPSEG_SIZE/1024/1024 max_Tempseg_size_mb, 
  last_TEMPSEG_SIZE/1024/1024 last_Tempseg_size_mb
FROM gV$SQL_WORKAREA
where sql_id = '&1'
ORDER BY 1,2;


prompt
prompt v$sql_workarea_active
prompt

column temp_used_mb format 999,999,999
column total_temp_used_mb format 999,999,999
column tempseg_size_mb format 999,999,999
column workarea_size_mb format 999,999,999.9
column expected_size_mb format 999,999,999.9
column total_workarea_mb format 999,999,999
column actual_mem_used_mb format 999,999,999.9
column max_mem_used_mb format 999,999,999.9
column tablespace format A20

SELECT inst_id, 
   to_number(decode(SID, 65535, NULL, SID)) sid,
  operation_type OPERATION,
  EXPECTED_SIZE/1024/1024 ESIZE_mb,
  ACTUAL_MEM_USED/1024/1024   workarea_MEM_mb,
  MAX_MEM_USED/1024/1024 max_mem_mb,
  NUMBER_PASSES PASS,
  TEMPSEG_SIZE/1024/1024 Tempseg_size_mb, 
   tablespace, 
  sum( ACTUAL_MEM_USED/(1024*1024) ) over () total_workarea_mb
FROM gV$SQL_WORKAREA_ACTIVE
where  sql_id = '&1'
ORDER BY 1,2;


prompt
prompt joined to v$tempseg_usage :
prompt


WITH pivot1 AS
(
select value/(1024*1024) as block_size_mb from v$parameter where name = 'db_block_size' 
)
SELECT B.inst_id, 
   to_number(decode(B.SID, 65535, NULL, SID)) sid,
  operation_type OPERATION,
   B.SQL_ID, B.SQL_EXEC_ID, B.ACTIVE_TIME, b.WORK_AREA_SIZE/(1024*1024) workarea_size_mb, B.EXPECTED_SIZE/1024/1024 expected_size_mb, B.ACTUAL_MEM_USED/1024/1024 actual_mem_used_mb, 
   B.TEMPSEG_SIZE/1024/1024 Tempseg_size_mb, 
   B.tablespace, 
  sum( B.ACTUAL_MEM_USED/(1024*1024) ) over () total_workarea_mb,
  '|',
   C.username, C.sql_id, C.tablespace, C.segtype, C.blocks*(select block_size_mb from pivot1) temp_used_mb
FROM gV$SQL_WORKAREA_ACTIVE B
left outer join gv$tempseg_usage C ON b.inst_id = C.inst_id and  b.tablespace = C.tablespace and b.SEGRFNO# = C.SEGRFNO# and b.SEGBLK# = C.SEGBLK#
where B.sql_id = '&1'
ORDER BY 1,2;

