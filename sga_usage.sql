


prompt
prompt Parameter settings :
prompt

column 1_value format A20
column 2_value format A20
column 3_value format A20
column 4_value format A20
column name format A30

with pivot1 as
(
select inst_id, name, value
from gv$parameter
where name in (
'session_cached_cursors',
'open_cursors',
'processes',
'sessions',
'db_files',
'shared_server',
'cursor_sharing',
'query_rewrite_enabled',
'result_cache_mode',
'statistics_level',
'db_cache_advice',
'compatible',
'result_cache_size',
'memory_target',
 'memory_max_target',
'sga_target',
'memory_target',
'memory_max_target',
'sga_max_size',
'java_pool_size',
'large_pool_size',
'streams_pool_size',
'log_buffer',
'shared_pool_size',
'shared_pool_reserved_size',
'pga_aggregate_target')

)
select * from pivot1 
pivot
( 
 max( value ) as value
  for inst_id in (1,2,3,4)
) ;


prompt
prompt sga_info :
prompt

SELECT inst_id,name,bytes/1024/1024 as size_mb 
FROM gv$sgainfo
where name in ('Maximum SGA Size', 'Free SGA Memory Available', 'Shared Pool Size', 'Buffer Cache Size', 'Redo Buffers', 'In-Memory Area Size')
union
select inst_id,'Shared pool free memory', bytes/1024/1024 as size_mb 
from gv$sgastat
where pool = 'shared pool' and name = 'free memory'
order by inst_id;


prompt
prompt sga_dynamic_components :
prompt

COLUMN current_size format 999,999,999,999;
COLUMN min_size format 999,999,999,999;
COLUMN max_size format 999,999,999,999;
column setting format 999,999,999,999
COLUMN user_specified_size format 999,999,999,999;
COLUMN component format A40

SELECT * FROM gV$SGA_DYNAMIC_COMPONENTS
--WHERE component = 'DEFAULT buffer cache'
ORDER BY inst_id;


prompt
prompt Resource Limit :
prompt


col resource_name format a25 head "Resource"
col current_utilization format 999,999,999,999 head "Current"
col max_utilization format 999,999,999,999 head "HWM"
col intl  head Setting format 999,999,999

select inst_id,  resource_name, current_utilization, max_utilization, initial_allocation intl
from gv$resource_limit
where resource_name in ('processes', 'sessions','enqueue_locks','enqueue_resources',
   'ges_procs','ges_ress','ges_locks','ges_cache_ress','ges_reg_msgs',
   'ges_big_msgs','ges_rsv_msgs','gcs_resources','dml_locks','max_shared_servers')
/




