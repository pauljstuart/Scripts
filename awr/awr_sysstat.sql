

column 1 format 999,999,999,999 heading inst_1
column 2 format 999,999,999,999 heading inst_2
column 3 format 999,999,999,999 heading inst_3
column 4 format 999,999,999,999 heading inst_4
column 5 format 999,999,999,999 heading inst_5
column 6 format 999,999,999,999 heading inst_6
column begin_time format A21
column value_change format 999,999,999,999
column value format 999,999,999,999
column value_change_db format 999,999,999,999


-- dba_hist_sysstat, for each instance :

with pivot1 as
(
select snap_id, 
       stat_name, 
       instance_number,
       (select distinct begin_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) begin_time, 
       greatest ( value -  lag(value,1) over (partition by instance_number, stat_name order by snap_id) , 0 ) as value_change
FROM DBA_HIST_SYSSTAT AWR
where  stat_name  like 'bytes sent via SQL*Net to client'
and dbid = (select dbid from v$database)
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
)
select * from pivot1 AWR
pivot
( sum(value_change) 
  for instance_number in (1,2,3,4)
)
order by snap_id;




-- a simple dba_hist_sysstat LAG query, summed across the whole database :


column end_time format A21
with pivot1 as
(
select snap_id, 
       stat_name, 
       instance_number,
       (select end_interval_time from dba_hist_snapshot SNAP where SNAP.snap_id = AWR.snap_id and rownum = 1) end_time, 
       greatest ( value -  lag(value,1) over (partition by instance_number, stat_name order by snap_id) , 0 ) as value_change
FROM DBA_HIST_SYSSTAT AWR
where  stat_name  like 'Parallel operations downgraded to serial'
and dbid = (select dbid from v$database)
and dbid = (select dbid from v$database)
and snap_id  > (select min(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) and begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') )
and snap_id  < (select max(snap_id) from dba_hist_snapshot where dbid = (select dbid from v$database) ) 
)
select snap_id, stat_name, end_time,  sum(value_change) value_change_db
from pivot1
group by snap_id, stat_name, end_time
order by snap_id;





/*


column stat_name format A20

column inst1 format 999,999,999.9

WITH 
pivot1 as
(
select min(snap_id) AS begin_snap_id
from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
),
pivot2 as
(
SELECT snap_id, 
  instance_number,
  stat_name,
  NVL ( DECODE ( GREATEST ( VALUE, NVL ( LAG ( VALUE) OVER (PARTITION BY dbid, instance_number, stat_name ORDER BY snap_id), 0)), VALUE, VALUE - LAG ( VALUE) OVER (PARTITION BY dbid, instance_number, stat_name ORDER BY snap_id), VALUE), 0) VALUE
FROM DBA_HIST_SYSSTAT
where   snap_id > (select begin_snap_id from pivot1)
and  stat_name  like 'cell physical IO bytes sent %'
),
pivot3 as
(
select snap_id,
        stat_name,
       (CASE  WHEN instance_number = 1     THEN value     else 0 END) as inst1,
       (CASE  WHEN instance_number = 2     THEN value     else 0 END) as inst2,
       (CASE  WHEN instance_number = 3     THEN value     else 0 END) as inst3,
       (CASE  WHEN instance_number = 4     THEN value     else 0 END) as inst4,
       (CASE  WHEN instance_number = 5     THEN value     else 0 END) as inst5,
       (CASE  WHEN instance_number = 5     THEN value     else 0 END) as inst6
 from pivot2
)
select pivot3.snap_id, trunc(AWR.begin_interval_time, 'MI'), stat_name, 
         sum(inst1) inst1, sum(inst2) inst2, sum(inst3) inst3, sum(inst4) inst4, sum(inst5) inst5
from 
pivot3
inner join dba_hist_snapshot AWR on 
AWR.snap_id = pivot3.snap_id
 group by pivot3.snap_id, trunc(AWR.begin_interval_time, 'MI'), stat_name
 order by pivot3.snap_id;

*/
