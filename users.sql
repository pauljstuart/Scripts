set echo off
--
-- who.sql
--
-- Paul Stuart
-- Oct 2004
-- May 2014
--



col p1 new_value 1

select null p1  from dual where 1=2;
select nvl( '&1','%') p1 from dual ;

define USERNAME_PATTERN=&1     




column username format a30;
column account_status format a10 heading 'Status';
column default_tablespace format a15 heading 'Default TS';
column profile format a20;
column temporary_tablespace format a15;
column external_name format A20



SELECT username, 
        user_id, 
        account_status, 
        default_tablespace, 
        temporary_tablespace, 
        profile,
        password_versions, 
        external_name
FROM dba_users
WHERE USERNAME LIKE '&USERNAME_PATTERN'
ORDER BY user_id;


undefine 1
undefine 2
