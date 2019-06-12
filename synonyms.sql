--
--
-- Paul Stuart
-- April 2005
--


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','%') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define SYNONYM_PATTERN=&2


undefine 1
undefine 2
undefine 3

column synonymn_name format A20
column table_owner format A20
column table_name format A50
column db_link format A20
column owner format A20


prompt
prompt Synonyms owned by &USERNAME matching &SYNONYM_PATTERN

select owner, synonym_name, table_owner, table_name, db_link
from DBA_synonyms
where (owner like '&USERNAME'  OR OWNER = 'PUBLIC' )
and table_owner != 'SYS'
and  synonym_name like  upper('&SYNONYM_PATTERN');




