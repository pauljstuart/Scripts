set echo off


prompt
prompt ========================== AWR settings ============================================================
prompt

select * from dba_hist_wr_control
where dbid = (select dbid from v$database);


/*
begin
dbms_workload_repository.modify_snapshot_settings (
   interval => 30,
   retention => 64800);
end;

*/

prompt
prompt size of SYSAUX
prompt

column total_max_mb format 999,999,999.9
column total_used_mb format 999,999,999.9
column pct_used format 99
column partition_name format A40

define TABLESPACE=SYSAUX
WITH 
pivot1 AS
(
select value/(1024*1024) as block_size_mb from v$parameter where name = 'db_block_size' 
), 
used_blocks as
  (
  SELECT TABLESPACE_NAME, SUM(blocks) tot_used_blocks
  FROM dba_segments
  where tablespace_name like '&TABLESPACE'
  GROUP BY TABLESPACE_NAME
  ),
max_blocks as
 (SELECT tablespace_name,
    SUM(DECODE(autoextensible, 'YES', maxblocks, blocks)) total_blocks
  FROM dba_data_files
  where tablespace_name like '&TABLESPACE'
  GROUP BY tablespace_name
)
SELECT max_blocks.tablespace_name, 
       max_blocks.total_blocks*(select block_size_mb from pivot1) total_max_mb, 
       used_blocks.tot_used_blocks*(select block_size_mb from pivot1) total_used_mb, 
      NVL((used_blocks.tot_used_blocks/max_blocks.total_blocks)*100,0) pct_used
FROM max_blocks
LEFT OUTER JOIN used_blocks on max_blocks.tablespace_name = used_blocks.tablespace_name;

prompt
prompt size of the AWR :
prompt

column size_mb format 999,999,999.9
COLUMN schema_name FORMAT A30
COLUMN occupant_name format A30
SELECT 
    occupant_name,  
    round( space_usage_kbytes/1024) size_mb,  
    schema_name
  FROM 
    v$sysaux_occupants  
where occupant_name = 'SM/AWR' ;
/


prompt
prompt query to examine the AWR partitions
prompt


with pivot1 as
(
SELECT table_name, partition_name,
  DBMS_XMLGEN.getxml('select  dbid, min(snap_id) X , max(snap_id) Y  from SYS.' || table_name || ' partition ( ' ||  partition_name || ' )  group by dbid' )   as xml_out
  FROM ALL_TAB_PARTITIONS  where TABLE_owner = 'SYS' AND TABLE_NAME = 'WRH$_ACTIVE_SESSION_HISTORY'
)
select table_name, partition_name,  
   case when xml_out is not null then to_number( EXTRACTVALUE(  xmltype(xml_out) , '/ROWSET/ROW/DBID')  )  end as DBID,
   case when xml_out is not null then to_number( EXTRACTVALUE(  xmltype(xml_out) , '/ROWSET/ROW/X')  ) end as min_snap,
   case when xml_out is not null then to_number( EXTRACTVALUE(  xmltype(xml_out) , '/ROWSET/ROW/Y')  ) end as max_snap,
  case when xml_out is not null then to_number( EXTRACTVALUE(  xmltype(xml_out) , '/ROWSET/ROW/Y')  )  - to_number( EXTRACTVALUE(  xmltype(xml_out) , '/ROWSET/ROW/X')  ) end as num_snaps
from pivot1;



prompt
prompt Any baselines :
prompt

select BASELINE_NAME from sys.WRM$_BASELINE where baseline_name like 'BASELINE%';

prompt
prompt ========================== AWR settings ============================================================
prompt

  


