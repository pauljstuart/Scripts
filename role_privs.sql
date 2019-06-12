define ROLE_NAME=&1

prompt
prompt object privs :
prompt

select * 
from role_tab_privs 
where role = '&ROLE_NAME' 
order by table_name;


prompt
prompt system privileges for &ROLE_NAME :
prompt


select * from dba_sys_privs
where grantee  like UPPER('&ROLE_NAME');


prompt grantees :
prompt

select * 
from dba_role_privs 
where granted_role = '&ROLE_NAME' ;

