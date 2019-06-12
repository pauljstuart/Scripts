--
-- Paul Stuart
--
-- April 2005

col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define JOB=&2     


undefine 1
undefine 2
undefine 3



column what format a200
column interval format a24
column schema_user format a12
column Fail    format 999
column job format 99999
column total_time format 999,999
column broken format A5

select job, schema_user,last_date, total_time , next_date, interval, failures fail, broken , what 
from dba_jobs
where schema_user like '&USERNAME'
and job like '&JOB'
order by next_date;

