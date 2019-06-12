-- Paul Stuart
-- 
-- Nov 2004
-- Apr 2005
-- Feb 2014


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define VIEW_NAME=&2     


undefine 1
undefine 2
undefine 3


column text_length format 999,999


prompt
prompt Views owned by &USERNAME (&VIEW_NAME)
prompt 

select owner, view_name, text_length
from dba_views
where owner like '&USERNAME'
and view_name like '&VIEW_NAME'
order by view_name;


