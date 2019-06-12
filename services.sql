

col SERVICE2 new_value 1 noprint


select null SERVICE2 from dual where 1=2;
select nvl( '&1','%') SERVICE2 from dual ;

define SERVICE_NAME=&1

undefine 1

column network_name format A40 truncate

select name, network_name, failover_type, failover_retries, failover_method, failover_delay, enabled from dba_services
where name like '%&SERVICE_NAME%';

break on inst_id skip page dup

prompt : gv$services :

select INST_ID, NAME, NETWORK_NAME, CREATION_DATE ,GOAL       from gv$services
where name not in ('SYS$USERS','SYS$BACKGROUND')
and name like '%&SERVICE_NAME%'
order by inst_id;


prompt : gv$active_services :

select INST_ID, NAME, NETWORK_NAME, CREATION_DATE ,GOAL       from gv$active_services
where name not in ('SYS$USERS','SYS$BACKGROUND')
and name like '%&SERVICE_NAME%'
order by inst_id;
