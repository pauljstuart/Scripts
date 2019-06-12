
col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2, nvl('&3','%')  PARAM3 from dual ;


define USERNAME=&1
define TABLE_NAME=&2     
define COLUMN_NAME=&3

undefine 1
undefine 2
undefine 3



prompt
prompt Histograms :
prompt

column end_point format A10
column endpoint_value format 9999999999999999999999999999999999999999


SELECT table_name, 
      partition_name, 
       column_name, 
      BUCKET_number,
      BUCKET_number - NVL(prev_endpoint,0) frequency,
      hex_val,
  chr(to_number(SUBSTR(hex_val, 2,2),'XX'))
  || chr(to_number(SUBSTR(hex_val, 4,2),'XX'))
  || chr(to_number(SUBSTR(hex_val, 6,2),'XX'))
  || chr(to_number(SUBSTR(hex_val, 8,2),'XX'))
  || chr(to_number(SUBSTR(hex_val,10,2),'XX'))
  || chr(to_number(SUBSTR(hex_val,12,2),'XX')) endpoint_decoded
from
  (SELECT PH.table_name, PH.partition_name, PH.column_name, PH.BUCKET_NUMBER,
    lag(BUCKET_number,1) over( order by BUCKET_NUMBER ) prev_endpoint,
    TO_CHAR(endpoint_value,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')hex_val,
    endpoint_actual_value
  FROM dba_PART_histograms PH
inner join dba_objects DO on DO.owner = PH.owner and DO.object_name = PH.table_name AND DO.subobject_name = PH.partition_name
  WHERE PH.owner     = '&OWNER'
  AND PH.table_name  = '&TABLE_NAME'
  AND PH.column_name = '&COLUMN_NAME'
 AND BUCKET_NUMBER = 1
and DO.object_type = 'TABLE PARTITION'
and DO.created > trunc(sysdate) - &DAYS_AGO
  )
ORDER BY BUCKET_number;

