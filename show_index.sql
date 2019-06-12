set echo off
clear screen


COLUMN tablespace_name FORMAT a20;
COLUMN table_name      FORMAT a30;
COLUMN COLUMN_name     FORMAT a20;
COLUMN index_name      FORMAT a30;
COLUMN Type            FORMAT a6;
COLUMN col_pos         FORMAT 99;
COLUMN BLVL            FORMAT 99;
COLUMN status          FORMAT A6;
column object_name FORMAT A30
column nullable format A10

define INDEX_NAME=&2
define OWNER=&1;


prompt
prompt
prompt
prompt
prompt ==============================================================================================================
prompt
prompt Index details for  : &INDEX_NAME for &OWNER
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
       blevel,
       leaf_blocks,
       distinct_keys
       clustering_factor,
       status,
       num_rows,
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
prompt DDL information for &INDEX_NAME
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
prompt Index Column information for : &INDEX_NAME for &OWNER
prompt



SELECT * 
from  dba_ind_COLUMNs 
where 
   index_owner = '&OWNER'
 and  index_name = '&INDEX_NAME'
order by  COLUMN_position ;

/*
SELECT T1.owner, t1.table_name, 
       t1.index_name, 
       t1.tablespace_name,  
       t1.index_type Type , 
       t2.COLUMN_position column_pos,
       t2.COLUMN_name, t1.status, 
       t1.blevel BLVL, t1.last_analyzed
from dba_indexes t1, dba_ind_COLUMNs t2
where t1.index_name = t2.index_name
AND T1.owner = upper('&OWNER')
AND T1.index_name = upper('&INDEX_NAME')
order by t1.table_name, t1.index_name, t2.COLUMN_position ;
*/

prompt
prompt checking for NULLABLE columns
prompt

SELECT IC.index_owner, IC.index_name, IC.table_name, IC.column_name, IC.column_position, nullable, num_nulls
from  dba_ind_COLUMNs IC
left outer join dba_tab_columns CC on CC.owner = IC.table_owner and CC.table_name = IC.table_name and CC.column_name = IC.column_name
where 
   index_owner = '&OWNER'
 and  index_name = '&INDEX_NAME'
and nullable = 'Y'
order by  COLUMN_position ;



prompt
prompt Index Stats for : &INDEX_NAME for &OWNER
prompt


select * 
FROM
  dba_ind_statistics
WHERE
     owner = upper('&OWNER')
AND index_name = upper('&INDEX_NAME')
and object_type = 'INDEX';



prompt
prompt ==================================================================================================================================================================
prompt Statistics history for : &INDEX_NAME
prompt ==================================================================================================================================================================
prompt


select * from
(
select owner, table_name, partition_name, subpartition_name, stats_update_time,
     row_number() over ( order by table_name, stats_update_time desc ) as table_rank
from dba_tab_stats_history
where table_name = upper('&INDEX_NAME')
AND owner = upper('&OWNER')
)
where table_rank < 50
order by stats_update_time;


prompt
prompt Actual blocks and size from dba_segments : &INDEX_NAME
prompt

SELECT owner, segment_name, bytes/(1024*1024) size_MB, blocks
 FROM DBA_segments
 WHERE  owner = upper('&OWNER') 
 and segment_name like upper('&INDEX_NAME');




prompt
prompt ==============================================================================================================
prompt
prompt




/*

column name format a15 
column blocks heading "ALLOCATED|BLOCKS" 
column lf_blks heading "LEAF|BLOCKS" 
column br_blks heading "BRANCH|BLOCKS" 
column Empty heading "UNUSED|BLOCKS" 
select name,        blocks,        lf_blks,        br_blks,        blocks-(lf_blks+br_blks) empty 
from   index_stats; 
*/

set echo on
