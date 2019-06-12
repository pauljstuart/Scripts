



define OWNER=&1;
define TABLE_NAME=&2;
define COLUMN_NAME=&3;


create or replace function raw_to_date(i_raw raw)
return date
as
m_n date;
begin
dbms_stats.convert_raw_value(i_raw,m_n);
return m_n;
end;
/ 

column estimated_selectivity format 0.9999999999;
column density format 99999.999999999;
COLUMN COLUMN_NAME FORMAT a30
COLUMN ENDPOINT_NUMBER FORMAT 999999
column endpoint_value format 999999999999999999999999999999999999
column ENDPOINT_ACTUAL_VALUE format A30


prompt 
prompt Histograms for &COLUMN_NAME (dba_tab_histograms)
prompt

WITH 
   num_table_rows1 AS
      ( SELECT num_rows AS num_table_rows FROM all_tab_statistics WHERE table_name  = upper('&TABLE_NAME') and owner = upper('&OWNER') and partition_name IS NULL )
select endpoint_number,
        endpoint_value , endpoint_actual_value,
	endpoint_number - lag(endpoint_number,1,0) OVER (ORDER BY endpoint_number) AS frequency,
	(endpoint_number - lag(endpoint_number,1,0) OVER (ORDER BY endpoint_number))/(select num_table_rows from num_table_rows1) as estimated_selectivity
FROM dba_tab_histograms
WHERE 
    table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER')
AND column_name = upper('&COLUMN_NAME');

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




