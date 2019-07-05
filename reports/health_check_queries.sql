
column temp_used_gb format 999,999
column service_name format A20

prompt
prompt the SQL temp usage query :
prompt

with pivot1 as
(
select S1.inst_id,
      S1.username, 
      sid,
      serial#,
      S1.sql_id, 
      sql_exec_id,
      sql_exec_start , 
     program,
      terminal,    
      module,
      service_name,
    blocks*(select value from v$parameter where name = 'db_block_size')/(1024*1024*1024) temp_gb
from gv$session S1
left outer join gv$tempseg_usage TSU on TSU.inst_id = S1.inst_id and TSU.session_num = S1.serial#
WHERE  S1.sql_id is not null AND  S1.SQL_EXEC_ID IS NOT NULL
and status = 'ACTIVE'
and type = 'USER'
order by S1.sql_id
)
select username, sql_id, sql_exec_id, sql_exec_start,  (trunc(sysdate, 'MI') - trunc(SQL_EXEC_START, 'MI')) * 60*24 etime_mins , terminal, module, service_name , sum(temp_gb) temp_used_gb
from pivot1
group by username, sql_id, sql_exec_id, sql_exec_start, terminal, module, service_name
having sum(temp_gb) > 20
order by sum(temp_gb)  desc;


prompt
prompt the SQL duration query :
prompt

-- SQL elapsed time check 
SELECT 
  username,
  osuser,
  inst_id,
  Sid,
  serial#,
  sql_id,
  DECODE(command, 1,'CRE TAB', 2,'INSERT', 3,'SELECT', 6,'UPDATE', 7,'DELETE', 9,'CRE INDEX', 12,'DROP TABLE', 15,'ALT TABLE',39,'CRE TBLSPC', 42, 'DDL', 44,'COMMIT', 45,'ROLLBACK', 47,'PL/SQL EXEC', 48,'SET XACTN', 62, 'ANALYZE TAB', 63,'ANALYZE IX', 71,'CREATE MLOG', 74,'CREATE SNAP',79, 'ALTER ROLE', 85,'TRUNC TAB' ) COMMAND,
  TO_CHAR(sql_exec_start,'DY YYYY-MM-DD HH24:MI') AS sql_exec_start,
  module,
  to_char( (sysdate - SQL_EXEC_START) * 60*24, '999,999') etime_mins
FROM
  gv$session S1
WHERE  S1.sql_id  IS NOT NULL
AND    S1.SQL_EXEC_ID  IS NOT NULL
AND    status     = 'ACTIVE'
AND    type       = 'USER'
and not regexp_like( program, '\(P[0-9]+\)')
and command != 47
AND    TRUNC( (sysdate - SQL_EXEC_START) * 60*24) > 600
order by 10 desc


prompt
prompt max concurrent BO reports
prompt

select count(*) as concurrent_bo_reports
from
(
select distinct sql_id, sql_exec_id, sql_exec_start
from gv$session 
where     SCHEMANAME IN (  'APP_BO_ONSHORE','APP_BO')
and status = 'ACTIVE'
AND SQL_ID IS NOT NULL AND SQL_EXEC_ID IS NOT NULL
) ;

prompt
prompt temp tablespace % usage :
prompt


column total_max_gb format 999,999,999
column total_used_gb format 999,999,999

WITH pivot1 AS
(
select value/(1024*1024*1024) as block_size_gb from v$parameter where name = 'db_block_size' 
),
u as
(
SELECT TABLESPACE, SUM(blocks) tot_used_blocks
  FROM gv$tempseg_usage
  GROUP BY TABLESPACE
),
f as
(
SELECT tablespace_name,
    SUM(DECODE(autoextensible, 'YES', maxblocks, blocks)) total_blocks
  FROM dba_temp_files
  GROUP BY tablespace_name
)
SELECT f.tablespace_name, 
       f.total_blocks*(select block_size_gb from pivot1) total_max_gb, 
       u.tot_used_blocks*(select block_size_gb from pivot1) total_used_gb, 
       trunc((u.tot_used_blocks/f.total_blocks)*100) pct_used
FROM f
left outer join u on f.tablespace_name = u.tablespace
where trunc((u.tot_used_blocks/f.total_blocks)*100) > 30;


prompt
prompt Physical IO per SQL :
prompt

column phys_total_gb format 999,999,999
-- SQL physical IO check 
WITH
  pivot1 AS
  (
    SELECT DISTINCT
      sql_id,
      sql_exec_id,
      sql_exec_start,
      osuser,
      username,
      module
    FROM
      gv$session S1
    WHERE
      S1.sql_id        IS NOT NULL
    AND S1.SQL_EXEC_ID IS NOT NULL
    AND status          = 'ACTIVE'
    AND type            = 'USER'
  )
SELECT
  P1.username,
  P1.osuser,
  P1.sql_id,
  P1.sql_exec_id,
  TO_CHAR(P1.sql_exec_start,'DY YYYY-MM-DD HH24:MI') AS sql_exec_start,
  P1.module ,
   to_char(TRUNC(SUM(NVL(delta_write_io_bytes, 0) + NVL(delta_read_io_bytes, 0))/(1024*1024*1024) ), '999,999,999,999') phys_total_gb
FROM  
  pivot1 P1
  INNER JOIN  dba_hist_active_sess_history AWR
  ON  
      P1.sql_id           = AWR.sql_id
    AND P1.sql_exec_id    = AWR.sql_exec_id
    AND P1.sql_exec_start = AWR.sql_exec_start
WHERE
  snap_id > (SELECT  MIN(snap_id) FROM dba_hist_snapshot  WHERE begin_interval_time > TRUNC(sysdate - 2, 'DD') )
GROUP BY
  P1.username,
  P1.osuser, 
  P1.sql_id,
  P1.sql_exec_id,
  P1.sql_exec_start,
  P1.module
HAVING
  SUM(NVL(delta_write_io_bytes, 0) + NVL(delta_read_io_bytes, 0))/(1024*1024*1024) > 1000
ORDER BY
  7 DESC

