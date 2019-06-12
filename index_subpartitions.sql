
col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2, nvl('&3','%')  PARAM3 from dual ;


define USERNAME=&1
define INDEX_NAME=&2     
define SUBPART_NAME=&3

column status format A10
column index_owner format A15

SELECT T1.index_owner,
       T1.index_name, 
       DI.table_name, 
       T1.subpartition_name,
       T1.subpartition_position,
       T1.status,
       T1.tablespace_name,
       T1.segment_created,    
       T1.pct_free,
       T1.ini_trans,
       T1.compression,
       T1.num_rows,
       T1.last_analyzed,
       T1.global_stats,
       T1.interval,
       T1.high_value
FROM dba_ind_subpartitions T1
INNER JOIN DBA_INDEXES DI on DI.index_name = T1.index_name and DI.owner = T1.index_owner
inner join dba_objects DO on DO.owner = T1.index_owner and DO.object_name = T1.index_name AND DO.subobject_name = T1.SUBpartition_name
WHERE T1.index_owner = '&USERNAME'
AND T1.index_name =  '&INDEX_NAME' 
and subpartition_name like '&SUBPART_NAME'
and    DO.created > trunc(sysdate) - &DAYS_AGO
and    DO.object_type = 'INDEX SUBPARTITION'
order by T1. index_name, T1.subpartition_position 
