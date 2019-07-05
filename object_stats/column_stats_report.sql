
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
prompt Column stats report for &SCHEMA_NAME
prompt



prompt
prompt Tables missing global column statistics on some columns :
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
),
pivot2 as
(
select D.owner, D.table_name, 
    (SELECT  count(1)   FROM dba_tab_columns WHERE  table_name = D.table_name AND owner = D.owner ) num_columns,
     (select count(last_analyzed) from dba_tab_col_statistics C where c.table_name = D.table_name and c.owner = D.owner) num_analyzed_columns
from 
  pivot1 D
)
select OWNER, table_name, num_columns, num_columns - num_analyzed_columns as num_unanalyzed_columns 
from pivot2
where (num_analyzed_columns < num_columns);




prompt
prompt the following tables have partitions without complete column stats :
prompt


with pivot1 as
(
select owner, segment_name as table_name, sum(blocks)
from dba_segments
where owner = '&SCHEMA_NAME'
and segment_type IN ('TABLE PARTITION')
and segment_name not like '%TEMP%'
and segment_name not like '%TMP%'
and segment_name not like 'M$%'
and segment_name not like '%TEST%'
and segment_name not like '%TST%'
and segment_name not like '%LOG%'
and segment_name not like '%BACKUP%'
and segment_name not like 'M$%'
and segment_name not like '%N$%'
group by  owner, segment_name
having sum(blocks) > 64
),
pivot2 as
(
SELECT owner, table_name, partition_name, count(column_name), count(last_analyzed), count(column_name) - count(last_analyzed) partitions_without_col_stats,
         decode( count(column_name) - count(last_analyzed), 0, 1,  0) analyzed_count
FROM 
dba_part_col_statistics D
WHERE 
  owner = '&SCHEMA_NAME'
  and D.table_name in (select table_name from pivot1)
group by owner, table_name, partition_name
order by table_name
)
select owner, table_name, count(partition_name) num_partitions, count(partition_name) - sum(analyzed_count) partitions_missing_col_stats
from pivot2
group by owner, table_name
having  count(partition_name) - sum(analyzed_count) > 0;
 



set feedback on
set echo off

