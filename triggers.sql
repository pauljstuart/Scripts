

col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define TRIG_NAME=&2     


undefine 1
undefine 2
undefine 3

column trigger_body format A60
column triggering_event format A20
column when_clause format A20
column trigger_name format A40
column trigger_body format A600

select owner, trigger_name,trigger_type,triggering_event, table_name, column_name, when_clause,   trigger_body 
FROM dba_triggers
where owner like '&USERNAME'
and trigger_name like '&TRIG_NAME';


