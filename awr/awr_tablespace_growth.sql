
-- daily tablespace usage, and daily difference


column ts_daily_max_gb format 999,999,999,999,999
column ts_daily_used_gb format 999,999,999,999,999
column daily_change_gb format 999,999,999,999,999
column ts_daily_free_gb format 999,999,999,999,999
column day format A15

with pivot1 as
(
select A.snap_id, 
        b.end_interval_time day,  
           sum(tablespace_usedsize)*(select value/(1024*1024*1024) as block_size_gb from v$parameter where name = 'db_block_size' ) ts_used_gb,
      sum(tablespace_maxsize)*(select value/(1024*1024*1024) as block_size_gb from v$parameter where name = 'db_block_size' ) ts_maxsize_gb
from dba_hist_tbspc_space_usage A
inner join dba_hist_snapshot B on A.snap_id = B.snap_id  and B.instance_number = 1
where tablespace_id = (select ts# from v$tablespace where name = '&1')
and A.snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and A.snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
group by A.snap_id,   b.end_interval_time
order by snap_id
)
, agg1 as
(
select trunc(day, 'DD') day, avg(ts_used_gb) ts_daily_used_gb, avg(ts_maxsize_gb) ts_daily_max_gb
from pivot1
group by trunc(day, 'DD')
order by 1
)
select day, ts_daily_max_gb, ts_daily_used_gb , (ts_daily_used_gb - lag(ts_daily_used_gb) over (order by day )) - (ts_daily_max_gb - lag(ts_daily_max_gb) over (order by day )) daily_change_gb, ts_daily_max_gb - ts_daily_used_gb ts_daily_free_gb
from agg1
order by day;
