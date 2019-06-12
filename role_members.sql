select granted_role, grantee from dba_role_privs 
where granted_role = '&ROLE_NAME';

