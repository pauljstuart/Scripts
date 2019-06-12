


COLUMN sample_size FORMAT 999,999,999,999
COLUMN est_size_mb FORMAT 999,999,999.9
column est_rows_per_block format 999,999,999,999
COLUMN size_mb FORMAT 999,999,999.9;
column operation format A20
column start_time format A19
column STATS_UPDATE_TIME format A19
column DATA_LENGTH format 999,999
column DATA_PRECISION format 999.999
column DATA_SCALE format 999,999
column nullable format A10
column default_length format 999,999
column STATTYPE_LOCKED  format A15

define OWNER=&1
define TABLE_NAME=&2

PROMPT => show_table_&OWNER..&TABLE_NAME..sql

set echo off
set termout off
spool show_table_&OWNER..&TABLE_NAME..sql
prompt
prompt ==============================================================================================================================================================================================
prompt
prompt USER : &OWNER
prompt TABLE : &TABLE_NAME
prompt
prompt ==============================================================================================================================================================================================
prompt

prompt 
prompt general info from dba_tables :
prompt

WITH 
pivot1 AS
      ( SELECT VALUE AS block_size FROM v$parameter WHERE NAME = 'db_block_size' )
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
       sample_size,
       last_analyzed,
      compression, 
      compress_for, 
      row_movement,
      read_only
from dba_tables
where table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER');

prompt 
prompt dba_objects :
prompt


select owner,
       object_name,
       created,
       last_ddl_time,
       object_type
from dba_objects
where     owner = upper('&OWNER')
AND object_name = upper('&TABLE_NAME')
and object_type = 'TABLE'
;


/*
prompt
prompt  Estimate of Avg Rows per block for &TABLE_NAME
prompt

WITH 
   block_size1 AS
      ( SELECT VALUE AS block_size FROM v$parameter WHERE NAME = 'db_block_size' ),
  pct_free1 AS
      ( SELECT pct_free FROM dba_tables WHERE owner = upper('&OWNER')  AND table_name LIKE upper('&TABLE_NAME') ),
  avg_row_len1 AS
      ( SELECT avg_row_len FROM dba_tables WHERE owner = upper('&OWNER')  AND table_name LIKE upper('&TABLE_NAME') )
SELECT
     round((block_size - (block_size*pct_free/100))/avg_row_len ) as est_rows_per_block
FROM block_size1, pct_free1, avg_row_len1;
*/


prompt
prompt Columns for table : &TABLE_NAME
prompt


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
   data_default
FROM dba_tab_columns
WHERE 
    table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER')
order by column_id;



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



prompt
prompt Indexes for table : &TABLE_NAME
prompt

SELECT T1.table_name, t1.index_name,
       T1.uniqueness, 
       t1.tablespace_name,  
       T1.index_type type , 
       T2.COLUMN_position col_pos,
       T2.COLUMN_name, 
       T1.last_analyzed,
       t1.status, 
       T1.blevel BLVL, 
       T1.pct_free,
       T1.clustering_factor,
       T1.partitioned
FROM dba_indexes T1
INNER JOIN dba_ind_COLUMNs T2 ON T2.table_owner = T1.owner and T2.table_name = T1.table_name
WHERE t1.index_name = t2.index_name
AND t1.owner = upper('&OWNER')
AND t1.table_name = upper('&TABLE_NAME')
ORDER BY t1.table_name, t1.index_name, t2.column_position ;    
 



prompt
prompt Constraints for table : &TABLE_NAME
prompt



SELECT OWNER, CONSTRAINT_NAME,CONSTRAINT_TYPE, TABLE_NAME, R_OWNER,R_CONSTRAINT_NAME, DELETE_RULE, STATUS, DEFERRABLE, DEFERRED , VALIDATED, GENERATED ,  laST_CHANGE,   INDEX_OWNER ,                    INDEX_NAME,                     INVALID, SEARCH_CONDITIOn
FROM dba_constraints
WHERE table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER');    


prompt
prompt details for any Primary Keys :
prompt

SELECT  cons.owner, cols.table_name,cons.constraint_name,  cols.column_name, cols.position, cons.status
FROM all_constraints cons, all_cons_columns cols
WHERE cols.table_name = upper('&TABLE_NAME')
and cols.owner = upper('&OWNER')
AND cons.constraint_type = 'P'
AND cons.constraint_name = cols.constraint_name
AND cons.owner = cols.owner
ORDER BY cols.table_name, cols.position;


prompt
prompt Any foreign keys referencing primary keys on &TABLE_NAME :
prompt


SELECT
  SRC.OWNER AS PARENT_OWNER,
  SRC.TABLE_NAME AS PARENT_TABLE,
  SRC.CONSTRAINT_NAME AS REFERENCED_CONSTRAINT,
  FK.OWNER AS CHILD_OWNER,
  FK.TABLE_NAME AS CHILD_TABLE,
  FK.CONSTRAINT_NAME AS FK_CONSTRAINT
FROM ALL_CONSTRAINTS FK
JOIN ALL_CONSTRAINTS SRC ON FK.R_CONSTRAINT_NAME = SRC.CONSTRAINT_NAME
WHERE
  FK.CONSTRAINT_TYPE = 'R'
  AND SRC.OWNER = upper('&OWNER')
  AND SRC.TABLE_NAME = upper('&TABLE_NAME');
  
prompt
prompt Foreign keys referencing this table which lack indexes :
prompt

SELECT
  SRC.OWNER AS PARENT_OWNER,
  SRC.TABLE_NAME AS PARENT_TABLE,
  SRC.CONSTRAINT_NAME AS REFERENCED_CONSTRAINT,
  FK.OWNER AS CHILD_OWNER,
  FK.TABLE_NAME AS CHILD_TABLE,
  FK.CONSTRAINT_NAME AS FK_CONSTRAINT, 
  CC.column_name
FROM ALL_CONSTRAINTS FK
JOIN ALL_CONSTRAINTS SRC ON FK.R_CONSTRAINT_NAME = SRC.CONSTRAINT_NAME
join all_cons_columns CC on FK.constraint_name = CC.constraint_name
WHERE
  FK.CONSTRAINT_TYPE = 'R'
  AND SRC.OWNER = upper('&OWNER')
  AND SRC.TABLE_NAME = upper('&TABLE_NAME')
and not exists
(
select 1
from all_ind_columns AIC
where  AIC.table_owner = FK.owner
    and AIC.table_name = FK.table_name
    and AIC.column_name = CC.column_name);


prompt
prompt Details of any foreign keys on this table :
prompt

SELECT   uc.constraint_name FK_constraint,     ' (' || ucc1.owner ||'.' ||ucc1.TABLE_NAME||'.'||ucc1.column_name||')' constraint_source
        ,  ucc2.constraint_name PARENT_KEY_NAME,
      'REFERENCES: ' || ucc2.owner || '.'||ucc2.TABLE_NAME||'('||ucc2.column_name||')' references_column       
FROM         all_constraints uc
inner join   all_cons_columns ucc1 on uc.constraint_name = ucc1.constraint_name and uc.owner = ucc1.owner
inner join all_cons_columns ucc2 on  uc.r_constraint_name = ucc2.constraint_name and uc.owner = ucc2.owner and ucc1.POSITION = ucc2.POSITION 
AND      uc.constraint_type = 'R'
AND        uc.owner = upper('&OWNER')
AND       uc.table_name = upper('&TABLE_NAME')
ORDER BY ucc1.TABLE_NAME, uc.constraint_name;

prompt
prompt Triggers for table : &TABLE_NAME
prompt



select TABLE_NAME, TRIGGER_NAME, TRIGGER_TYPE, TRIGGERING_EVENT, STATUS
from dba_triggers
WHERE table_name = upper('&TABLE_NAME')
AND table_owner = upper('&OWNER');   




prompt 
prompt access report : roles :
PROMPT

select * from 
role_tab_privs
where table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER'); 
prompt 
prompt access report : accounts :
PROMPT


select * from 
DBA_tab_privs
where table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER');  

prompt
prompt Actual blocks and size from dba_segments : &TABLE_NAME
prompt


SELECT owner, segment_name, bytes/(1024*1024) size_MB, blocks
 FROM DBA_segments
 WHERE  owner = upper('&OWNER') 
 and segment_name like upper('&TABLE_NAME')
 AND segment_type = 'TABLE';


prompt
prompt Extent Analysis for &TABLE_NAME
prompt

/*
select owner, segment_name, blocks, count(extent_id) num_extents
from dba_extents
 WHERE  owner = upper('&OWNER') 
 and segment_name like upper('&TABLE_NAME')
group by owner, segment_name, blocks
order by blocks;
*/

prompt
prompt HWM analysis report
prompt

column hwm_blks format 999,999,999
column Current_rows_in_blks format 999,999,999
column empty_blocks format 999,999,999
column empty_under_hwm_pct format 999.9
column current_rows_in_blks format 999,999,999


select owner, table_name,
      blocks                                     hwm_blks,
      (num_rows*avg_row_len)/(select value from v$parameter where name = 'db_block_size')            Current_rows_in_blks,
      blocks - (num_rows*avg_row_len)/(select value from v$parameter where name = 'db_block_size') empty_blocks,  
         DECODE( BLOCKS, 0, 0,   100*(blocks - (num_rows*avg_row_len)/(select value from v$parameter where name = 'db_block_size'))/blocks) empty_under_hwm_pct
from dba_tab_statistics 
where partition_name is null
and subpartition_name is null
and table_name = upper('&TABLE_NAME')
AND owner = upper('&OWNER');  


prompt
prompt ==================================================================================================================================================================
prompt 					Table Statistics Report
prompt			
prompt 					for &OWNER/&TABLE_NAME
prompt
prompt ==================================================================================================================================================================
prompt

prompt 
prompt global statistics preferences :
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
prompt 
prompt Table stats preferences for &OWNER/&TABLE_NAME
prompt 
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


prompt
prompt 
prompt Statistics history for : &TABLE_NAME
prompt 
prompt



@OBJECT_STATS/OPSTAT_TAB_HISTORY &OWNER &TABLE_NAME

@OBJECT_STATS/OPSTAT_OPERATIONS &OWNER &TABLE_NAME


prompt
prompt 
prompt global table stats :
prompt 
prompt 


select  A.table_name,  
          A.num_rows, 
          A.last_analyzed ,
          round( decode( A.num_rows,0,0,100*A.sample_size/A.num_rows), 2)  sample_pct, 
        A.stale_stats,
        STATTYPE_LOCKED , 
        B.partitioned,
        B.global_stats
from dba_tab_statistics A
inner join dba_tables B on A.owner = b.owner and A.table_name = B.table_name
where A.owner = upper('&OWNER')
and  A.table_name like upper('&TABLE_NAME')
and A.partition_name is NULL;


prompt 
prompt global column stats  :
prompt 



column cardinality format 999,999,999,999
column low_v format A20
column hi_v format A20

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
prompt index stats 
prompt 




SELECT T1.table_name, t1.index_name,
       T1.uniqueness, 
       T1.last_analyzed,
       t1.status
FROM dba_indexes T1
where t1.owner = upper('&OWNER')
AND t1.table_name = upper('&TABLE_NAME') ;    
 
 
 


prompt
prompt ==================================================================================================================================================================
prompt End of Stats report for &TABLE_NAME
prompt ==================================================================================================================================================================
prompt

spool off
set termout on


prompt done


