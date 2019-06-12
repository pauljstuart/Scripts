
column current_size_gb format 999,999,999;
column max_size_gb format 999,999,999;

WITH pivot1 AS
(
select value/(1024*1024*1024) as block_size from v$parameter where name = 'db_block_size' 
)
SELECT tablespace_name,
    SUM(BLOCKS*(select block_size from pivot1)) current_size_gb,
    SUM(DECODE(autoextensible, 'YES', maxblocks, BLOCKS))*(select block_size from pivot1) max_size_gb
  FROM dba_temp_files
  GROUP BY tablespace_name
UNION
SELECT tablespace_name,
    SUM(BLOCKS*(select block_size from pivot1)) current_size_gb,
    SUM(DECODE(autoextensible, 'YES', maxblocks, BLOCKS))*(select block_size from pivot1) max_size_gb
  FROM dba_data_files
  GROUP BY tablespace_name;
