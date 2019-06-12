



column recid format 99999
column operation format A10
column session_stamp format 9999999999

SELECT * FROM
(
SELECT T1.SID, T1.recid, T1.session_stamp, T2.start_time, T2.operation, output, 
    row_number () over ( order by  T2.start_time desc ) r
FROM v$rman_output T1
INNER JOIN   v$rman_status T2 ON T1.session_stamp = T2.session_stamp AND T1.session_recid = T2.session_recid
AND T2.row_level = 0
)
where r < 1000
order by session_stamp , recid  ;
