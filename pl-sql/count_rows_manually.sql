create or replace
function get_rows( p_tname in varchar2 ) return number
as
    l_columnValue    number default NULL;
begin
    execute immediate
       'select count(1)
          from ' || p_tname INTO l_columnValue;
    return l_columnValue;
end;


column cnt format 999,999,999,999
select user, table_name, last_analyzed, stale_stats, PARTITIONED, 
       get_rows( 'MERIDIAN' ||'.'||table_name) cnt
  from dba_tables
where owner = 'MERIDIAN';


-- query to get row count of big tables :

with pivot1 as
(
select owner, segment_name, sum(blocks)
from dba_segments
where owner = 'MERIDIAN'
and segment_type IN ('TABLE', 'TABLE PARTITION')
and segment_name not like '%TEMP%'
and segment_name not like '%TMP%'
and segment_name not like 'M$%'
and segment_name not like '%TEST%'
and segment_name not like '%TST%'
and segment_name not like '%LOG%'
and segment_name not like '%N$%'
group by  owner, segment_name
having sum(blocks) > 64
)
select  table_name, last_analyzed, GLOBAL_STATS, PARTITIONED,  get_rows( 'MERIDIAN' ||'.'||table_name) cnt
  from dba_tables
where owner = 'MERIDIAN'
and table_name in (select segment_name from pivot1);
