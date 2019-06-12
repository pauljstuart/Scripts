define OBJECT_NAME=&1

prompt
prompt Object privs for &OBJECT_NAME :
prompt

select *
from dba_tab_privs
where table_name = upper('&OBJECT_NAME');
