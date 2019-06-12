
--
-- Paul Stuart
-- 
-- Nov 2004
-- Apr 2005
-- Feb 2014


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2, nvl('&3',0)  PARAM3 from dual ;


define USERNAME=&1
define TABLE_NAME=&2     
define ROW_SIZE=&3

undefine 1
undefine 2
undefine 3



column num_rows format 999,999,999,999
column logging format a3
column Degree format a10   justify left 
column owner format a15
column tablespace_name format a30
column table_name format a30
column itran format 99999
column mtran format 99999
column sample_pct format 999.9
column partition_name format a18
column high_value     format a30
column partition_count format 999,999

prompt
prompt Tables owned by &USERNAME (&TABLE_NAME)
prompt 

select DT.owner, 
       table_name, 
       tablespace_name, 
       num_rows, 
       avg_row_len, 
       blocks, 
       blocks*(select value from v$parameter where name = 'db_block_size')/(1024*1024) size_mb,
       degree, 
       partitioned, 
       DT.temporary,
       last_analyzed , 
        decode( num_rows,0,0,100*sample_size/num_rows)  sample_pct, 
        compression,
        compress_for
, created
from dba_tables DT
inner join dba_objects DO on DO.owner = DT.owner and DO.object_name = DT.table_name
where DT.owner = '&USERNAME'
and DT.table_name LIKE '&TABLE_NAME'
and DO.owner = '&USERNAME'
and DO.object_type = 'TABLE'
and DO.OBJECT_NAME LIKE '&TABLE_NAME'
order by CREATED;


prompt
prompt table statistics :
prompt

column stattype_locked format A15

WITH 
pivot1 AS
( SELECT VALUE AS block_size FROM v$parameter WHERE NAME = 'db_block_size' )
select  table_name,  
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
        stattype_locked
from  dba_tab_statistics DT
where DT.object_type = 'TABLE'
and DT.owner = '&USERNAME'
and DT.table_name like '&TABLE_NAME'
ORDER BY table_name;
