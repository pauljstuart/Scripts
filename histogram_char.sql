
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


/*
prompt
prompt Histogram : basic query
prompt


SELECT OWNER,
       TABLE_NAME,
       COLUMN_NAME,
       ENDPOINT_NUMBER,
       ENDPOINT_VALUE
FROM all_tab_histograms
WHERE table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER')
AND column_name = upper('&COLUMN_NAME');



prompt
prompt Data distribution analysis for column &COLUMN_NAME in &TABLE_NAME :
prompt

select sum(tot) tot_rows, count(*) adjustment_ids, min(tot) least_per_id, max(tot) most_per_id, avg(tot) avg_per_id 
from
(
select &COLUMN_NAME, count(*) tot 
from &OWNER..&TABLE_NAME
group by &COLUMN_NAME);

prompt
prompt and a histogram analysis of the data :
prompt

with pivot1 
as
(
select &COLUMN_NAME, count(*) tot 
from &OWNER..&TABLE_NAME
group by &COLUMN_NAME
),
sum1 as
(  
select 
  case when tot between 0 and 100 then 1 else 0 end as to100,
  case when tot between 101 and 1000 then 1 else 0 end as to1K,
  case when tot between 1001 and 10000 then 1 else 0 end as to10K,
  case when tot between 10001 and 100000 then 1 else 0 end as to100K,
  case when tot between 10001 and 500000 then 1 else 0 end as to500K,
  case when tot between 500001 and 1000000 then 1 else 0 end as to1M,
  case when tot between 1000001 and 5000000 then 1 else 0 end as to5M,
  case when tot between 5000001 and 10000000 then 1 else 0 end as to10M,
  case when tot between 10000001 and 500000000 then 1 else 0 end as to50M,
  case when tot between 50000001 and 100000000 then 1 else 0 end as to100M,
  case when tot between 100000001 and 500000000 then 1 else 0 end as to500M,
  case when tot between 500000001 and 1000000000 then 1 else 0 end as to1B
from pivot1
)
select 
      sum(to100) to100,
      sum(to1K) to1K,
      sum(to10K) to10K,
      sum(to100K) to100K,
      sum(to500K) to500K,
      sum(to1M) to1M,
      sum(to5M) to5M,
      sum(to10M) to10M,
      sum(to10M) to50M,
      sum(to100M) to100M,
      sum(to100M) to500M,
      sum(to1B) to1B
from sum1;
*/

prompt
prompt ==============================================================================================================




