--
--
-- Paul Stuart
-- Nov 2004

col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2  from dual ;


define USERNAME=&1
define TABLE_NAME=&2     


undefine 1
undefine 2
undefine 3


column index_name format a15
column Type format a4
column search_condition format A55
column table_name format A30
column validated format A5
column r_owner format A20
column r_constraint_name format A30



break on table_name

select  owner,  table_name,
        constraint_name, 
        constraint_type Type,  
        r_owner,   
        r_constraint_name, 
        status, 
        validated, 
        index_name, 
        search_condition
from dba_constraints
where table_name like '&TABLE_NAME'
and owner = '&USERNAME'
order by table_name;
/

