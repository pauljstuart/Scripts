

col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define MVIEW_NAME=&2     


undefine 1
undefine 2
undefine 3


column query format A30
column last_refresh_date format A20
column up      format a2
column Rewrite format A7
column mview_name format A40

select owner, mview_name,updatable "up",rewrite_enabled "Rewrite", refresh_mode, refresh_method, fast_refreshable, last_refresh_date, 
          last_refresh_type "Last Ref Type", 
        staleness, compile_state
from dba_mviews
WHERE
  owner like '&USERNAME'
AND mview_name LIKE '&MVIEW_NAME'
order by last_refresh_date;

