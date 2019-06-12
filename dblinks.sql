--
-- set commandline defaults
--

col P_USERNAME new_value 1 format A10
col P_DBLINK new_value 2 format A10


select null P_USERNAME, null P_DBLINK from dual where 1=2;
select nvl( '&1','&_USER') P_USERNAME, nvl('&2','%') P_DBLINK from dual ;

define USERNAME=&1
define DB_LINK=&2



undefine 1
undefine 2
undefine 3


column host format a200;
column db_link format a35;


select owner, db_link, created, username, host 
from dba_db_links
where db_link like '&DB_LINK'
AND owner like '&USERNAME' 

/
