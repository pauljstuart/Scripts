
col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2, nvl('&3',0)  PARAM3 from dual ;


define OWNER=&1
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
column def_pct_free format 9999
column DEF_INI_TRANS format 999
column mtran format 99999
column sample_pct format 999.9
COLUMN PARTITION_KEY FORMAT a30
COLUMN SUBPARTITION_KEY FORMAT a30

COLUMN PARTITIONING_TYPE FORMAT a20
COLUMN SUBPARTITIONING_TYPE FORMAT a20
COLUMN def_compression FORMAT a20
column high_value     format a30
column NUM_PARTITIONS format 999,999,999
column NUM_SUBPARTITIONS format 999,999,999


with pivot1 as
(
select owner, object_name as table_name, (case when object_type = 'TABLE PARTITION' THEN 1 ELSE 0 END) AS PART, (case when object_type = 'TABLE SUBPARTITION' THEN 1 ELSE 0 END) AS SUBPART
FROM DBA_OBJECTS
where owner = '&OWNER'
and OBJECT_NAME = '&TABLE_NAME'
and object_type in ('TABLE PARTITION','TABLE SUBPARTITION')
), PIVOT2 AS
(
SELECT OWNER, table_name, sum(part) as num_partitionS, sum(subpart) as num_subpartitions
from pivot1
group by owner, table_name
)
select PT.owner, PT.table_name,
        partitioning_type,
        subpartitioning_type,
       pkc.column_name as partition_key,
      SKC.COLUMN_NAME AS SUBPARTITION_KEY,
    --    partition_count,
        interval,
         pivot2.num_partitions, 
          pivot2.num_subpartitions,
   --     partitioning_key_count,
   --     subpartitioning_key_count,
        def_tablespace_name,
        def_compression,
       DEF_PCT_FREE ,
        DEF_INI_TRANS
from dba_part_tables PT
inner join dba_PART_KEY_COLUMNS PKC on PKC.owner = PT.owner and PKC.name = PT.table_name
inner join pivot2 on pivot2.owner = PT.owner and pivot2.table_name = PT.table_name
LEFT OUTER join dba_subPART_KEY_COLUMNS SKC on  SKC.OWNER = PT.OWNER AND SKC.NAME = PT.table_NAME
where PT.owner = '&OWNER'
AND PT.table_name = '&TABLE_NAME'
ORDER BY SUBPARTITIONING_TYPE DESC, PARTITIONING_TYPE, PARTITION_KEY, SUBPARTITION_KEY,TABLE_NAME;




SELECT dpkc.owner, dpkc.name, dpkc.column_name as partition_key, data_type
FROM dba_PART_KEY_COLUMNS DPKC
inner join dba_tab_cols DTC on DTC.owner = DPKC.owner and DTC.table_name = dPKC.name and dpkc.column_name = dtc.column_name
WHERE dpkc.owner LIKE upper('&OWNER')
AND dpkc.name LIKE upper('&TABLE_NAME')
AND dpkc.object_type = 'TABLE';


prompt
prompt Sub partition Key columns
prompt


SELECT dpkc.owner, dpkc.name, dpkc.column_name as SUBpartition_key, data_type
FROM dba_subPART_KEY_COLUMNS DPKC
inner join dba_tab_cols DTC on DTC.owner = DPKC.owner and DTC.table_name = dPKC.name and dpkc.column_name = dtc.column_name
WHERE dpkc.owner LIKE upper('&OWNER')
AND dpkc.name LIKE upper('&TABLE_NAME')
AND dpkc.object_type = 'TABLE';





PROMPT
PROMPT Count of Partition and Subpartitions :
prompt

select count(1) as Number_of_partitions
FROM dba_tab_partitions
WHERE  table_name = upper('&TABLE_NAME')
AND table_owner = upper('&OWNER');


select count(1) as Number_of_subpartitions
FROM dba_tab_subpartitions
WHERE  table_name = upper('&TABLE_NAME')
AND table_owner = upper('&OWNER');




