

column stat_name format A20
column inst1 format 999,999,999.9
COLUMN DAILY_TOTAL FORMAT 999,999,999,999
column  db_block_changes  FORMAT 999,999,999,999
column session_logical_reads  FORMAT 999,999,999,999,999
column user_commits   FORMAT 999,999,999,999
column phys_read_io   FORMAT 999,999,999,999
column phys_write_io   FORMAT 999,999,999,999
column phys_read_mb   FORMAT 999,999,999,999
column phys_write_mb   FORMAT 999,999,999,999
column redo_mbytes format 999,999,999,999,999
column execute_count  FORMAT 999,999,999,999,999
column day format A14


WITH 
pivot1 as
(
select min(snap_id) AS begin_snap_id
from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
)
, PIVOT2 AS
(
SELECT snap_id, 
  instance_number,
  stat_name, 
 NVL ( DECODE ( GREATEST ( VALUE, NVL ( LAG ( VALUE) OVER (PARTITION BY dbid, instance_number, stat_name ORDER BY snap_id), 0)), VALUE, VALUE - LAG ( VALUE) OVER (PARTITION BY dbid, instance_number, stat_name ORDER BY snap_id), VALUE), 0) DELTA
FROM DBA_HIST_SYSSTAT DHS
where   DHS.snap_id > (select begin_snap_id from pivot1)
and  stat_name in ('user commits', 'db block changes', 'session logical reads', 'user commits', 'execute count', 'physical read bytes', 'physical write bytes', 'redo size', 'physical read IO requests', 'physical write IO requests')
),
pivot3 as
(
select trunc(AWR.begin_interval_time, 'DD') day, 
        case when stat_name = 'db block changes' then  sum(DELTA) else 0  end as sum1,
        case when stat_name = 'session logical reads' then  sum(DELTA) else 0  end as sum2,
        case when stat_name = 'user commits' then  sum(DELTA) else 0 end as sum3,
        case when stat_name = 'execute count' then  sum(DELTA) else 0 end as sum4,
        case when stat_name = 'physical read bytes' then  sum(DELTA) else 0 end as sum5, 
        case when stat_name = 'physical write bytes' then  sum(DELTA) else 0 end as sum6, 
        case when stat_name = 'redo size' then  sum(DELTA) else 0 end as sum7,
        case when stat_name in ('physical read IO requests')   then  sum(DELTA) else 0 end as sum8,
        case when stat_name in ('physical write IO requests')    then  sum(DELTA) else 0 end as sum9
from 
pivot2
inner join dba_hist_snapshot AWR on  AWR.snap_id = pivot2.snap_id
 group by trunc(AWR.begin_interval_time, 'DD'), stat_name
 order by stat_name,  trunc(AWR.begin_interval_time, 'DD')
)
select day , sum( sum1) as db_block_changes, sum(sum2) as session_logical_reads, sum(sum3) as user_commits, sum(sum4) as execute_count, sum(sum5)/(1024*1024) as phys_read_mb, sum(sum6)/(1024*1024) as phys_write_mb, sum(sum7)/(1024*1024) as redo_mbytes,
     sum(sum8)/(1024*1024) as phys_read_io, sum(sum9)/(1024*1024) as phys_write_io
from pivot3
group by day
order by day;
