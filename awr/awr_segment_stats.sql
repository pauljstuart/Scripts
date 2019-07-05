

-- a query to examine the ITL waits on particular index segments

WITH pivot1 AS
(
SELECT object_id FROM dba_objects WHERE object_name = 'JOURNALS_IDX9'
),
pivot2 AS 
(
SELECT snap_id , begin_interval_time FROM dba_hist_snapshot WHERE trunc(begin_interval_time, 'DD' ) > SYSDATE - 30
)
SELECT snap_id,   sum(itl_waits_delta)
FROM dba_hist_seg_stat
WHERE obj# IN (SELECT object_id FROM pivot1)
and snap_id in (select snap_id from pivot2)
GROUP BY snap_id
order by snap_id;


-- query to sum block changes to database segments during a particular period

-- can be used to see where changes are being made, perhaps to identify excessive redo being generated.

column sum_block_changes format 999,999,999,999
SELECT to_char(begin_interval_time,'YYYY-MM-DD HH24:MI') snap_time,
        dhsso.owner,
        dhsso.object_name,
        SUM(db_block_changes_delta) sum_block_changes
FROM dba_hist_seg_stat dhss,
         dba_hist_seg_stat_obj dhsso,
         dba_hist_snapshot dhs
WHERE dhs.snap_id = dhss.snap_id
    AND dhs.instance_number = dhss.instance_number
    AND dhss.obj# = dhsso.obj#
    AND dhss.dataobj# = dhsso.dataobj#
    AND begin_interval_time BETWEEN to_date('2014-01-30 21','YYYY-MM-DD HH24') AND to_date('2014-01-30 22','YYYY-MM-DD HH24')
GROUP BY to_char(begin_interval_time,'YYYY-MM-DD HH24:MI'), dhsso.owner, dhsso.object_name
having SUM(db_block_changes_delta) > 500
order by 1,4 desc;
