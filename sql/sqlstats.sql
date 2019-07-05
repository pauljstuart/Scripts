
COLUMN execs FORMAT 999,999,999
COLUMN avg_etime_sec FORMAT 999,999.999
COLUMN avg_lio FORMAT 999,999,999,999
COLUMN avg_rows_processed FORMAT 999,999,999,999
COLUMN avg_buffer_gets FORMAT 999,999,999,999
COLUMN avg_io_saved_pct  FORMAT  999,999.9
COLUMN avg_px_servers FORMAT 999
COLUMN io_saved_pct format 9999.9
COLUMN cell_offload FORMAT a15
COLUMN avg_phys_reads_mb FORMAT 999,999,999,999.9
COLUMN avg_phys_writes_mb FORMAT 999,999,999,999.9
COLUMN avg_io_offload_elig_mb FORMAT 999,999,999,999.9
COLUMN avg_io_interconnect_mb FORMAT 999,999,999,999.9
COLUMN avg_total_phys_mb FORMAT 999,999,999,999.9
COLUMN avg_elapsed_time_sec FORMAT 999,999,999,999.9
column plan_hash_value format 999999999999
column parsing_schema_name format A15
column fetches format 999,999,999
column invalidations format 999,999,999
column executions format 999,999,999
column parse_calls format 999,999,999
coluMN last_active_time format A21

define SQL_ID1=&1

prompt 
prompt  stats for  &SQL_ID1 from gv$sqlstats_plan_hash
prompt


select sql_id,
      plan_hash_value,
      executions,
      parse_calls,
     LAST_ACTIVE_TIME,  
     FETCHES,
    INVALIDATIONS, 
    elapsed_time/1000000/greatest(executions, 1) avg_elapsed_time_sec,
    rows_processed/greatest(executions, 1) avg_rows_processed,
    buffer_gets/greatest(executions, 1) avg_buffer_gets,
   PX_SERVERS_EXECUTIONS/greatest(executions, 1) avg_px_servers,
   IO_CELL_OFFLOAD_ELIGIBLE_BYTES/greatest(executions, 1)/(1024*1024) avg_io_offload_elig_mb,
   IO_INTERCONNECT_BYTES/greatest(executions, 1)/(1024*1024) avg_io_interconnect_mb,
    (PHYSICAL_write_BYTES+PHYSICAL_READ_BYTES)/greatest(executions, 1)/(1024*1024) avg_total_phys_mb,
   PHYSICAL_READ_BYTES/greatest(executions, 1)/(1024*1024) avg_phys_reads_mb,
   PHYSICAL_WRITE_BYTES/greatest(executions, 1)/(1024*1024) avg_phys_writes_mb,
     decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES,0,'No','Yes') cell_offload,
    (  IO_CELL_OFFLOAD_ELIGIBLE_BYTES -  IO_INTERCONNECT_BYTES)*100/decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES,0,null,IO_CELL_OFFLOAD_ELIGIBLE_BYTES)   avg_io_saved_pct
from gv$sqlstats_plan_hash 
where  sql_id in &SQL_ID1;



