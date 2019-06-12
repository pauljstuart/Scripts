

col P_USER new_value 1 format A20
col P_TABLENAME new_value 2 format A20
col P_SUBPARTNAME new_value 3 format A20

select null P_USER, null P_TABLENAME, null P_SUBPARTNAME from dual where 1=2;
select nvl( '&1','&_USER') P_USER, nvl('&2','%') P_TABLENAME, nvl('&3','%')  P_SUBPARTNAME from dual ;


define USERNAME=&1
define TABLE_NAME=&2     
define SUBPART_NAME=&3

undefine 1
undefine 2
undefine 3

PROMPT
PROMPT subpartition information, &USERNAME, &TABLE_NAME,   &DAYS_AGO days ago, subpartition name like '&SUBPART_NAME'
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
where  table_owner = '&USERNAME'
and    table_name = '&TABLE_NAME'
and    (subpartition_name like '&SUBPART_NAME' OR partition_name like '&SUBPART_NAME' )
and   DO.object_type = 'TABLE SUBPARTITION'
and DO.created > trunc(sysdate) - &DAYS_AGO
ORDER BY partition_NAME, subpartition_position;

--and exists (select 1 from  dba_objects DO where DO.owner = DT.table_owner and DO.object_name = DT.table_name AND DO.subobject_name = DT.subpartition_name and  DO.object_type = 'TABLE SUBPARTITION' and trunc(created) > sysdate - &DAYS_AGO)


prompt
prompt sub partition statistics, &DAYS_AGO days ago :
prompt

WITH 
pivot1 AS
      ( SELECT VALUE AS block_size FROM v$parameter WHERE NAME = 'db_block_size' )
select /*+  */ table_name,  
        partition_name,
        partition_position,         
        subpartition_name,
        subpartition_position, 
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
from  dba_tab_statistics DTS 
inner join dba_objects DO on DO.owner = DTS.owner and DO.object_name = DTS.table_name AND DO.subobject_name = DTS.subpartition_name
where DTS.object_type = 'SUBPARTITION'
and   DTS.owner = '&USERNAME'
and   DTS.table_name = '&TABLE_NAME'
and   (DTS.SUBpartition_name like '&SUBPART_NAME'  OR DTS.partition_name like '&SUBPART_NAME' )
and   DO.object_type = 'TABLE SUBPARTITION'
and   DO.created > trunc(sysdate) - &DAYS_AGO
and   DO.owner = '&USERNAME'
ORDER BY partition_position,subpartition_position;

