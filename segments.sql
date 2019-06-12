
col P_USER new_value 1 format A10
col P_SEGMENTNAME new_value 2 format A10
col P_TABLESPACE new_value 3 format A10

select null P_USER, null P_SEGMENTNAME, null P_TABLESPACE from dual where 1=2;
select nvl( '&1','&_USER') P_USER, nvl('&2','%') P_SEGMENTNAME, nvl('&3','%') P_TABLESPACE from dual ;


define USERNAME=&1
define SEGMENT_NAME=&2     
define TABLESPACE_NAME=&3


undefine 1
undefine 2
undefine 3



column size_mb format 999,999,999.9
column blocks format 999,999,999.9
column extents format 999,999,999.9

prompt
prompt Segments owned by &USERNAME (&SEGMENT_NAME) in tablespace &TABLESPACE_NAME
prompt 




select owner, segment_name, partition_name, segment_type, tablespace_name, bytes/(1024*1024) size_mb, blocks, extents 
from dba_segments
where owner like '&USERNAME' 
and segment_name like '&SEGMENT_NAME'
and tablespace_name like '&TABLESPACE_NAME';



