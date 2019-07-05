




define DAYS_AGO=7;

COLUMN snap_id NEW_VALUE starting_snap_id no_print

select snap_id , begin_interval_time from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD') = trunc(sysdate - &DAYS_AGO, 'DD')
and rownum = 1
order by snap_id desc;

clear screen



prompt
prompt
prompt  Starting snap_id from &DAYS_AGO days ago is &STARTING_SNAP_ID
prompt
prompt


COLUMN bytes_sent_delta format 999,999,999,999;
COLUMN bytes_received_delta format 999,999,999,999;
COLUMN bytes_total_delta format 999,999,999,999;

WITH pivot1 AS 
(
SELECT dbid, 
          instance_number, 
          snap_id, 
          CASE WHEN stat_name = 'bytes sent via SQL*Net to dblink' THEN VALUE ELSE 0 END AS   sent,
          CASE WHEN stat_name = 'bytes received via SQL*Net from dblink' THEN VALUE ELSE 0 END as  received
FROM DBA_HIST_SYSSTAT
WHERE snap_id > &STARTING_SNAP_ID
AND  stat_name IN ('bytes received via SQL*Net from dblink', 'bytes sent via SQL*Net to dblink' ) 
ORDER BY 3
),
pivot2 AS 
(
SELECT dbid,
       instance_number, 
       snap_id,
        sum(sent) AS bytes_sent,
        sum(received) as bytes_received,
        sum(sent + received) AS bytes_total
FROM pivot1
GROUP BY dbid, instance_number, snap_id
) 
SELECT AWR.begin_interval_time, 
   SS.snap_id, 
  SS.dbid,
  SS.instance_number,
  NVL ( DECODE ( GREATEST ( bytes_sent, NVL ( LAG ( bytes_sent) OVER (PARTITION BY SS.dbid, SS.instance_number ORDER BY SS.snap_id), 0)), bytes_sent, bytes_sent - LAG ( bytes_sent) OVER (PARTITION BY SS.dbid, SS.instance_number ORDER BY SS.snap_id), bytes_sent), 0) bytes_sent_delta,
  NVL ( DECODE ( GREATEST ( bytes_received, NVL ( LAG ( bytes_received) OVER (PARTITION BY SS.dbid, SS.instance_number ORDER BY SS.snap_id), 0)), bytes_received, bytes_received - LAG ( bytes_received) OVER (PARTITION BY SS.dbid, SS.instance_number ORDER BY SS.snap_id), bytes_received), 0) bytes_received_delta,
  NVL ( DECODE ( GREATEST ( bytes_total, NVL ( LAG ( bytes_total) OVER (PARTITION BY SS.dbid, SS.instance_number ORDER BY SS.snap_id), 0)), bytes_total, bytes_total - LAG ( bytes_total) OVER (PARTITION BY SS.dbid, SS.instance_number ORDER BY SS.snap_id), bytes_total), 0) bytes_total_delta
FROM pivot2 SS, dba_hist_snapshot AWR
where SS.snap_id = AWR.snap_id;
