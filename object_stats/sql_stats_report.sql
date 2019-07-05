

-- get the stats for each table, once the query has been parsed.



define SQL_ID=&1


column  NUM_PARTITIONS   format 999,999,999                     
column STALE_PARTITIONS  format 999,999,999
column  NUM_SUBPARTITIONS format 999,999,999                    
column STALE_SUBPARTITIONS format 999,999,999
column UNANALYZED_PARTITIONS format 999,999,999
column UNANALYZED_SUBPARTITIONS format 999,999,999


prompt
prompt checking V$SQL_PLAN :
prompt

select count(*) 
from V$SQL_PLAN
where sql_id = '&SQL_ID';

prompt
prompt first, a high level report showing  what tables are involved :
prompt


with table_name_list as
(
select owner, table_name
from dba_tables DT
where exists (select 1 from v$sql_plan SP
      where sql_id = (select distinct sql_id from v$sql where sql_id = '&SQL_ID')
  --    and object_owner != 'SYS'
       and DT.owner = object_owner and DT.table_name = object_name )
union
select table_owner, table_name
from dba_indexes DI
where exists (select 1 from v$sql_plan SP
      where sql_id = (select distinct sql_id from v$sql where sql_id = '&SQL_ID')
 --     and object_owner != 'SYS'
       and DI.owner = object_owner and DI.index_name = object_name )
order by owner
)
select owner, table_name, partitioned, degree, iot_type, last_analyzed, temporary, num_rows
from dba_tables DT
where exists ( select 1 from table_name_list  where  DT.table_name = table_name_list.table_name and DT.owner = table_name_list.owner);


prompt
prompt NEXT, a global stats report :
prompt

with table_name_list as
(
select owner, table_name
from dba_tables DT
where exists (select 1 from v$sql_plan SP
      where sql_id = (select distinct sql_id from v$sql where sql_id = '&SQL_ID')
  --    and object_owner != 'SYS'
       and DT.owner = object_owner and DT.table_name = object_name )
union
select table_owner, table_name
from dba_indexes DI
where exists (select 1 from v$sql_plan SP
      where sql_id = (select distinct sql_id from v$sql where sql_id = '&SQL_ID')
 --     and object_owner != 'SYS'
       and DI.owner = object_owner and DI.index_name = object_name )
order by owner
)
SELECT  owner, table_name, stale_stats, last_analyzed
from  DBA_tab_statistics DTS
wHERE object_type = 'TABLE'
and exists (select 1 from table_name_list TNL where TNL.owner = DTS.owner AND  TNL.table_name = DTS.table_name )
order by owner;



prompt
prompt partitioned tables stats report
prompt


with table_name_list as
(
select owner, table_name, partitioned
from dba_tables DT
where exists (select 1 from v$sql_plan SP
      where sql_id = (select distinct sql_id from v$sql where sql_id = '&SQL_ID')
       and DT.owner = object_owner and DT.table_name = object_name )
and partitioned = 'YES' 
union
select table_owner, table_name, partitioned
from dba_indexes DI
where exists (select 1 from v$sql_plan SP
      where sql_id = (select distinct sql_id from v$sql where sql_id = '&SQL_ID')
       and DI.owner = object_owner and DI.index_name = object_name )
and partitioned = 'YES' 
)
SELECT /*+  push_pred(DTS)  */ DTS.owner, DTS.table_name, count(*) as num_partitions,    sum(decode(stale_stats, 'YES', 1, 0)) stale_partitions, sum(decode(stale_stats, NULL, 1, 0)) unanalyzed_partitions
from  DBA_tab_statistics DTS
inner join table_name_list TNL on TNL.owner = DTS.owner AND  TNL.table_name = DTS.table_name 
wHERE object_type = 'PARTITION'
--and   exists (select 1 from table_name_list TNL where TNL.owner = DTS.owner AND  TNL.table_name = DTS.table_name  and TNL.partitioned = 'YES' )
GROUP BY DTS.OWNER, DTS.TABLE_NAME;

prompt
prompt sub partitions report 
prompt

with table_name_list as
(
select owner, table_name, partitioned
from dba_tables DT
where exists (select 1 from v$sql_plan SP
      where sql_id = (select distinct sql_id from v$sql where sql_id = '&SQL_ID')
       and DT.owner = object_owner and DT.table_name = object_name )
union
select table_owner, table_name, partitioned
from dba_indexes DI
where exists (select 1 from v$sql_plan SP
      where sql_id = (select distinct sql_id from v$sql where sql_id = '&SQL_ID')
       and DI.owner = object_owner and DI.index_name = object_name )
order by owner
)
SELECT /*+ push_pred(DTS) */  DTS.OWNER, DTS.TABLE_NAME, count(*) as num_subpartitions, sum(decode(stale_stats, 'YES', 1, 0)) stale_subpartitions,  sum(decode(stale_stats, NULL, 1, 0)) unanalyzed_subpartitions
from DBA_tab_statistics DTS 
inner join table_name_list TNL on TNL.owner = DTS.owner AND  TNL.table_name = DTS.table_name  and TNL.partitioned = 'YES' 
  where  DTS.object_type = 'SUBPARTITION'
GROUP BY DTS.OWNER, DTS.TABLE_NAME;



