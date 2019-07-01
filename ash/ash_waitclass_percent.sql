COLUMN  CLUSTER_PCT FORMAT 99.9
COLUMN SYSTEM_IO_PCT FORMAT 99.9
COLUMN USER_IO_PCT FORMAT 99.9
COLUMN NETWORK_PCT FORMAT 99.9
COLUMN COMMIT_PCT FORMAT 99.9
COLUMN OTHER_PCT FORMAT 99.9
COLUMN APPLICATION_PCT FORMAT 99.9
COLUMN CONCURRENCY_PCT FORMAT 99.9
COLUMN CPU_PCT FORMAT 99.9
COLUMN AAS FORMAT 999,999


prompt 
prompt Wait class percent for the database :
prompt

with sub1 AS (

select  INST_ID,
       TRUNC(sample_time, 'MI') as sample_min, 
      case wait_class when 'Cluster'  then 1 else 0 end as CLUSTER_CLASS,
      case wait_class when 'System I/O'  then 1 else 0 end as SYSTEM_IO_CLASS,
      case wait_class when 'User I/O'  then 1 else 0 end as USER_IO_CLASS,
      case wait_class when 'Network'  then 1 else 0 end as NETWORK_CLASS,
      case wait_class when 'Commit'  then 1 else 0 end as COMMIT_CLASS,
      case wait_class when 'Other'  then 1 else 0 end as OTHER_CLASS,
      case wait_class when 'Application'  then 1 else 0 end as APPLICATION_CLASS,
      case wait_class when 'Concurrency'  then 1 else 0 end as CONCURRENCY_CLASS,
       case session_state when 'ON CPU'  then 1 else 0 end as CPU_CLASS
from
        GV$ACTIVE_SESSION_HISTORY
)
select sub1.sample_MIN,
      sum(sub1.CLUSTER_CLASS)*100/COUNT(*) as CLUSTER_PCT,
     sum(sub1.SYSTEM_IO_CLASS)*100/COUNT(*) as SYSTEM_IO_PCT,
     sum(sub1.USER_IO_CLASS)*100/COUNT(*) as USER_IO_PCT,
     sum(sub1.NETWORK_CLASS)*100/COUNT(*) as NETWORK_PCT,
     sum(sub1.COMMIT_CLASS)*100/COUNT(*) as COMMIT_PCT,
     sum(sub1.OTHER_CLASS)*100/COUNT(*) as OTHER_PCT,
     sum(sub1.APPLICATION_CLASS)*100/COUNT(*) as APPLICATION_PCT,
     sum(sub1.CONCURRENCY_CLASS)*100/COUNT(*) as CONCURRENCY_PCT,
     sum(sub1.CPU_CLASS)*100/COUNT(*) as CPU_PCT,
     COUNT(*)/60 AAS
FROM sub1
group by  sub1.sample_MIN 




prompt 
prompt wait class percent per instance 
prompt



with sub1 AS (

select  INST_ID,
       TRUNC(sample_time, 'MI') as sample_min, 
      case wait_class when 'Cluster'  then 1 else 0 end as CLUSTER_CLASS,
      case wait_class when 'System I/O'  then 1 else 0 end as SYSTEM_IO_CLASS,
      case wait_class when 'User I/O'  then 1 else 0 end as USER_IO_CLASS,
      case wait_class when 'Network'  then 1 else 0 end as NETWORK_CLASS,
      case wait_class when 'Commit'  then 1 else 0 end as COMMIT_CLASS,
      case wait_class when 'Other'  then 1 else 0 end as OTHER_CLASS,
      case wait_class when 'Application'  then 1 else 0 end as APPLICATION_CLASS,
      case wait_class when 'Concurrency'  then 1 else 0 end as CONCURRENCY_CLASS,
       case session_state when 'ON CPU'  then 1 else 0 end as CPU_CLASS
from
        GV$ACTIVE_SESSION_HISTORY
)
select inst_id, 
      sample_MIN,
      sum(CLUSTER_CLASS)*100/COUNT(*) as CLUSTER_PCT,
     sum(SYSTEM_IO_CLASS)*100/COUNT(*) as SYSTEM_IO_PCT,
     sum(USER_IO_CLASS)*100/COUNT(*) as USER_IO_PCT,
     sum(NETWORK_CLASS)*100/COUNT(*) as NETWORK_PCT,
     sum(COMMIT_CLASS)*100/COUNT(*) as COMMIT_PCT,
     sum(OTHER_CLASS)*100/COUNT(*) as OTHER_PCT,
     sum(APPLICATION_CLASS)*100/COUNT(*) as APPLICATION_PCT,
     sum(CONCURRENCY_CLASS)*100/COUNT(*) as CONCURRENCY_PCT,
     sum(CPU_CLASS)*100/COUNT(*) as CPU_PCT,
     COUNT(*)/60 AAS
FROM sub1
group by  inst_id, sample_MIN 
order by inst_id, sample_min;


prompt
prompt Wait class percent per SQL_ID
prompt

with seed_ash as
(
select  ASH.*,
     (CASE  WHEN wait_class  = 'Concurrency'   THEN 1     else 0 END) as concurrency_cnt,
     (CASE  WHEN wait_class  = 'System I/O '   THEN 1     else 0 END) as system_cnt,
     (CASE  WHEN wait_class  = 'User I/O'      THEN 1     else 0 END) as userio_cnt,
     (CASE  WHEN wait_class  = 'Other'         THEN 1     else 0 END) as other_cnt,
     (CASE  WHEN wait_class  = 'Configuration'   THEN 1     else 0 END) as config_cnt,
     (CASE  WHEN wait_class  = 'Application'   THEN 1     else 0 END) as app_cnt,
     (CASE  WHEN wait_class  = 'Network'       THEN 1     else 0 END) as network_cnt,
    (CASE  WHEN wait_class  = 'Commit'         THEN 1     else 0 END) as commit_cnt,
    (CASE  WHEN wait_class  = 'Idle'           THEN 1     else 0 END) as idle_cnt,
    (CASE  WHEN session_state = 'ON CPU' AND wait_class is null then 1 else 0 END) as cpu_cnt
from gv$active_session_history ASH
WHERE  
     ASH.session_type = 'FOREGROUND'
--AND ash.USER_ID = 71
--AND ASH.sql_opname = 'INSERT'
),
pivot2 as
(
SELECT   
     ASH.inst_id, 
     ASH.user_id, 
      ASH.session_id sid, 
      ASH.session_serial# serial#, 
      ASH.sql_opname,
      ASH.module,
      ASH.top_level_sql_id, 
      ASH.sql_id, 
      ASH.sql_exec_id,
      ASH.sql_exec_start,
      ASH.SQL_PLAN_HASH_VALUE,
      NVL(ASH.sql_exec_start, min(sample_time)) sql_start_time, 
             MAX(sample_time) sql_end_time, 
             (CAST(MAX(sample_time)  AS DATE) - CAST( NVL(ASH.sql_exec_start, min(sample_time)) AS DATE)) * 60*24 etime_mins ,
             sum(nvl(delta_write_io_bytes, 0) + nvl(delta_read_io_bytes, 0))/(select value from v$parameter where name = 'db_block_size')   phys_total_blocks,
             max(temp_space_allocated)/(1024*1024) max_temp_mb,
      sum(concurrency_cnt)*100/count(*) as concurrent_pct, 
      sum(system_cnt)*100/count(*) as system_pct, 
      sum(userio_cnt)*100/count(*) as userio_pct, 
      sum(other_cnt)*100/count(*) as other_pct, 
      sum(config_cnt)*100/count(*) as config_pct, 
      sum(app_cnt)*100/count(*) as app_pct, 
      sum(network_cnt)*100/count(*) as network_pct, 
      sum(commit_cnt)*100/count(*) as commit_pct, 
      sum(idle_cnt)*100/count(*) as idle_pct, 
      sum(cpu_cnt)*100/count(*) as cpu_pct,
      count(*) count_total
from seed_ash ASH
group by  ASH.inst_id, ASH.user_id, ASH.session_id, ASH.session_serial#, ASH.sql_opname, ASH.module, ASH.top_level_sql_id, ASH.sql_id,  ASH.sql_exec_id, ASH.sql_exec_start, ASH.SQL_PLAN_HASH_VALUE,  sql_exec_start
)
select * from pivot2
where count_total > 100
order by sql_start_time;
