

col P_ROLE new_value 1

select null P_ROLE  from dual where 1=2;
select nvl( '&1','%') P_ROLE from dual ;

define ROLES=&1     

undefine 1
undefine 2



SELECT *
FROM dba_roles
where role like '&ROLES';



