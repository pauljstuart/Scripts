
set echo off
set feedback off


column owner format A20
column table_name format A30

column NUM_PARTITIONS format 999,999
column NUM_SUBPARTITIONS format 999,999,999
column STALE_PARTITIONS format 999,999

column NUM_PARTITIONS format 999,999
column STALE_PARTITIONS format 999,999
column UNANALYZED_PARTITIONS format 999,999
column   NUM_COLUMNS       format 9,999
column NUM_ANALYZED_COLUMNS format 9,999
column STALE_STATS format A10
column num_unanalyzed_columns format 9,999
column unanalyzed_subpartitions format 999,999,999
column stale_subpartitions format 999,999,999

col REGEXP1 new_value 2

select null REGEXP1 from dual where 1=2;
select  nvl('&2','BKP') REGEXP1 from dual ;

define SCHEMA_NAME=&1
define REGEXP_PATTERN=&2

undefine 1
undefine 2
set termout on

prompt
prompt Table filter regular expression : '&REGEXP_PATTERN'
prompt

prompt
prompt Stale/Missing stats report for &SCHEMA_NAME
prompt

prompt
prompt The following tables do not have global table statistics :
prompt

with pivot1 as
(
select owner, segment_name as table_name, sum(blocks)
from dba_segments
where owner = '&SCHEMA_NAME'
and segment_type IN ('TABLE PARTITION', 'TABLE', 'TABLE SUBPARTITION')
and segment_name not like '%TEMP%'
and segment_name not like '%TMP%'
and segment_name not like 'M$%'
and segment_name not like '%TEST%'
and segment_name not like '%TST%'
and segment_name not like '%LOG%'
and segment_name not like '%BACKUP%'
and segment_name not like 'CMP%'
and segment_name not like 'M$%'
and segment_name not like '%N$%'
and not regexp_like( segment_name, '&REGEXP_PATTERN')
group by  owner, segment_name
having sum(blocks) > 32
)
select D.owner, D.table_name, S.last_analyzed,   S.stale_stats
from 
  pivot1 D
  inner join dba_tab_statistics S on D.owner = S.owner and D.table_name = S.table_name  
where S.last_analyzed is NULL 
and S.object_type = 'TABLE';



prompt
prompt The following tables have global statistics, but are stale :
prompt

with pivot1 as
(
select owner, segment_name as table_name, sum(blocks)
from dba_segments
where owner = '&SCHEMA_NAME'
and segment_type IN ('TABLE PARTITION', 'TABLE', 'TABLE SUBPARTITION')
and segment_name not like '%TEMP%'
and segment_name not like '%TMP%'
and segment_name not like 'M$%'
and segment_name not like '%TEST%'
and segment_name not like '%TST%'
and segment_name not like '%LOG%'
and segment_name not like '%BACKUP%'
and segment_name not like 'M$%'
and segment_name not like '%N$%'
and not regexp_like( segment_name, '&REGEXP_PATTERN')
group by  owner, segment_name
having sum(blocks) > 32
)
select D.owner, D.table_name, S.last_analyzed,   S.stale_stats
from 
  pivot1 D
  inner join dba_tab_statistics S on D.owner = S.owner and D.table_name = S.table_name  
where S.stale_stats = 'YES' 
and S.object_type = 'TABLE';



prompt
prompt The following tables have partitions which are stale or unanalyzed :
prompt

with table_name_list as
(
select owner, segment_name as table_name, sum(blocks)
from dba_segments
where owner = '&SCHEMA_NAME'
and segment_type IN ('TABLE PARTITION')
and segment_name not like '%TEMP%'
and segment_name not like '%TMP%'
and segment_name not like '%TEST%'
and segment_name not like '%TST%'
and segment_name not like '%LOG%'
and segment_name not like '%BACKUP%'
and segment_name not like '%BKP%'
and not regexp_like( segment_name, '&REGEXP_PATTERN')
group by  owner, segment_name
having sum(blocks) > 64
)
SELECT /*+  push_pred(DTS)  */ DTS.owner, DTS.table_name, count(*) as num_partitions,    sum(decode(stale_stats, 'YES', 1, 0)) stale_partitions, sum(decode(stale_stats, NULL, 1, 0)) unanalyzed_partitions
from  DBA_tab_statistics DTS
inner join table_name_list TNL on TNL.owner = DTS.owner AND  TNL.table_name = DTS.table_name 
wHERE object_type = 'PARTITION'
GROUP BY DTS.OWNER, DTS.TABLE_NAME
HAVING sum(decode(stale_stats, 'YES', 1, 0)) >0 or  sum(decode(stale_stats, NULL, 1, 0)) >0;



prompt
prompt The following tables have subpartitions which are stale or unanalyzed :
prompt

with table_name_list as
(
select owner, segment_name as table_name, sum(blocks)
from dba_segments
where owner = '&SCHEMA_NAME'
and segment_type IN ('TABLE SUBPARTITION')
and segment_name not like '%TEMP%'
and segment_name not like '%TMP%'
and segment_name not like '%TEST%'
and segment_name not like '%TST%'
and segment_name not like '%LOG%'
and segment_name not like '%BACKUP%'
and segment_name not like '%BKP%'
and not regexp_like( segment_name, '&REGEXP_PATTERN')
group by  owner, segment_name
having sum(blocks) > 64
)
SELECT /*+  push_pred(DTS)  */ DTS.owner, DTS.table_name, count(*) as num_partitions,    sum(decode(stale_stats, 'YES', 1, 0)) stale_SUBpartitions, sum(decode(stale_stats, NULL, 1, 0)) unanalyzed_SUBpartitions
from  DBA_tab_statistics DTS
inner join table_name_list TNL on TNL.owner = DTS.owner AND  TNL.table_name = DTS.table_name 
wHERE object_type = 'SUBPARTITION'
GROUP BY DTS.OWNER, DTS.TABLE_NAME
HAVING sum(decode(stale_stats, 'YES', 1, 0)) >0 or  sum(decode(stale_stats, NULL, 1, 0)) >0;






set feedback on
set echo off

