

col P1 new_value 1 format A10
col P2 new_value 2 format A10

select null p1, null p2 from dual where 1=2;
select nvl( '&1','%') p1, nvl('&2','%') p2 from dual ;

   
define OWNER=&1
define TABLE_NAME=&2  


undefine 1
undefine 2
undefine 3


prompt
prompt Querying for &TABLE_NAME in &OWNER, &DAYS_AGO days ago.
prompt

column operation format A20
column target format A50
column start_time format A21
column end_time format A21
column STATS_UPDATE_TIME format A21
ALTER session SET NLS_TIMESTAMP_TZ_FORMAT='DY DD-MON-YYYY HH24:MI TZR';

PROMPT
PROMPT GLOBAL STATS :
PROMPT

SELECT operation, target, start_time , end_time, ( cast(end_time as DATE) - cast(start_time as DATE) ) * 24*60  as etime_mins
 FROM dba_optstat_operations
where TARGET like '&OWNER..&TABLE_NAME'
-- and start_time > '14-FEB-2016 15.00 CET' 
-- and end_time < '14-FEB-2016 17.00 CET'
and start_time > trunc(sysdate) - &DAYS_AGO
 ORDER BY start_time ;


PROMPT
PROMPT PARTITION AND SUBPARTITION STATS :
PROMPT

SELECT operation, target, start_time , end_time, ( cast(end_time as DATE) - cast(start_time as DATE) ) * 24*60  as etime_mins
 FROM dba_optstat_operations
where TARGET LIKE '&OWNER..&TABLE_NAME..%'
-- and start_time > '14-FEB-2016 15.00 CET' 
-- and end_time < '14-FEB-2016 17.00 CET'
and start_time > trunc(sysdate) - &DAYS_AGO
 ORDER BY start_time ;




