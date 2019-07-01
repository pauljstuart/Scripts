column host format A30
column acl format A30
column principal format A30

select ACL, host, lower_port, upper_port from dba_network_acls
order by 1;

select ACL, PRINCIPAL, PRIVILEGE, IS_GRANT
from dba_network_acl_privileges;
