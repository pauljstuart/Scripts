


col P_USER new_value 1
col P_TABLESPACE new_value 2

select null P_USER, null P_TABLESPACE  from dual where 1=2;
select nvl( '&1','%') P_USER , nvl('&2','%') P_TABLESPACE from dual ;

define USERS=&1     
define TABLESPACE=&2

undefine 1
undefine 2


select username, tablespace_name, bytes, max_bytes
from dba_ts_quotas
where username like '&USERS'
AND TABLESPACE_NAME like '&TABLESPACE'
order by username ;

