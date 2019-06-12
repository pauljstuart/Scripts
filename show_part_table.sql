



column partition_rank format 999
COLUMN SAMPLE_PCT FORMAT 999
column est_size_mb format 999,999,999,999.9
column est_rows_per_block format 999,999,999.9
column sample_size_pct format 99.9
column cardinality format 999,999,999,999
column low_v format A20
column hi_v format A20


col OWNER1 new_value 1
col TABLE_NAME1 new_value 2
col P3 new_value 3
select null OWNER1, null TABLE_NAME1, null P3 from dual where 1=2;
select nvl( '&1','_USER') OWNER1, nvl('&2','%') TABLE_NAME1, nvl('&3', '20') p3 from dual ;


define OWNER=&1
define TABLE_NAME=&2     
define PART_LIMIT=&3


undefine 1
undefine 2
undefine 3


PROMPT => show_part_table_&OWNER..&TABLE_NAME..sql

set echo off
set termout off
set wrap off

spool show_part_table_&OWNER..&TABLE_NAME..sql

prompt
prompt
prompt ===================================================================================================================================================================
prompt
prompt USER : &OWNER
prompt TABLE : &TABLE_NAME
prompt
prompt ==================================================================================================================================================================
prompt

prompt 
prompt general info from dba_tables :
prompt

WITH 
pivot1 AS
      ( SELECT VALUE AS block_size FROM v$parameter WHERE NAME = 'db_block_size' ), 
pivot2 as 
	(select num_rows from dba_tables where table_name = upper('&TABLE_NAME') AND owner = upper('&OWNER') )
select degree, 
       tablespace_name, 
       partitioned, 
      num_rows,  
      blocks, 
      pct_free , 
       blocks*(select block_size from pivot1)/(1024*1024) as est_size_mb,
       empty_blocks,
       chain_cnt,
       avg_row_len,
       ((select block_size from pivot1) - (select block_size from pivot1)*pct_free/100)/nullif(avg_row_len, 0) as  est_rows_per_block,
       sample_size*100/(select nullif(num_rows, 0) from pivot2) as sample_size_pct,
       sample_size,  
       last_analyzed,
      compression, 
      compress_for, 
      row_movement,
      ini_TRANS,
      read_only
from dba_tables
where table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER');


prompt
prompt DDL information :
prompt

select owner,
       object_name,
       created,
       last_ddl_time,
       object_type
from dba_objects
where     owner = '&OWNER'
AND object_name = '&TABLE_NAME'
and object_type = 'TABLE'
;

prompt
prompt Partitioning Info :
prompt


select table_name,
        partitioning_type,
        subpartitioning_type,
        partition_count,
        partitioning_key_count,
        subpartitioning_key_count,
        def_tablespace_name,
        def_compression,
        DEF_INI_TRANS,
        interval
from dba_part_tables
where table_name = '&TABLE_NAME'
AND owner = '&OWNER';

prompt
prompt Partition Key columns
prompt

column partition_keys format A30

SELECT dpkc.owner, dpkc.name, dpkc.column_name as partition_keys, data_type
FROM dba_PART_KEY_COLUMNS DPKC
inner join dba_tab_cols DTC on DTC.owner = DPKC.owner and DTC.table_name = dPKC.name and dpkc.column_name = dtc.column_name
WHERE dpkc.owner LIKE upper('&OWNER')
AND dpkc.name LIKE upper('&TABLE_NAME')
AND dpkc.object_type = 'TABLE';


prompt
prompt Sub partition Key columns
prompt


SELECT dpkc.owner, dpkc.name, dpkc.column_name as partition_keys, data_type
FROM dba_subPART_KEY_COLUMNS DPKC
inner join dba_tab_cols DTC on DTC.owner = DPKC.owner and DTC.table_name = dPKC.name and dpkc.column_name = dtc.column_name
WHERE dpkc.owner LIKE upper('&OWNER')
AND dpkc.name LIKE upper('&TABLE_NAME')
AND dpkc.object_type = 'TABLE';




prompt
prompt Columns for table (dba_tab_columns) : &TABLE_NAME
prompt

column data_default format A15
column data_length format 999,999
column data_type format A10
column nullable format A10

SELECT 
   owner, 
   table_name,
   column_name,
   column_id,
   data_type,
   data_length,
   data_precision,
   data_scale,
   nullable,
   default_length,
   data_default,
   char_length,
   char_used
   FROM dba_tab_cols
WHERE 
    table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER')
order by column_id;

-- AND COLUMN_name = '&COL_NAME';

SELECT  count(1)  number_of_columns
   FROM dba_tab_columns
WHERE 
    table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER');


prompt
prompt hidden columns 
prompt

select table_name, column_name
from dba_tab_cols T1
where owner = '&OWNER'
and table_name = '&TABLE_NAME'
and  not exists (select 1 from dba_tab_columns T2 where owner = '&OWNER' and table_name = '&TABLE_NAME' and T1.column_name = T2.column_name );


PROMPT
PROMPT Count of Partition and Subpartitions :
prompt

select count(1) as Number_of_partitions
FROM dba_tab_partitions
WHERE  table_name = upper('&TABLE_NAME')
AND table_owner = upper('&OWNER');


select count(1) as Number_of_subpartitions
FROM dba_tab_subpartitions
WHERE  table_name = upper('&TABLE_NAME')
AND table_owner = upper('&OWNER');


prompt
prompt Non-Partioned Indexes for table : &TABLE_NAME
prompt

SELECT T1.table_name, t1.index_name,
       T1.uniqueness, 
       t1.tablespace_name,  
       T1.index_type type , 
       T2.COLUMN_position ,
       T2.COLUMN_name, 
       t1.status, 
       T1.blevel , 
       T1.pct_free,
       T1.clustering_factor,
       T1.partitioned, 
       T1.last_analyzed
FROM dba_indexes T1
INNER JOIN dba_ind_COLUMNs T2 ON T2.table_owner = T1.owner and T2.table_name = T1.table_name
WHERE t1.index_name = t2.index_name
AND t1.owner = upper('&OWNER')
AND t1.table_name = upper('&TABLE_NAME')
and t1.partitioned = 'NO'
ORDER BY t1.table_name, t1.index_name, t2.column_position ;    



prompt
prompt Partitioned Indexes for table : &TABLE_NAME
prompt
prompt 

SELECT T1.table_name, 
         T1.index_name,
         T1.partitioning_type,
         T1.subpartitioning_type,
         T1.partition_count,
         T1.locality,
         T1.alignment,
         T1.def_tablespace_name, 
         T1.def_pct_free,
         T2.column_position ,
	 T2.column_name
FROM dba_part_indexes T1
INNER JOIN dba_ind_COLUMNs T2 ON T2.table_owner = T1.owner and T2.table_name = T1.table_name
WHERE t1.index_name = t2.index_name
AND t1.owner = upper('&OWNER')
AND t1.table_name = upper('&TABLE_NAME')
ORDER BY t1.table_name, t1.index_name, t2.column_position ;    	 
	 

prompt ======
prompt ======
prompt =====

SELECT T1.table_name, t1.index_name,
       T1.uniqueness, 
       t1.tablespace_name,  
       T1.index_type type , 
       T2.COLUMN_position ,
       T2.COLUMN_name, 
       t1.status, 
       T1.blevel BLVL, 
       T1.pct_free,
       T1.clustering_factor,
       T1.partitioned, 
       T1.last_analyzed
FROM dba_indexes T1
INNER JOIN dba_ind_COLUMNs T2 ON T2.table_owner = T1.owner and T2.table_name = T1.table_name
WHERE t1.index_name = t2.index_name
AND t1.owner = upper('&OWNER')
AND t1.table_name = upper('&TABLE_NAME')
and t1.partitioned = 'YES'
ORDER BY t1.table_name, t1.index_name, t2.column_position ;  

prompt 
prompt Constraints for table : &TABLE_NAME
prompt 
prompt 

SELECT *
FROM dba_constraints
WHERE table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER'); 


prompt 
prompt Triggers for table : &TABLE_NAME
prompt 

COLUMN TRIGGERING_EVENT FORMAT a30

select TABLE_NAME, TRIGGER_NAME, TRIGGER_TYPE, TRIGGERING_EVENT, STATUS
from dba_triggers
WHERE table_name = upper('&TABLE_NAME')
AND table_owner = upper('&OWNER');   


DEFINE PART_NAME=%
DEFINE SUBPART_NAME=%

prompt
prompt partition information, &DAYS_AGO days ago 
prompt

SELECT table_name,
       partition_name,
       partition_position,
       subpartition_count,
       composite,
       tablespace_name,
       pct_free,
       compression,
       compress_for,
       num_rows,
       last_analyzed,
       created,
       INTERVAL,
       high_value
FROM dba_tab_partitions DT
inner join dba_objects DO on DO.owner = DT.table_owner and DO.object_name = DT.table_name AND DO.subobject_name = DT.partition_name
where  DT.table_owner = '&OWNER'
and    DT.table_name = '&TABLE_NAME'
and    DT.partition_name like '&PART_NAME'
and    DO.object_type = 'TABLE PARTITION'
and    DO.created > trunc(sysdate) - &DAYS_AGO
ORDER BY partition_position;


PROMPT
PROMPT subpartition information,  &DAYS_AGO days ago 
prompt


SELECT table_name,
       partition_name,
       subpartition_name,
       subpartition_position,
       tablespace_name,
       pct_free,
       compression,
       compress_for,
       num_rows,
       last_analyzed,
       created,
       INTERVAL,
       high_value
FROM dba_tab_subpartitions DT
inner join dba_objects DO on DO.owner = DT.table_owner and DO.object_name = DT.table_name AND DO.subobject_name = DT.subpartition_name
where  table_owner = '&OWNER'
and    table_name = '&TABLE_NAME'
and    subpartition_name like '&SUBPART_NAME'
and   DO.object_type = 'TABLE SUBPARTITION'
and DO.created > trunc(sysdate) - &DAYS_AGO
ORDER BY PARTITION_NAME, subpartition_position;



prompt
prompt Actual Blocks and size from dba_segments : &TABLE_NAME
prompt

COLUMN AVG_MB FORMAT 999,999,999,999
COLUMN SIZE_MB FORMAT 999,999,999,999,999

/*
SELECT owner, segment_name, SEGMENT_TYPE, Sum(bytes)/(1024*1024) size_MB, AVG(BYTES)/(1024*1024) AVG_MB
 FROM DBA_segments
 WHERE  owner = upper('&OWNER') 
 and segment_name IN (SELECT INDEX_NAME FROM DBA_INDEXES WHERE TABLE_NAME = upper('&TABLE_NAME') AND OWNER = upper('&OWNER'))
group by owner, segment_name, SEGMENT_TYPE
union
SELECT owner, segment_name, SEGMENT_TYPE, Sum(bytes)/(1024*1024) size_MB, AVG(BYTES)/(1024*1024) AVG_MB
 FROM DBA_segments
 WHERE  owner = upper('&OWNER') 
 and segment_name = upper('&TABLE_NAME') 
group by owner, segment_name, SEGMENT_TYPE;
*/


prompt 
prompt
prompt ==================================================================================================================================================================
prompt 					Table Statistics Report
prompt			
prompt 					for &OWNER/&TABLE_NAME
prompt
prompt ==================================================================================================================================================================
prompt
prompt
prompt



prompt
prompt ==================================================================================================================================================================
prompt global statistics preferences :
prompt ==================================================================================================================================================================
prompt 

column global_value format A40

 SELECT 'stale_pct' as parameter, dbms_stats.get_prefs('STALE_PERCENT') as global_value FROM dual
union
 SELECT 'autostats_target', dbms_stats.get_prefs( 'AUTOSTATS_TARGET' )  FROM dual
union
 SELECT 'cascasde',  dbms_stats.get_prefs( 'CASCADE' ) cascade FROM dual
union
 select 'degree' ,dbms_stats.get_prefs( 'DEGREE' ) degree from dual
union
 select 'estimate_percent',dbms_stats.get_prefs('ESTIMATE_PERCENT' ) estimate_percent from dual
union
 select 'method_opt', dbms_stats.get_prefs('METHOD_OPT') method_opt from dual
union
 select 'no_invalidate', dbms_stats.get_prefs('NO_INVALIDATE' ) no_invalidate from dual
union
 select 'granularity', dbms_stats.get_prefs('GRANULARITY' ) granularity from dual
union
 select 'publish', dbms_stats.get_prefs('PUBLISH') publish from dual
union
 select 'incremental', dbms_stats.get_prefs('INCREMENTAL') incremental from dual;



prompt
prompt ==================================================================================================================================================================
prompt Table stats preferences for &OWNER/&TABLE_NAME
prompt ==================================================================================================================================================================
prompt 

column value format A40

 SELECT 'stale_pct' as parameter, dbms_stats.get_prefs('STALE_PERCENT', '&OWNER', '&TABLE_NAME') as value FROM dual
union
 SELECT 'autostats_target', dbms_stats.get_prefs( 'AUTOSTATS_TARGET' , '&OWNER', '&TABLE_NAME')  FROM dual
union
 SELECT 'cascasde',  dbms_stats.get_prefs( 'CASCADE' , '&OWNER', '&TABLE_NAME') cascade FROM dual
union
 select 'degree' ,dbms_stats.get_prefs( 'DEGREE' , '&OWNER', '&TABLE_NAME') degree from dual
union
 select 'estimate_percent',dbms_stats.get_prefs('ESTIMATE_PERCENT' , '&OWNER', '&TABLE_NAME') estimate_percent from dual
union
 select 'method_opt', dbms_stats.get_prefs('METHOD_OPT', '&OWNER', '&TABLE_NAME') method_opt from dual
union
 select 'no_invalidate', dbms_stats.get_prefs('NO_INVALIDATE' , '&OWNER', '&TABLE_NAME') no_invalidate from dual
union
 select 'granularity', dbms_stats.get_prefs('GRANULARITY' , '&OWNER', '&TABLE_NAME') granularity from dual
union
 select 'publish', dbms_stats.get_prefs('PUBLISH', '&OWNER', '&TABLE_NAME') publish from dual
union
 select 'incremental', dbms_stats.get_prefs('INCREMENTAL', '&OWNER', '&TABLE_NAME') incremental from dual;

COLUMN PREFERENCE_VALUE FORMAT A10

 SELECT table_name, preference_name, preference_value
 FROM dba_tab_stat_prefs
 WHERE owner = '&OWNER'
 AND table_name IN ('&TABLE_NAME')
 ORDER BY table_name, preference_name;

prompt
prompt ==================================================================================================================================================================
prompt Statistics history for : &TABLE_NAME
prompt ==================================================================================================================================================================
prompt


column duration_mins format 999,999.9
column STATS_UPDATE_TIME format A21
column target format A50
column start_time format A19
COLUMN ANALYZETIME FORMAT a21


prompt
prompt _opstat_tab_history :
prompt

select OBJECT_NAME AS TABLE_NAME, SUBOBJECT_NAME AS PARTITION_NAME, obj#, analyzetime,  rowcnt as NUM_ROWS, samplesize
from sys.wri$_optstat_tab_history W
INNER JOIN DBA_OBJECTS DO on DO.object_id = W.obj#
and DO.object_name = '&TABLE_NAME' 
and DO.owner = '&OWNER' 
--and DO.subobject_name = 'CM_R_20170925'
and  analyzetime > trunc(sysdate) - &DAYS_AGO
 order by analyzetime ; 



prompt
prompt : dba_tab_stats_history  :
promp

select owner, table_name, partition_name, subpartition_name, stats_update_time
from dba_tab_stats_history
where table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER')
AND stats_update_time > trunc(sysdate) - &DAYS_AGO
order by stats_update_time;

prompt
prompt : dba_opstat_operations :
prompt

SELECT operation, target, start_time, ( cast(end_time as DATE) - cast(start_time as DATE) ) * 24*60  as etime_mins
 FROM dba_optstat_operations
where start_time > TRUNC(sysdate) - &DAYS_AGO
AND TARGET LIKE '' || UPPER('&OWNER') || '.' || UPPER('&TABLE_NAME')  || ''
ORDER BY start_time ;


prompt
prompt ==================================================================================================================================================================
prompt  Global Table stats :
prompt ==================================================================================================================================================================
prompt 


select  A.table_name,  
          A.num_rows, 
          A.last_analyzed last_anal,
          round( decode( A.num_rows,0,0,100*A.sample_size/A.num_rows), 2)  sample_pct, 
        A.stale_stats,
        STATTYPE_LOCKED, 
        B.partitioned,
        B.global_stats
from dba_tab_statistics A
inner join dba_tables B on A.owner = b.owner and A.table_name = B.table_name
where A.owner = upper('&OWNER')
and  A.table_name like upper('&TABLE_NAME')
and A.partition_name is NULL;



prompt
prompt ==================================================================================================================================================================
prompt Global column stats 
prompt ==================================================================================================================================================================
prompt




WITH 
pivot1 AS
( SELECT num_rows
from dba_tables
where table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER')
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
    decode(A.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(B.low_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(B.low_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(B.low_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(B.low_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(B.low_value))  ,'DATE',to_char(1780+to_number(substr(B.low_value,1,2),'XX')         +to_number(substr(B.low_value,3,2),'XX'))||'-'       ||to_number(substr(B.low_value,5,2),'XX')||'-'       ||to_number(substr(B.low_value,7,2),'XX')||' '       ||(to_number(substr(B.low_value,9,2),'XX')-1)||':'       ||(to_number(substr(B.low_value,11,2),'XX')-1)||':'       ||(to_number(substr(B.low_value,13,2),'XX')-1),  B.low_value       ) low_v,
    decode(A.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(B.high_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(B.high_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(B.high_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(B.high_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(B.high_value))  ,'DATE',to_char(1780+to_number(substr(B.high_value,1,2),'XX')         +to_number(substr(B.high_value,3,2),'XX'))||'-'       ||to_number(substr(B.high_value,5,2),'XX')||'-'       ||to_number(substr(B.high_value,7,2),'XX')||' '       ||(to_number(substr(B.high_value,9,2),'XX')-1)||':'       ||(to_number(substr(B.high_value,11,2),'XX')-1)||':'       ||(to_number(substr(B.high_value,13,2),'XX')-1),  B.high_value       ) hi_v
FROM dba_tab_columns  A
left outer join dba_tab_col_statistics  B on A.owner = B.owner AND A.table_name = B.table_name and A.column_name = B.column_name
WHERE A.table_name = upper('&TABLE_NAME')
AND A.owner = upper('&OWNER')
ORDER BY A.COLUMN_name;

prompt
prompt ==================================================================================================================================================================
prompt partition stats
prompt ==================================================================================================================================================================
prompt


prompt
prompt Showing the partitions created &DAYS_AGO days ago
prompt



select  table_name,  
        partition_name,
        partition_position, 
        num_rows, 
        last_analyzed ,
        blocks,
        empty_blocks,
        blocks*(select value from v$parameter where name = 'db_block_size')/(1024*1024) size_mb,
        decode( num_rows,0,0,100*sample_size/num_rows)  sample_pct, 
        stale_stats,
        global_stats,  
        created
from  dba_tab_statistics DTS 
inner join dba_objects DO on DO.owner = DTS.owner and DO.object_name = DTS.table_name AND DO.subobject_name = DTS.partition_name
where DTS.object_type = 'PARTITION'
and  DO.object_type = 'TABLE PARTITION'
and DTS.owner = '&OWNER'
and DTS.table_name = '&TABLE_NAME'
and trunc(created) > sysdate - &DAYS_AGO
ORDER BY partition_position;



/*
with pivot2 as
(
select  A.table_name,  A.partition_name,
          A.num_rows, 
          A.last_analyzed last_anal,
          round( decode( A.num_rows,0,0,100*A.sample_size/A.num_rows), 2)  sample_pct, 
        A.stale_stats,
        A.global_stats,
        dense_rank() over ( partition by table_name order by table_name, partition_position desc) as partition_rank
from dba_tab_statistics A
--inner join dba_tab_partitions B on A.owner = b.table_owner and A.table_name = B.table_name
where A.owner = upper('&OWNER')
and  A.table_name like upper('&TABLE_NAME')
and A.object_type = 'PARTITION'
order by table_name, partition_position
)
SELECT * FROM pivot2 
WHERE partition_rank < &PART_LIMIT;

*/


/*
prompt
prompt ==================================================================================================================================================================
prompt partition column stats
prompt ==================================================================================================================================================================
prompt


      
prompt
prompt Showing the most recent &PART_LIMIT partitions
prompt


with pivot1 as 
(
  select table_owner, table_name, partition_name, num_rows
  from dba_tab_partitions
  where partition_position > (select max(partition_position) from dba_tab_partitions
                              where  table_owner = upper('&OWNER') and   table_name = upper('&TABLE_NAME') )
                            - &PART_LIMIT
  and table_owner = upper('&OWNER')  and   table_name = upper('&TABLE_NAME') 
)
select A.TABLE_NAME, 
       A.PARTITION_NAME,
       B.COLUMN_NAME ,
       B.NUM_DISTINCT, 
       B.DENSITY,
       B.NUM_NULLS, 
       B.LAST_ANALYZED, 
       decode( A.num_rows, 0, 0, 100*B.sample_size/A.num_rows) sample_pct,
       B.GLOBAL_STATS, 
       B.HISTOGRAM, 
       B.NUM_BUCKETS,
      decode(C.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(B.low_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(B.low_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(B.low_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(B.low_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(B.low_value))  ,'DATE',to_char(1780+to_number(substr(B.low_value,1,2),'XX')         +to_number(substr(B.low_value,3,2),'XX'))||'-'       ||to_number(substr(B.low_value,5,2),'XX')||'-'       ||to_number(substr(B.low_value,7,2),'XX')||' '       ||(to_number(substr(B.low_value,9,2),'XX')-1)||':'       ||(to_number(substr(B.low_value,11,2),'XX')-1)||':'       ||(to_number(substr(B.low_value,13,2),'XX')-1),  B.low_value       ) low_v,
      decode(C.data_type  ,'NUMBER'       ,to_char(utl_raw.cast_to_number(B.high_value))  ,'VARCHAR2'     ,to_char(utl_raw.cast_to_varchar2(B.high_value))  ,'NVARCHAR2'    ,to_char(utl_raw.cast_to_nvarchar2(B.high_value))  ,'BINARY_DOUBLE',to_char(utl_raw.cast_to_binary_double(B.high_value))  ,'BINARY_FLOAT' ,to_char(utl_raw.cast_to_binary_float(B.high_value))  ,'DATE',to_char(1780+to_number(substr(B.high_value,1,2),'XX')         +to_number(substr(B.high_value,3,2),'XX'))||'-'       ||to_number(substr(B.high_value,5,2),'XX')||'-'       ||to_number(substr(B.high_value,7,2),'XX')||' '       ||(to_number(substr(B.high_value,9,2),'XX')-1)||':'       ||(to_number(substr(B.high_value,11,2),'XX')-1)||':'       ||(to_number(substr(B.high_value,13,2),'XX')-1),  B.high_value       ) hi_v
from  pivot1  A
inner join dba_part_col_statistics B on A.table_owner = B.owner and A.table_name = B.table_name and A.partition_name = B.partition_name
INNER JOIN dba_tab_columns C on A.table_owner = C.owner AND A.table_name = C.table_name and C.column_name = B.column_name
order by A.table_name, A.partition_name, B.column_name;


*/

prompt
prompt ==================================================================================================================================================================
prompt Partitions missing column statistics 
prompt ==================================================================================================================================================================


with pivot1 as 
(
  select table_owner, table_name, partition_name, num_rows
  from dba_tab_partitions
  where partition_position > (select max(partition_position) from dba_tab_partitions
                              where  table_owner = upper('&OWNER') and   table_name = upper('&TABLE_NAME') )
                            - &PART_LIMIT
  and table_owner = upper('&OWNER')  and   table_name = upper('&TABLE_NAME') 
)
SELECT A.table_owner, A.table_name, A.partition_name, count(column_name) num_columns, count(last_analyzed), count(column_name) - count(last_analyzed) columns_missing_stats
FROM 
pivot1 A
inner join dba_part_col_statistics D on A.table_owner = D.owner and A.table_name = D.table_name and A.partition_name = D.partition_name
group by A.table_owner, A.table_name, A.partition_name
having count(column_name) - count(last_analyzed) > 0;

prompt
prompt ==================================================================================================================================================================
prompt Sub-partition statistics 
prompt ==================================================================================================================================================================

prompt
prompt Showing the most recent &DAYS_AGO days ago subpartitions
prompt


select  table_name,  
        partition_name,
        partition_position,         
        subpartition_name,
        subpartition_position, 
        num_rows, 
        last_analyzed ,
        blocks,
        empty_blocks,
        blocks*(select value from v$parameter where name = 'db_block_size')/(1024*1024) size_mb,
        decode( num_rows,0,0,100*sample_size/num_rows)  sample_pct, 
        stale_stats,
        global_stats,  
        created
from  dba_tab_statistics DTS 
inner join dba_objects DO on DO.owner = DTS.owner and DO.object_name = DTS.table_name AND DO.subobject_name = DTS.subpartition_name
where DTS.object_type = 'SUBPARTITION'
and  DO.object_type = 'TABLE SUBPARTITION'
and DTS.owner = '&OWNER'
and DTS.table_name = '&TABLE_NAME'
and trunc(created) > sysdate - &DAYS_AGO
ORDER BY partition_position,subpartition_position;





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
and  A.table_name = upper('&TABLE_NAME')
AND PARTITION_NAME IS NULL;


prompt
prompt ==================================================================================================================================================================
prompt Index Partition statistics 
prompt ==================================================================================================================================================================
prompt
prompt

SELECT /*+ FULL(DO) LEADING(DO) USE_HASH(DTS) USE_HASH(DO)  */ index_name, 
       table_name, 
       partition_name, 
       partition_position, 
       DTS.object_type,
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
  dba_ind_statistics DTS
inner join dba_objects DO on DO.owner = DTS.owner and DO.object_name = DTS.index_name AND DO.subobject_name = DTS.partition_name
and DTS.owner = '&OWNER'
and DTS.table_name = '&TABLE_NAME'
AND DTS.object_type = 'PARTITION'
and  DO.object_type = 'PARTITION'
AND DO.owner = '&OWNER'
and trunc(created) > sysdate - &DAYS_AGO
ORDER BY INDEX_NAME, partition_position, subpartition_position;

prompt
prompt ==================================================================================================================================================================
prompt Index Sub-partition statistics 
prompt ==================================================================================================================================================================
prompt
prompt
prompt



SELECT /*+ leading(DO) */ index_name, 
       table_name, 
       partition_name, 
       partition_position, 
       subpartition_name, 
       subpartition_position, 
       DTS.object_type,
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
  dba_ind_statistics DTS
inner join dba_objects DO on DO.owner = DTS.owner and DO.object_name = DTS.index_name AND DO.subobject_name = DTS.subpartition_name
where DTS.object_type = 'SUBPARTITION'
and DTS.owner = '&OWNER'
and DTS.table_name = '&TABLE_NAME'
and  DO.object_type = 'INDEX SUBPARTITION'
AND DO.owner = '&OWNER'
and trunc(created) > sysdate - &DAYS_AGO
ORDER BY INDEX_NAME, partition_position, subpartition_position;


prompt
prompt ==================================================================================================================================================================
prompt End of Stats report for &TABLE_NAME
prompt ==================================================================================================================================================================

spool off

PROMPT done


    







