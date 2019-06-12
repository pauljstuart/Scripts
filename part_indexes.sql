--
-- part_indexes.sql
--
-- Paul Stuart
--
-- Nov 2004
-- may 2017
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

SELECT
  t1.owner, 
  t1.table_name,
  t1.index_name,
  partitioning_type,
  subpartitioning_type, partitioning_key_count, subpartitioning_key_count,
  locality,
  alignment, 
        DEF_TABLESPACE_NAME,
        DEF_PCT_FREE , def_ini_trans, def_max_trans
FROM
  dba_part_indexes t1
WHERE
  T1.owner = '&USERNAME'
AND (T1.index_name LIKE '&INDEX_NAME' or T1.table_name like '&INDEX_NAME')
ORDER BY
  t1.table_name,
  t1.index_name;



