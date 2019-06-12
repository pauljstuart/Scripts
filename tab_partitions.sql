


col P_USER new_value 1 format A20
col P_TABLENAME new_value 2 format A20
col P_PARTNAME new_value 3 format A20

select null P_USER, null P_TABLENAME, null P_PARTNAME from dual where 1=2;
select nvl( '&1','&_USER') P_USER, nvl('&2','%') P_TABLENAME, nvl('&3','%')  P_PARTNAME from dual ;


define USERNAME=&1
define TABLE_NAME=&2     
define PART_NAME=&3

undefine 1
undefine 2
undefine 3

column high_value format A50
column interval format A15
COLUMN SAMPLE_PCT FORMAT 999
column est_size_mb format 999,999,999.9
column est_rows_per_block format 999,999
column partition_count format 999,999,999
column subpartition_count format 999,999,999
column partition_position format 999,999,999
column subpartition_position format 999,999,999
column composite format A10


prompt
prompt partition information, &DAYS_AGO days ago, partition_name like '&PART_NAME'
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
where  DT.table_owner = '&USERNAME'
and    DT.table_name = '&TABLE_NAME'
and    DT.partition_name like '&PART_NAME'
and    DO.object_type = 'TABLE PARTITION'
and    DO.created > trunc(sysdate) - &DAYS_AGO
ORDER BY partition_position;

prompt
prompt partition statistics, &DAYS_AGO days ago :
prompt

WITH 
pivot1 AS
( SELECT VALUE AS block_size FROM v$parameter WHERE NAME = 'db_block_size' )
select  table_name,  
        partition_name,
        partition_position, 
        last_analyzed ,
        num_rows, 
        blocks,
        empty_blocks,
              blocks*(select block_size from pivot1)/(1024*1024) as size_mb,
        decode( num_rows,0,0,100*sample_size/num_rows)  sample_pct, 
       chain_cnt,
       avg_row_len,
        stale_stats,
        global_stats,  
        created
from  dba_tab_statistics DT
inner join dba_objects DO on DO.owner = DT.owner and DO.object_name = DT.table_name AND DO.subobject_name = DT.partition_name
where DT.object_type = 'PARTITION'
and DT.owner = '&USERNAME'
and DT.table_name = '&TABLE_NAME'
and DT.partition_name like '&PART_NAME'
and DO.object_type = 'TABLE PARTITION'
and DO.created > trunc(sysdate) - &DAYS_AGO
ORDER BY partition_position;

