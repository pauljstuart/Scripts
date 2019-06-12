
set echo off

define USERNAME=&1



column owner format a15;
column role format a20;
column table_name format a30;
column privilege format a30;


PROMPT
prompt roles :
prompt

select * from dba_role_privs
where grantee  like UPPER('&USERNAME');

PROMPT
prompt privileges :
prompt


select * from dba_sys_privs
where grantee  like UPPER('&USERNAME');

prompt
prompt object privileges :
prompt

select * from dba_tab_privs
where grantee like UPPER('&USERNAME');


prompt
prompt Tablespace quotas :
prompt



select username, tablespace_name, bytes, max_bytes
from dba_ts_quotas
where username = upper('&USERNAME')
order by username ;


