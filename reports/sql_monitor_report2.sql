

-- getting SQL monitor


SELECT   PREV_SQL_ID, PREV_EXEC_ID, PREV_CHILD_NUMBER  
FROM v$session V
WHERE SID =  (SELECT dbms_debug_jdwp.current_session_id from dual )
AND serial# = (select dbms_debug_jdwp.current_session_serial from dual) ;
    
 
 
set linesize  32767
set long 1000000

    
define SQL_ID=bcw169692mznh
define SQL_EXEC_ID=50331648 

select 
DBMS_SQLTUNE.report_sql_monitor( sql_id => '&SQL_ID', sql_exec_id => &SQL_EXEC_ID, type   => 'TEXT', report_level => 'TYPICAL +ACTIVITY +ACTIVITY_HISTOGRAM +PLAN_HISTOGRAM') 
from dual;












COLUMN operation   FORMAT A45 TRUNCATE
COLUMN OID         FORMAT 999
COLUMN ID          FORMAT 999
column PID         FORMAT 999
COLUMN object      FORMAT A30
COLUMN rows_actual FORMAT 999,999,999;
COLUMN rows_est    FORMAT 999,999,999;
COLUMN execs       FORMAT 999,999,999;
COLUMN etime_sec  FORMAT 999,999,999,999
COLUMN pstart     FORMAT A10 TRUNCATE
COLUMN pstop      FORMAT A10 TRUNCATE
COLUMN cpu_cost   FORMAT 9.99EEEE
COLUMN io_cost    FORMAT 999,999,999,999
COLUMN temp       FORMAT 999,999,999,999


prompt
prompt SQL monitor report for &SQL_ID and &SQL_EXEC_ID
prompt





SELECT  '|' as "|", 
        plan_object_name object,     '|' as "|",
        starts execs,               '|' as "|",
        plan_cardinality rows_est,  '|' as "|",
        output_rows rows_actual,    '|' as "|",
        plan_time etime_sec,    '|' as "|",
        plan_partition_start pstart,    '|' as "|",
        plan_partition_stop pstop,    '|' as "|",
        physical_read_requests phy_reads,               '|' as "|",
        plan_cpu_cost CPU_cost,               '|' as "|",
        plan_io_cost  IO_cost,               '|' as "|",
        plan_temp_space TEMP,             '|' as "|"
FROM  gv$sql_plan_monitor WHERE  sql_id = '&SQL_ID' AND sql_exec_id = &SQL_EXEC_ID ;

/*

prompt -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


with sql_plan_data as (
        select  plan_line_id, plan_parent_id
        from    gv$sql_plan_monitor
        where   sql_id = '&SQL_ID'
        and     sql_exec_id = &SQL_EXEC_ID
        )
,    hierarchy_data as (
        select  plan_line_id, plan_parent_id
        from    sql_plan_data
        start   with plan_line_id = 0
        connect by prior plan_line_id = plan_parent_id
        order   siblings by plan_line_id desc
        )
,    ordered_hierarchy_data as (
        select plan_line_id
        ,      plan_parent_id as pid
        ,      row_number() over (order by rownum desc) as oid
        ,      max(plan_line_id) over () as maxid
        from   hierarchy_data
        )
,    ALL_MON as (    
        SELECT *   FROM gv$sql_plan_monitor WHERE  sql_id = '&SQL_ID' AND sql_exec_id = &SQL_EXEC_ID 
       )
SELECT  '|' as "|", 
        ordered_hierarchy_data.oid , '|' as "|" ,
        ALL_MON.plan_line_id Id,  '|' as "|", 
        ALL_MON.plan_parent_id Pid, '|' as "|",
        substr( '....+....+....+....+....+....+....+....+....+....+....+', 1,  plan_depth) || plan_operation || ' ' || Plan_options as operation,  '|' as "|",
        plan_object_name object,     '|' as "|",
        starts execs,               '|' as "|",
        plan_cardinality rows_est,  '|' as "|",
        output_rows rows_actual,    '|' as "|",
        plan_time etime_sec,    '|' as "|",
        plan_partition_start pstart,    '|' as "|",
        plan_partition_stop pstop,    '|' as "|",
        physical_read_requests phy_reads,               '|' as "|",
        plan_cpu_cost CPU_cost,               '|' as "|",
        plan_io_cost  IO_cost,               '|' as "|",
        plan_temp_space TEMP,             '|' as "|"
FROM ALL_MON, ordered_hierarchy_data
WHERE ALL_MON.plan_line_id = ordered_hierarchy_data.plan_line_id
START WITH ALL_MON.plan_line_id = 0
CONNECT by PRIOR ALL_MON.plan_line_id = ALL_MON.plan_parent_id 
ORDER BY ALL_MON.plan_line_id ;

prompt -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

*/
