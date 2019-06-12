
clear screen

define OWNER=&1
define TABLE_NAME=&2
define PART_NAME=&3
define SUBPART_NAME=&4

define PART_LIMIT=1

prompt 
prompt
prompt ==================================================================================================================================================================
prompt 					SubPartition Report
prompt			
prompt 					for &OWNER/&TABLE_NAME
prompt
prompt ==================================================================================================================================================================
prompt
prompt
prompt




COLUMN SAMPLE_PCT FORMAT 999
column est_size_mb format 999,999,999,999.9
column partition_count format 999,999,999
column subpartition_count format 999,999,999
column partition_position format 999,999,999
column subpartition_position format 999,999,999
column leaf_blocks format 999,999,999

column low_v format A20
column hi_v format A20


prompt
prompt Subpartition information for table  : &TABLE_NAME, partition : &PART_NAME : subpartition : &SUBPART_NAME
prompt

WITH 
pivot1 AS
( SELECT VALUE AS block_size FROM v$parameter WHERE NAME = 'db_block_size' )
SELECT table_name,
       partition_name,
       subpartition_name,
       tablespace_name,
       pct_free,
       compression,
       compress_for,
       num_rows,
       blocks,
       blocks*(select block_size from pivot1)/(1024*1024) as est_size_mb,
       empty_blocks,
       chain_cnt,
       avg_row_len,
       ((select block_size from pivot1) - (select block_size from pivot1)*pct_free/100)/nullif(avg_row_len, 0) as  est_rows_per_block,
       last_analyzed,
       ini_trans,
       INTERVAL,
       high_value
FROM dba_tab_subpartitions
WHERE  table_name = upper('&TABLE_NAME')
AND table_owner = upper('&OWNER')
and partition_name = upper('&PART_NAME')
and subpartition_name = '&SUBPART_NAME';





prompt
prompt ==================================================================================================================================================================
prompt SubPartition Index information for &PART_NAME for &OWNER/&TABLE_NAME
prompt ==================================================================================================================================================================
prompt


SELECT 
    index_name   ,
     subpartition_name, 
     status, 
    tablespace_name, 
     subpartition_position,
compression,
blevel, leaf_blocks,
distinct_keys,
avg_data_blocks_per_key, clustering_factor, num_rows, sample_size, last_analyzed, global_stats, high_value
FROM dba_ind_subpartitions
WHERE
     index_owner = upper('&OWNER')
 and index_name in (select index_name from dba_indexes where table_name = upper('&TABLE_NAME') and table_owner = upper('&OWNER'))
and partition_name = upper('&PART_NAME')
and subpartition_name = '&SUBPART_NAME';


prompt ==================================================================================================================================================================
prompt stats report
prompt ==================================================================================================================================================================



prompt
prompt ==================================================================================================================================================================
prompt subpartition stats FOR &PART_NAME
prompt ==================================================================================================================================================================
prompt


select  A.table_name,  
         A.partition_name,
          A.num_rows, 
          A.last_analyzed last_anal,
          decode( A.num_rows,0,0,100*A.sample_size/A.num_rows)  sample_pct, 
        A.stale_stats,
        A.global_stats
from  dba_tab_statistics A 
where A.object_type = 'PARTITION'
AND  A.owner = upper('&OWNER') and A.table_name = UPPER('&TABLE_NAME')
and partition_NAME = '&PART_NAME'
order by partition_position;




prompt
prompt ==================================================================================================================================================================
prompt Sub-partition statistics 
prompt ==================================================================================================================================================================


select table_name, 
          partition_name,  
          partition_position,
          subpartition_name,
          subpartition_position,
          object_type,
          num_rows, 
          avg_row_len, 
          chain_cnt,
          last_analyzed last_anal,
          decode( num_rows,0,0,100*sample_size/num_rows) sample_pct, 
          sample_size,
        stale_stats, 
        dense_rank() over ( partition by table_name order by table_name, partition_position desc) as partition_rank
from dba_tab_statistics
where table_name like upper('&TABLE_NAME')
AND owner = upper('&OWNER')
and object_type in ( 'SUBPARTITION')
AND PARTITION_NAME = '&PART_NAME'
and subpartition_name = '&SUBPART_NAME'
order by table_name, partition_position, subpartition_position;


prompt
prompt ==================================================================================================================================================================
prompt Sub-partition column statistics 
prompt ==================================================================================================================================================================
prompt


select   B.TABLE_NAME, 
         B.PARTITION_NAME,
         B.subpartition_name,
       A.COLUMN_NAME ,
       A.NUM_DISTINCT, 
       A.DENSITY,
       A.NUM_NULLS, 
       B.LAST_ANALYZED, 
       B.sample_size*100/B.num_rows as sample_of_part_pct , 
       B.GLOBAL_STATS, 
       A.HISTOGRAM, 
       A.NUM_BUCKETS
FROM dba_tab_subpartitions B
inner join dba_subpart_col_statistics A on B.table_owner = A.owner and B.table_name = A.table_name and A.subpartition_name = B.subpartition_name
where B.table_name like upper('&TABLE_NAME')
AND B.TABLE_owner = upper('&OWNER')
AND B.PARTITION_NAME = '&PART_NAME'
and B.subpartition_name = '&SUBPART_NAME';




select B.TABLE_NAME, 
       B.SUBPARTITION_NAME,
       B.COLUMN_NAME ,
       B.NUM_DISTINCT, 
       B.DENSITY,
       B.NUM_NULLS, 
       B.LAST_ANALYZED, 
       B.GLOBAL_STATS, 
       B.HISTOGRAM, 
       B.NUM_BUCKETS,
      decode(C.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(B.low_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(B.low_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(B.low_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(B.low_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(B.low_value))  ,'DATE',to_char(1780+to_number(substr(B.low_value,1,2),'XX')         +to_number(substr(B.low_value,3,2),'XX'))||'-'       ||to_number(substr(B.low_value,5,2),'XX')||'-'       ||to_number(substr(B.low_value,7,2),'XX')||' '       ||(to_number(substr(B.low_value,9,2),'XX')-1)||':'       ||(to_number(substr(B.low_value,11,2),'XX')-1)||':'       ||(to_number(substr(B.low_value,13,2),'XX')-1),  B.low_value       ) low_v,
      decode(C.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(B.high_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(B.high_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(B.high_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(B.high_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(B.high_value))  ,'DATE',to_char(1780+to_number(substr(B.high_value,1,2),'XX')         +to_number(substr(B.high_value,3,2),'XX'))||'-'       ||to_number(substr(B.high_value,5,2),'XX')||'-'       ||to_number(substr(B.high_value,7,2),'XX')||' '       ||(to_number(substr(B.high_value,9,2),'XX')-1)||':'       ||(to_number(substr(B.high_value,11,2),'XX')-1)||':'       ||(to_number(substr(B.high_value,13,2),'XX')-1),  B.high_value       ) hi_v
from   dba_subpart_col_statistics B
INNER JOIN dba_tab_columns C on B.owner = C.owner AND B.table_name = C.table_name and C.column_name = B.column_name
WHERE b.owner = upper('&OWNER') and B.table_name = UPPER('&TABLE_NAME')
and B.subpartition_name = '&SUBPART_NAME';
order by B.table_name,  C.column_name;
	 




prompt
prompt ==================================================================================================================================================================
prompt HISTOGRAM column statistics 
prompt ==================================================================================================================================================================
prompt

/*
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
  WHERE PH.owner     = '&OWNER'
  AND PH.table_name  = '&TABLE_NAME'
  and PH.partition_NAME = '&PART_NAME'
--  AND PH.column_name = 'COLUMN_NAME'
 AND BUCKET_NUMBER = 1
  )
ORDER BY BUCKET_number;
*/



prompt
prompt basic histogram query on &PART_NAME :
prompt

/*
SELECT   table_name,
         partition_name,
         column_name,
         bucket_number,
         endpoint_value
FROM dba_part_histograms
WHERE table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER')
AND partition_NAME = '&PART_NAME';
*/

prompt
prompt ==================================================================================================================================================================
prompt Sub-partition  statistics 
prompt ==================================================================================================================================================================
prompt

prompt
prompt Sub Partition information for table  : &TABLE_NAME
prompt

WITH 
pivot1 AS    ( SELECT VALUE AS block_size FROM v$parameter WHERE NAME = 'db_block_size' )
, 
pivot2 AS
(
SELECT SP.table_name,
       SP.partition_name,
       SP.subpartition_name,
       SP.subpartition_position,
       SP.tablespace_name,
       SP.pct_free,
       SP.compression,
       SP.num_rows,
       SP.blocks,
       SP.blocks*(select block_size from pivot1)/(1024*1024) as est_size_mb,
       SP.empty_blocks,
       SP.chain_cnt,
       SP.avg_row_len,
       ((select block_size from pivot1) - (select block_size from pivot1)*SP.pct_free/100)/nullif(SP.avg_row_len, 0) as  est_rows_per_block,
       SP.last_analyzed,
       SP.INTERVAL,
       PP.partition_position,
         SP.high_value
FROM dba_tab_subpartitions SP
INNER JOIN dba_tab_partitions PP ON SP.table_owner = PP.table_owner and SP.table_name = PP.table_name and SP.partition_name =PP.partition_name
WHERE  SP.table_name = upper('&TABLE_NAME')
AND SP.table_owner = upper('&OWNER')
and SP.partition_NAME = '&PART_NAME'
and subpartition_name = '&SUBPART_NAME'
ORDER BY PP.partition_position
)
SELECT * FROM pivot2 ;





prompt
prompt ==================================================================================================================================================================
prompt Index Sub-partition statistics 
prompt ==================================================================================================================================================================
prompt
prompt
prompt



COLUMN sample_pct format 999


SELECT index_name, 
       table_name, 
       partition_name, 
       partition_position, 
       subpartition_name, 
       subpartition_position, 
       object_type,
          blevel, 
           distinct_keys, 
            CLUSTERING_FACTOR, 
    	      leaf_blocks,
    	      AVG_LEAF_BLOCKS_PER_KEY,
    	      AVG_DATA_BLOCKS_PER_KEY,
        num_rows, 
        decode(num_rows, 0, 0, 100*sample_size/num_rows ) sample_pct, 
        global_stats, 
        last_analyzed, 
        stale_stats,
      dense_rank() over ( partition by table_name order by table_name, partition_position desc) as partition_rank
FROM
  dba_ind_statistics
WHERE
     owner = upper('&OWNER')
and  table_name = upper('&TABLE_NAME')
and object_type in ( 'SUBPARTITION')
and partition_NAME = '&PART_NAME'
and subpartition_name = '&SUBPART_NAME'
ORDER BY INDEX_NAME, partition_position, subpartition_position;



prompt
prompt ==================================================================================================================================================================
prompt End of Stats report for &TABLE_NAME
prompt ==================================================================================================================================================================

