



col P_OWNER new_value 1 format A10
col P_TABLE_NAME new_value 2 format A20
col P_COL_NAME new_value 3 format A20

select null P_OWNER, null P_TABLE_NAME, null P_COL_NAME from dual where 1=2;
select nvl( '&1','&_USER') P_OWNER, nvl('&2','%') P_TABLE_NAME, nvl('&3','%')  P_COL_NAME from dual ;


define OWNER=&1
define TABLE_NAME=&2
define COLUMN_NAME=&3

undefine 1
undefine 2
undefine 3



column estimated_selectivity format 0.9999999999;
column density format 99999.999999999;
COLUMN COLUMN_NAME FORMAT a30
COLUMN ENDPOINT_NUMBER FORMAT 999999
column cardinality format 999,999,999,999
column low_v format A20
column hi_v format A20
COLUMN LOW_VALUE FORMAT A20
COLUMN HIGH_VALUE FORMAT A20

prompt 
prompt global Column statistics for &COLUMN_NAME (dba_tab_col_statistics)
prompt

WITH 
pivot1 AS
( SELECT num_rows
from dba_tables
where table_name = '&TABLE_NAME'
AND owner = '&OWNER'
)
SELECT  A.OWNER,
       A.TABLE_NAME,
      A.COLUMN_NAME,
    B.AVG_COL_LEN,
   B.NUM_DISTINCT,
   B.DENSITY,
   B.NUM_NULLS,
   B.density*(select num_rows from pivot1 ) as cardinality,
   B.LAST_ANALYZED,
   B.SAMPLE_SIZE*100/(select num_rows from pivot1 ) sample_pct,
   B.GLOBAL_STATS,
   B.USER_STATS,                     
    B.HISTOGRAM, 
   B.NUM_BUCKETS ,
  B.LOW_VALUE,
  B.HIGH_VALUE ,
    decode(A.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(B.low_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(B.low_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(B.low_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(B.low_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(B.low_value))  ,'DATE',to_char(1780+to_number(substr(B.low_value,1,2),'XX')         +to_number(substr(B.low_value,3,2),'XX'))||'-'       ||to_number(substr(B.low_value,5,2),'XX')||'-'       ||to_number(substr(B.low_value,7,2),'XX')||' '       ||(to_number(substr(B.low_value,9,2),'XX')-1)||':'       ||(to_number(substr(B.low_value,11,2),'XX')-1)||':'       ||(to_number(substr(B.low_value,13,2),'XX')-1),  B.low_value       ) low_v,
    decode(A.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(B.high_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(B.high_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(B.high_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(B.high_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(B.high_value))  ,'DATE',to_char(1780+to_number(substr(B.high_value,1,2),'XX')         +to_number(substr(B.high_value,3,2),'XX'))||'-'       ||to_number(substr(B.high_value,5,2),'XX')||'-'       ||to_number(substr(B.high_value,7,2),'XX')||' '       ||(to_number(substr(B.high_value,9,2),'XX')-1)||':'       ||(to_number(substr(B.high_value,11,2),'XX')-1)||':'       ||(to_number(substr(B.high_value,13,2),'XX')-1),  B.high_value       ) hi_v
FROM dba_tab_columns  A
left outer join dba_tab_col_statistics  B on A.owner = B.owner AND A.table_name = B.table_name and A.column_name = B.column_name
WHERE A.table_name = '&TABLE_NAME'
AND A.owner = '&OWNER'
AND A.column_name like '&COLUMN_NAME'
ORDER BY COLUMN_ID;








undefine 1
undefine 2
undefine 3



