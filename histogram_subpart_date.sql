define OWNER=&1
define TABLE_NAME=&2
define SUBPART_NAME=&3
define COLUMN_NAME=&4



column estimated_selectivity format 0.9999999999;
column density format 99999.999999999;
COLUMN COLUMN_NAME FORMAT a30
COLUMN BUCKET_NUMBER FORMAT 999999
column endpoint_value format 999999999999999999999999999999999999
column DATE_VALUE format A30


prompt 
prompt Histograms for &COLUMN_NAME subpartition  &SUBPART_NAME)
prompt


select bucket_number,
        TO_DATE(TRUNC(endpoint_value),'J')+(ENDPOINT_VALUE-TRUNC(ENDPOINT_VALUE)) DATE_VALUE ,
	bucket_number - lag(bucket_number,1,0) OVER (ORDER BY bucket_number) AS frequency
FROM dba_subPART_histograms
WHERE 
    table_name = '&TABLE_NAME'
AND owner = '&OWNER'
AND column_name = '&COLUMN_NAME'
AND SUBPARTITION_NAME = '&SUBPART_NAME'
ORDER BY bucket_number;

