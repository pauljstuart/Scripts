

COLUMN sql_text FORMAT A40
COLUMN avg_elapsed_time_ms FORMAT 999,999,999,999.9;
COLUMN avg_fetches FORMAT 999999
COLUMN avg_parse_calls FORMAT 999,999;
COLUMN avg_disk_reads FORMAT 999,999;
COLUMN avg_buffer_gets FORMAT 999,999;
COLUMN first_load_time FORMAT A30;

alter session set NLS_DATE_FORMAT = 'YYYY-MM-DD/HH24:MI';

SELECT  inst_id,
        parsing_schema_name,
        sql_id,
        is_bind_sensitive,
        is_bind_aware,
        object_status,
        first_load_time,
        last_active_time,
        loads,
        invalidations,   
        executions,
        plan_hash_value,
        version_count,
        kept_versions ,
        optimizer_mode,
        optimizer_cost,
        sql_plan_baseline,
        trunc( (elapsed_time*1000)/executions, 1 ) avg_elapsed_time_ms,
        trunc( fetches/executions, 1)              avg_fetches,
        trunc( parse_calls/executions, 1)          avg_parse_calls,
        trunc( disk_reads/executions, 1)           avg_disk_reads,
        trunc( buffer_gets/executions, 1)          avg_buffer_gets
--        decode( executions,  0,0, (elapsed_time*1000)/executions) avg elapsed_time_ms,
--        decode( executions,  0,0,  fetches/executions) avg fetches,
--        decode( executions,  0,0, parse_calls/executions) avg parse_calls,
--        decode( executions,  0,0, disk_reads/executions) avg disk_reads,
--        decode( executions,  0,0, buffer_gets/executions) avg buffer_gets,
FROM gv$sqlarea
WHERE  
        sql_id = '&1'
order by  inst_id, first_load_time asc;

--select sql_id, users_executing, sql_text,elapsed_time/1000 "elapse time (ms)",cpu_time/1000 "cpu (ms)", concurrency_wait_time/1000, cluster_wait_time/1000, user_io_wait_time/1000
--from v$sqlarea
--where rownum < 100
--order by 5 desc;


