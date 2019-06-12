rem
rem Get status of all procedures and packages
rem 
rem PJS 
-- NOv 2002
-- Nov 2004



col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10


select null PARAM1, null PARAM2  from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define PACKAGE_NAME=&2     


undefine 1
undefine 2



column package_name format a30
  
  
select  owner, O.object_name package_name,  O.object_type type,  O.status , O.last_ddl_time
from DBA_objects O
where O.object_type IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE' )
and object_name like '&PACKAGE_NAME'
and o.owner like '&USERNAME';
