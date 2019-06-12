col OWNER2 new_value 1 format A20
col TABLE_NAME2 new_value 2 format A20
col PART_NAME2 new_value 3 format A20
col COLUMN_NAME2 new_value 4 format A20

select null OWNER2, null TABLE_NAME2, null PART_NAME2, null COLUMN_NAME2 from dual where 1=2;
select nvl( '&1','&_USER') OWNER2, nvl('&2','%') TABLE_NAME2, nvl('&3','%')  PART_NAME2, nvl('&4','%')  COLUMN_NAME2 from dual ;


define OWNER=&1
define TABLE_NAME=&2     
define PART_NAME=&3
define COLUMN_NAME=&4

undefine 1
undefine 2
undefine 3
undefine 4

column column_name format A30
column estimated_selectivity format 99999999.9999999999;
column density format 9999999.99999999;
column interval format A10
column low_v format A20
column hi_v format A20
COLUMN LOW_VALUE FORMAT A20
COLUMN HIGH_VALUE FORMAT A20
COLUMN SAMPLE_SIZE FORMAT 999,999,999

prompt
prompt partition column statistics, owner &OWNER, table &TABLE_NAME, partition &PART_NAME,  column &COLUMN_NAME , &DAYS_AGO days ago  
prompt

SELECT
  DT.OWNER ,
  DT.TABLE_NAME ,
  DT.PARTITION_NAME,
  DT.COLUMN_NAME,
  DT.LAST_ANALYZED ,
  DT.SAMPLE_SIZE ,
  DT.NUM_DISTINCT ,
  DT.DENSITY ,
  DT.NUM_NULLS ,
  DT.GLOBAL_STATS,
  DT.USER_STATS,
  DT.AVG_COL_LEN,
  DT.HISTOGRAM ,
  DT.NUM_BUCKETS,
  DT.LOW_VALUE,
  DT.HIGH_VALUE ,
  decode(B.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(DT.low_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(DT.low_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(DT.low_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(DT.low_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(DT.low_value))       ,'DATE',to_char(1780+to_number(substr(DT.low_value,1,2),'XX')    +to_number(substr(DT.low_value,3,2),'XX'))||'-'       ||to_number(substr(DT.low_value,5,2),'XX')||'-'       ||to_number(substr(DT.low_value,7,2),'XX')||' '       ||(to_number(substr(DT.low_value,9,2),'XX')-1)||':'       ||(to_number(substr(DT.low_value,11,2),'XX')-1)||':'       ||(to_number(substr(DT.low_value,13,2),'XX')-1),  DT.low_value       ) low_v,
  decode(B.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(DT.high_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(DT.high_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(DT.high_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(DT.high_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(DT.high_value))  ,'DATE',to_char(1780+to_number(substr(DT.high_value,1,2),'XX')   +to_number(substr(DT.high_value,3,2),'XX'))||'-'       ||to_number(substr(DT.high_value,5,2),'XX')||'-'       ||to_number(substr(DT.high_value,7,2),'XX')||' '       ||(to_number(substr(DT.high_value,9,2),'XX')-1)||':'       ||(to_number(substr(DT.high_value,11,2),'XX')-1)||':'       ||(to_number(substr(DT.high_value,13,2),'XX')-1),  DT.high_value       ) hi_v,
  CREATED 
from 
      dba_part_col_statistics DT
inner join dba_objects DO on DO.owner = DT.owner and DO.object_name = DT.table_name AND DO.subobject_name = DT.partition_name
INNER JOIN dba_tab_columns B on DT.owner = B.owner AND DT.table_name = B.table_name and DT.column_name = B.column_name
where 1=1
AND DT.owner = '&OWNER'
AND DT.table_name = '&TABLE_NAME'
AND DT.column_name LIKE '&COLUMN_NAME'
AND DT.partition_name like '&PART_NAME'
and DO.object_type = 'TABLE PARTITION'
and DO.created > trunc(sysdate) - &DAYS_AGO
ORDER BY PARTITION_NAME;


undefine OWNER
undefine TABLE_NAME
undefine PART_NAME
undefine COLUMN_NAME















