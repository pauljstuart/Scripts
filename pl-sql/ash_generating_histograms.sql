

with pivot_table as
(select event, time_waited/1000 time_ms, 
    CASE WHEN width_bucket( time_waited/1000, 0, 9, 1) = 1 THEN 1 ELSE 0 END AS "0to9",
    CASE WHEN width_bucket( time_waited/1000, 10, 19, 1) = 1 THEN 1 ELSE 0 END AS "10to19",
    CASE WHEN width_bucket( time_waited/1000, 20, 29, 1) = 1 THEN 1 ELSE 0 END AS "20to29",
    CASE WHEN width_bucket( time_waited/1000, 30, 39, 1) = 1 THEN 1 ELSE 0 END AS "30to39",
    CASE WHEN width_bucket( time_waited/1000, 40, 49, 1) = 1 THEN 1 ELSE 0 END AS "40to49",
    CASE WHEN width_bucket( time_waited/1000, 50, 99, 1) = 1 THEN 1 ELSE 0 END AS "50to99",
    CASE WHEN width_bucket( time_waited/1000, 100, 199, 1) = 1 THEN 1 ELSE 0 END AS "100to199",
   CASE WHEN width_bucket( time_waited/1000, 200, 500, 1) = 1 THEN 1 ELSE 0 END AS "200to500"
from gv$active_session_history
where sample_time >  TO_DATE ('21/11/2012 11:11', 'dd/mm/yyyy hh24:mi:ss') 
and sample_time < TO_DATE ('21/11/2012 11:21', 'dd/mm/yyyy hh24:mi:ss') 
and event = 'db file sequential read'
and session_type = 'FOREGROUND'
)
select sum("0to9"), sum("10to19"), sum("20to29"), sum("30to39"), sum("40to49"), sum("50to99"), sum("100to199"), sum("200to500")
from pivot_table;



with pivot_table as
(select event, time_waited/1000 time_ms, 
    CASE WHEN width_bucket( time_waited/1000, 0, 9, 1) = 1 THEN 1 ELSE 0 END AS "0to9",
    CASE WHEN width_bucket( time_waited/1000, 10, 19, 1) = 1 THEN 1 ELSE 0 END AS "10to19",
    CASE WHEN width_bucket( time_waited/1000, 20, 29, 1) = 1 THEN 1 ELSE 0 END AS "20to29",
    CASE WHEN width_bucket( time_waited/1000, 30, 39, 1) = 1 THEN 1 ELSE 0 END AS "30to39",
    CASE WHEN width_bucket( time_waited/1000, 40, 49, 1) = 1 THEN 1 ELSE 0 END AS "40to49",
    CASE WHEN width_bucket( time_waited/1000, 50, 99, 1) = 1 THEN 1 ELSE 0 END AS "50to99",
    CASE WHEN width_bucket( time_waited/1000, 100, 199, 1) = 1 THEN 1 ELSE 0 END AS "100to199",
   CASE WHEN width_bucket( time_waited/1000, 200, 499, 1) = 1 THEN 1 ELSE 0 END AS "200to500",
      CASE WHEN width_bucket( time_waited/1000, 500, 1000, 1) = 1 THEN 1 ELSE 0 END AS "500to1000",
         CASE WHEN width_bucket( time_waited/1000, 1000, 2000, 1) = 1 THEN 1 ELSE 0 END AS "1000to2000",
    CASE WHEN width_bucket( time_waited/1000, 2000, 5000, 1) = 1 THEN 1 ELSE 0 END AS "2000to5000",
      CASE WHEN width_bucket( time_waited/1000, 5000, 10000, 1) = 1 THEN 1 ELSE 0 END AS "5000to10000",
    CASE WHEN width_bucket( time_waited/1000, 10000, 10000000, 1) = 1 THEN 1 ELSE 0 END AS "over10sec"
from dba_hist_active_sess_history
where sample_time >  TO_DATE ('26/11/2012 02:30', 'dd/mm/yyyy hh24:mi:ss') 
and sample_time < TO_DATE ('26/11/2012 02:33', 'dd/mm/yyyy hh24:mi:ss') 
and snap_id > 38795 
and event = 'log file sync'
and session_type = 'FOREGROUND'
)
select sum("0to9"), sum("10to19"), sum("20to29"), sum("30to39"), sum("40to49"), sum("50to99"), sum("100to199"), sum("200to500"),
       sum("500to1000"), sum("1000to2000"), sum("2000to5000"), sum("5000to10000"), sum("over10sec")
from pivot_table;
