




@login

-- overall database usage, per day :


column db_daily_allocated_gb format 999,999,999,999,999
column db_daily_used_gb format 999,999,999,999,999
column day format A15
with pivot1 as
(
select A.snap_id, 
        b.end_interval_time day,  
           sum(tablespace_usedsize)*(select value/(1024*1024*1024) as block_size_gb from v$parameter where name = 'db_block_size' ) db_used_gb,
 sum(tablespace_maxsize)*(select value/(1024*1024*1024) as block_size_gb from v$parameter where name = 'db_block_size' ) db_allocated_gb
 from dba_hist_tbspc_space_usage A
inner join dba_hist_snapshot B on A.snap_id = B.snap_id  and B.instance_number = 1
group by A.snap_id,   b.end_interval_time
)
select trunc(day, 'DD') day, max(db_used_gb) db_daily_used_gb, max(db_allocated_gb) db_daily_allocated_gb
from pivot1
group by trunc(day, 'DD')
order by 1;


@datafiles

DAY                 DB_DAILY_USED_MB      DB_DAILY_MAX_MB
--------------- -------------------- --------------------
MON 28/03/2016            13,069,686           20,875,378
TUE 29/03/2016            13,575,012           20,875,378
WED 30/03/2016            13,509,096           20,875,378
THU 31/03/2016            13,473,563           20,875,378
FRI 01/04/2016            13,688,471           20,875,378
SAT 02/04/2016            13,706,005           20,875,378
SUN 03/04/2016            13,161,912           20,875,378
MON 04/04/2016            13,471,194           20,875,378
TUE 05/04/2016            13,612,399           20,875,378
WED 06/04/2016            13,699,260           20,875,378
THU 07/04/2016            13,847,469           20,875,378
FRI 08/04/2016            14,006,552           20,875,378
SAT 09/04/2016            14,038,791           20,875,378
SUN 10/04/2016            13,409,885           20,875,378
MON 11/04/2016            13,418,151           20,875,378
TUE 12/04/2016            13,963,107           20,875,378
WED 13/04/2016            14,139,046           20,875,378
THU 14/04/2016            14,122,649           20,875,378
FRI 15/04/2016            14,038,323           20,875,378
SAT 16/04/2016            14,157,144           20,875,378
SUN 17/04/2016            13,600,660           20,875,378
MON 18/04/2016            13,608,112           20,875,378
TUE 19/04/2016            14,053,766           20,875,378
WED 20/04/2016            14,054,618           20,875,378
THU 21/04/2016            14,417,118           20,875,378
FRI 22/04/2016            14,316,974           20,875,378
SAT 23/04/2016            14,485,819           20,875,378
SUN 24/04/2016            13,962,236           20,875,378
MON 25/04/2016            13,584,317           20,875,378
TUE 26/04/2016            14,035,699           20,875,378
WED 27/04/2016            13,965,071           20,875,378
THU 28/04/2016            13,955,333           20,875,378
FRI 29/04/2016            14,041,507           20,875,378
SAT 30/04/2016            14,185,159           20,875,378
SUN 01/05/2016            13,673,246           20,875,378
MON 02/05/2016            13,571,987           20,875,378
TUE 03/05/2016            14,136,263           20,875,378
WED 04/05/2016            14,340,130           20,875,378
THU 05/05/2016            14,135,784           20,875,378
FRI 06/05/2016            14,209,739           20,875,378
SAT 07/05/2016            14,195,428           20,875,378
SUN 08/05/2016            13,795,475           20,875,378
MON 09/05/2016            13,782,449           20,875,378
TUE 10/05/2016            14,116,103           20,875,378
WED 11/05/2016            14,275,222           20,875,378
THU 12/05/2016            14,163,453           20,875,378


-- building up from tablespace usage :

with pivot1 as
(
select A.snap_id,  
tablespace_id,
           tablespace_usedsize*(select value/(1024*1024) as block_size_mb from v$parameter where name = 'db_block_size' ) ts_used_mb,
           tablespace_maxsize*(select value/(1024*1024) as block_size_mb from v$parameter where name = 'db_block_size' ) ts_max_mb
from dba_hist_tbspc_space_usage A
where tablespace_id not in (
          select ts# from v$tablespace
          where name like '%TEMP%'or name like '%UNDO%')
--and A.snap_id between 38142 and 38315
order by snap_id
),
pivot2 as
(
select trunc(end_interval_time, 'DD') day, tablespace_id,  max(ts_used_mb) ts_daily_max_mb
from pivot1 A
inner join dba_hist_snapshot B on A.snap_id = B.snap_id  and B.instance_number = 1
--and tablespace_id = 29
group by trunc(end_interval_time, 'DD'), tablespace_id
)
select day, sum(ts_daily_max_mb) db_daily_used_mb
from pivot2
group by day
order by day;
