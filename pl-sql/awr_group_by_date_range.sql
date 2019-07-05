


-- http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:13946369553642


--
-- grouping by date ranges when there's nothing else to group by
-- 

-- when the difference between dates is 3 days :

WITH tom1 AS
(
SELECT start_time, table_name,
           lag(start_time) OVER (ORDER BY start_time),
           CASE WHEN abs(lag(start_time) OVER (ORDER BY start_time) - start_time) > 3 THEN row_number() OVER (ORDER BY start_time)
                    when row_number() over (order by start_time) = 1 then 1
                            else null
                    END rn
      from meridian.compression_work_request T
WHERE start_time > to_date('14-MAY-2013', 'DD-MON-YYYY')
AND table_name = 'POSTING'
),
tom2 AS
(
SELECT start_time, table_name, MAX(rn) OVER (ORDER BY start_time) AS date_range_id
from tom1
)
SELECT table_name, MIN(start_time), MAX(start_time)
FROM tom2
GROUP BY table_name, date_range_id
order by min(start_time);



-- and also using ASH data 
-- date difference being 5 mins in this instance


WITH tom1 AS
(
SELECT ASH.*,
           lag(sample_time) OVER (ORDER BY sample_time),
           CASE WHEN lag(sample_time) OVER (ORDER BY sample_time) - sample_time > TO_DSINTERVAL('000 00:05:00') THEN row_number() OVER (ORDER BY sample_time)
                    when row_number() over (order by sample_time) = 1 then 1
                            else null
                    END rn
from dba_hist_active_sess_history ASh
WHERE  
    ASH.session_type = 'FOREGROUND'
AND ASH.session_state = 'WAITING'AND  ASH.sample_time >  TO_DATE ('29/06/2013 21:30', 'dd/mm/yyyy hh24:mi') 
AND ASH.sample_time <   TO_DATE ('30/06/2013 12:00', 'dd/mm/yyyy hh24:mi') 
AND     ASH.snap_id >89684
AND instance_number = 4
AND session_id = 676
AND session_serial# =4505
AND sql_id = '0s6ng7m59977g'
),
tom2 AS
(
SELECT start_time, table_name, MAX(rn) OVER (ORDER BY start_time) AS date_range_id
from tom1
)
SELECT table_name, MIN(start_time), MAX(start_time)
FROM tom2
GROUP BY table_name, date_range_id
order by min(start_time);

