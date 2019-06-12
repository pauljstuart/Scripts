


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2, nvl('&3','%') PARAM3 from dual ;


define USERNAME=&1
define OBJ_NAME=&2     


undefine 1
undefine 2
undefine 3



 column OWNER format A30
 column OBJECT_NAME format A40
 column SUBOBJECT_NAME format A20
 column OBJECT_ID  format 999999999999
 column  OBJECT_TYPE format A10
 
PROMPT
PROMPT &USERNAME/&OBJ_NAME 
PROMPT
 
select OWNER ,OBJECT_NAME,SUBOBJECT_NAME,OBJECT_ID, OBJECT_TYPE,CREATED , LAST_DDL_TIME,  STATUS   
 from dba_objects 
where object_name like '&OBJ_NAME'
and owner like '&USERNAME'
order by created desc;
