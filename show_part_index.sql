


COLUMN tablespace_name FORMAT a20;
COLUMN table_name      FORMAT a20;
COLUMN COLUMN_name     FORMAT a20;
COLUMN index_name      FORMAT a20;
COLUMN partition_name      FORMAT a20;
COLUMN Type            FORMAT a6;
COLUMN col_pos         FORMAT 99;
COLUMN BLVL            FORMAT 99;
COLUMN status          FORMAT A6;
COLUMN interval        FORMAT A100;
column num_rows        FORMAT 999,999,999,999;
column object_name FORMAT A30
column high_value format A20
column stale_stats format A10
column clustering_factor format 999,999,999,999
column partition_position format 999,999
column subpartition_position format 999,999
column leaf_blocks format 999,999
column AVG_LEAF_BLOCKS_PER_KEY format 999,999,999
column AVG_DATA_BLOCKS_PER_KEY format 999,999,999
column partition_rank format 999
column composite format A10
column last_analyzed format A21
column global_stats format A10
column distinct_keys format 999,999,999
column segment_created format A15
COLUMN DISTINCT_KEYS FORMAT 999,999,999,999,999
COLUMN sample_pct format 999


column partition_rank format 999
COLUMN SAMPLE_PCT FORMAT 999
column est_size_mb format 999,999,999,999.9
column est_rows_per_block format 999,999,999.9
column sample_size_pct format 99.9
column cardinality format 999,999,999,999
column low_v format A20
column hi_v format A20
column nullable format A10

col p1 new_value 1
col p2 new_value 2
col p3 new_value 3
select null p1, null p2, null p3 from dual where 1=2;
select nvl( '&1','&_USER') p1, nvl('&2','YY') p2, nvl('&3', '20') p3 from dual ;


define OWNER=&1
define INDEX_NAME=&2     





prompt
prompt
prompt
prompt
prompt ==================================================================================================================================================================
prompt Index detail for : &INDEX_NAME for &OWNER
prompt ==================================================================================================================================================================
prompt

prompt 


SELECT owner,
       index_name,
       index_type,
       table_owner,
       table_name,
       table_type,
       uniqueness,
       compression,
       tablespace_name,
       pct_free,
       num_rows,
       status,
       sample_size,
       last_analyzed,
       degree,
       partitioned,
       ini_trans,
       dropped,
       visibility,
       segment_created
FROM
  dba_indexes
WHERE
    owner = upper('&OWNER')
AND index_name = upper('&INDEX_NAME');


prompt
prompt ==================================================================================================================================================================
prompt DDL information for : &INDEX_NAME for &OWNER
prompt ==================================================================================================================================================================
prompt

select owner,
       object_name,
       created,
       last_ddl_time
from dba_objects
WHERE   owner = upper('&OWNER')
AND object_name = upper('&INDEX_NAME')
and object_type = 'INDEX';


prompt
prompt ==================================================================================================================================================================
prompt Index Column information for : &INDEX_NAME for &OWNER
prompt ==================================================================================================================================================================
prompt



SELECT * 
from  dba_ind_COLUMNs 
where 
   index_owner = upper('&OWNER')
 and  index_name = upper('&INDEX_NAME')
order by  COLUMN_position ;


prompt
prompt checking for NULLABLE columns
prompt

SELECT IC.index_owner, IC.index_name, IC.table_name, IC.column_name, IC.column_position, nullable , num_nulls
from  dba_ind_COLUMNs IC
left outer join dba_tab_columns CC on CC.owner = IC.table_owner and CC.table_name = IC.table_name and CC.column_name = IC.column_name
where 
   index_owner = '&OWNER'
 and  index_name = '&INDEX_NAME'
and nullable = 'Y'
order by  COLUMN_position ;


prompt
prompt ==================================================================================================================================================================
prompt Partition Index information for &INDEX_NAME for &OWNER
prompt ==================================================================================================================================================================
prompt


SELECT 
    index_name   ,
    table_name         ,
     partitioning_type , 
     subpartitioning_type    ,
     partition_count,
     locality,
     alignment,
     def_pct_free,
     def_tablespace_name,
     def_buffer_pool,
     interval
FROM dba_part_indexes
WHERE
     owner = upper('&OWNER')
AND index_name = upper('&INDEX_NAME');



prompt
prompt Partitioning key columns for : &INDEX_NAME for &OWNER
prompt 

SELECT owner, NAME, column_name, column_position 
FROM dba_part_key_columns
WHERE
     owner = upper('&OWNER')
AND name = upper('&INDEX_NAME');


prompt
prompt ==================================================================================================================================================================
prompt Partition segment info for  : &INDEX_NAME for &OWNER
prompt ==================================================================================================================================================================
prompt


SELECT T1.index_owner,
       T1.index_name, 
       T1.composite,
       T1.partition_name,
       T1.subpartition_count,
       T1.high_value,
       T1.partition_position,
       T1.status,
       T1.tablespace_name,
       T1.segment_created,    
       T1.pct_free,
       T1.ini_trans,
       T1.compression,
       T1.num_rows,
       T1.last_analyzed,
       T1.buffer_pool,
       T1.global_stats,
       T1.interval
FROM dba_ind_partitions T1
inner join dba_objects DO on DO.owner = T1.INDEX_owner and DO.object_name =T1.index_name AND DO.subobject_name = T1.partition_name
where  T1.INDEX_owner = '&OWNER'
AND   T1.index_name like  upper('&INDEX_NAME')
and    DO.object_type = 'INDEX PARTITION'
and    DO.created > trunc(sysdate) - &DAYS_AGO
ORDER BY partition_position;







prompt
prompt ==================================================================================================================================================================
prompt  Global Index statistics
prompt ==================================================================================================================================================================
prompt 



select  index_name, 
       table_name, 
       object_type,
       blevel, leaf_blocks, 
       distinct_keys, 
        CLUSTERING_FACTOR, 
        num_rows, 
        decode(num_rows, 0, 0, 100*sample_size/num_rows ) sample_pct, 
        global_stats, 
        last_analyzed, 
        stale_stats
from dba_ind_statistics A
where A.owner = upper('&OWNER')
and  A.INDEX_name like upper('&INDEX_NAME')
AND PARTITION_NAME IS NULL;


prompt
prompt ==================================================================================================================================================================
prompt Partition statistics 
prompt ==================================================================================================================================================================
prompt
prompt Partition and Subpartition Index Stats for : &INDEX_NAME for &OWNER
prompt
prompt
prompt

prompt



SELECT index_name, 
       table_name, 
       partition_name, 
       partition_position, 
       T1.object_type,
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
        stale_stats
FROM
  dba_ind_statistics T1
inner join dba_objects DO on DO.owner = T1.table_owner and DO.object_name = T1.table_name AND DO.subobject_name = T1.partition_name
where  T1.table_owner = '&OWNER'
AND   T1.index_name like '&INDEX_NAME'
and   T1.object_type = 'PARTITION'
and    DO.object_type = 'INDEX PARTITION'
and    DO.created > trunc(sysdate) - &DAYS_AGO
ORDER BY partition_position;



prompt
prompt ==================================================================================================================================================================
prompt Sub-partition statistics 
prompt ==================================================================================================================================================================
prompt
prompt Subpartition Index Stats for : &INDEX_NAME for &OWNER
prompt
prompt Showing the most recent &PART_LIMIT sub-partitions
prompt
prompt





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
  dba_ind_statistics T1
inner join dba_objects DO on DO.owner = T1.table_owner and DO.object_name = T1.table_name AND DO.subobject_name = T1.partition_name
where  T1.table_owner = '&OWNER'
AND   T1.index_name like '&INDEX_NAME'
and   T1.object_type = 'SUBPARTITION'
and    DO.object_type = 'INDEX SUBPARTITION'
and    DO.created > trunc(sysdate) - &DAYS_AGO
ORDER BY partition_position, subpartition_position;



/*

column name format a15 
column blocks heading "ALLOCATED|BLOCKS" 
column lf_blks heading "LEAF|BLOCKS" 
column br_blks heading "BRANCH|BLOCKS" 
column Empty heading "UNUSED|BLOCKS" 
select name,        blocks,        lf_blks,        br_blks,        blocks-(lf_blks+br_blks) empty 
from   index_stats; 
*/















