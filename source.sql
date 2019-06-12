


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define SOURCE_NAME=&2     


undefine 1
undefine 2
undefine 3



column LINE format 9999
column TEXT format a200 
column TYPE format A20
column owner format A10

select owner, type, name, line,regexp_replace(dbms_LOB.substr(text, 200), '[[:cntrl:]]',null)  text
 --substr(text, 1,100) text
from dba_source
where owner like '&USERNAME'
and name like '&SOURCE_NAME'
order by type, name, line;

