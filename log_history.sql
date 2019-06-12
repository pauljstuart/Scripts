--
--
-- Paul Stuart
--
-- Dec 2002
-- Feb 2005


COLUMN lowest_SCN  FORMAT 99999999999999
COLUMN Highest_SCN FORMAT 99999999999999

select inst_id,
  RECID ,
 STAMP,
 THREAD# ,
 SEQUENCE# ,
 FIRST_TIME  ,
 FIRST_CHANGE# Lowest_SCN,
 NEXT_CHANGE# Highest_SCN
from gv$log_history
order by first_time asc;

