



define OWNER=&1
define TABLE_NAME=&2
define PART_NAME=&3
define COLUMN_NAME=&4



column estimated_selectivity format 0.9999999999;
column density format 99999.999999999;
COLUMN COLUMN_NAME FORMAT a30
COLUMN BUCKET_NUMBER FORMAT 999999
column endpoint_value format 999999999999999999999999999999999999
column DATE_VALUE format A30


prompt 
prompt Histograms for &COLUMN_NAME (dba_tab_histograms)
prompt

WITH 
   num_table_rows1 AS
      ( SELECT num_rows AS num_table_rows FROM all_tab_statistics WHERE table_name  = upper('&TABLE_NAME') and owner = upper('&OWNER') and partition_name IS NULL )
select bucket_number,
        TO_DATE(TRUNC(endpoint_value),'J')+(ENDPOINT_VALUE-TRUNC(ENDPOINT_VALUE)) DATE_VALUE ,
	bucket_number - lag(bucket_number,1,0) OVER (ORDER BY bucket_number) AS frequency,
	(bucket_number - lag(bucket_number,1,0) OVER (ORDER BY bucket_number))/(select num_table_rows from num_table_rows1) as estimated_selectivity
FROM dba_PART_histograms
WHERE 
    table_name = '&TABLE_NAME'
AND owner = '&OWNER'
AND column_name = '&COLUMN_NAME'
AND PARTITION_NAME = '&PART_NAME'
ORDER BY bucket_number;


prompt
prompt ==============================================================================================================




