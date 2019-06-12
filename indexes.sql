--
-- indexes.sql
--
-- Paul Stuart
--
-- Nov 2004 
--


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2 from dual ;


define USERNAME=&1
define INDEX_NAME=&2     


undefine 1
undefine 2
undefine 3


column tablespace_name format a20
column table_name format a30
column column_name format a20
column index_name format a30
column Type     format a6
column Col_Pos format 99
column BLVL format 99
column status format A6
column leaf_blocks format 999,999,999
column DEGREE format A9

SELECT
  t1.owner, 
  t1.table_name,
  t1.index_name,
  t1.tablespace_name,
  t1.index_type type ,
  t2.column_position col_pos ,
  t2.column_name,
  t1.status,
  T1.uniqueness, 
  T1.compression, 
  leaf_blocks,
  distinct_keys, AVG_LEAF_BLOCKS_PER_KEY, AVG_DATA_BLOCKS_PER_KEY, CLUSTERING_FACTOR, NUM_ROWS, last_analyzed, degree, partitioned, visibility,
  t1.blevel BLVL,
  t1.last_analyzed
FROM
  dba_indexes t1
INNER JOIN dba_ind_columns t2
ON
  T1.owner        = T2.index_owner
AND t1.index_name = t2.index_name
WHERE
  T1.owner = '&USERNAME'
AND (T1.index_name LIKE '&INDEX_NAME' or T1.table_name like '&INDEX_NAME')
ORDER BY
  t1.table_name,
  t1.index_name,
  t2.column_position ;   


prompt
prompt checking for NULLABLE columns :
prompt

column nullable format A10
column column_position format 999

SELECT IC.index_owner, IC.index_name, IC.table_name, IC.column_name, IC.column_position, nullable , num_nulls
from  dba_ind_COLUMNs IC
left outer join dba_tab_columns CC on CC.owner = IC.table_owner and CC.table_name = IC.table_name and CC.column_name = IC.column_name
where 
   index_owner = '&USERNAME'
AND (IC.index_name LIKE '&INDEX_NAME' or IC.table_name like '&INDEX_NAME')
and nullable = 'Y'
order by  COLUMN_position ;

