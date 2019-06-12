set echo off
set feedback off
prompt
prompt =========================================================================================
prompt

--
-- ts_space.sql
--
-- by Paul Stuart and Bala
-- 
-- June 2004
-- Jan  2013

col p1 new_value 1
col p2 new_value 2
col p3 new_value 3
select null p1, null p2, null p3 from dual where 1=2;
select nvl( '&1','SYSTEM') p1 from dual ;

define TABLESPACE=&1;


undefine 1

column total_max_gb format 999,999,999;
column total_used_gb format 999,999,999;
column max_size_gb format 999,999,999;
column free_gb format 999,999,999;
column tablespace_name format A30
column pct_used format 999.9;
column pct_FREE format 999.9
/*
select a.tablespace_name, 
        (select sum(d.bytes)/(1024*1024) FROM dba_data_files d where d.tablespace_name = a.tablespace_name) "Total MB" ,      
        sum(a.bytes)/(1024*1024) "Used MB", 
        (select sum(b.bytes)/(1024*1024) FROM dba_free_space b where b.tablespace_name = a.tablespace_name) "Free MB"
from dba_segments a
group by a.tablespace_name
*/





prompt


column total_max_gb format 999,999,999;
column total_used_gb format 999,999,999;
column free_gb format 999,999,999;
column tablespace_name format A30
column pct_used format 999.9;
WITH 
 used_size as
  (
  SELECT TABLESPACE_NAME, SUM(blocks)*(select value/(1024*1024*1024) from v$parameter where name = 'db_block_size' ) total_used_gb
  FROM dba_segments
   where  tablespace_name like '&TABLESPACE' 
   and tablespace_name not like 'UNDO%'
   and tablespace_name not like 'TEMP%'
  GROUP BY TABLESPACE_NAME
  ),
max_size as
(
SELECT tablespace_name,
    SUM(DECODE(autoextensible, 'YES', maxblocks, blocks))*(select value/(1024*1024*1024) from v$parameter where name = 'db_block_size' )  max_size_gb
  FROM dba_data_files
  where  tablespace_name like '&TABLESPACE'
   and tablespace_name not like 'UNDO%'
   and tablespace_name not like 'TEMP%'
  GROUP BY tablespace_name
)
SELECT max_size.tablespace_name, 
       max_size_gb,
       total_used_gb,
       max_size_gb - total_used_gb  free_gb,
      NVL( total_used_gb*100/max_size_gb,0) pct_used,
NVL( (max_size_gb - total_used_gb)*100/max_size_gb,0) pct_free
FROM max_size
LEFT OUTER JOIN used_size on max_size.tablespace_name = used_size.tablespace_name
order by 5 desc;




prompt
prompt
prompt max fragment sizes :
prompt


column mxfrag_mb format 999,999,999.0

SELECT tablespace_name tsname,
  COUNT(free.bytes) nfrags,
  NVL(MAX(free.bytes)/(1024*1024),0) mxfrag_mb
from dba_free_space free
where tablespace_name like '&TABLESPACE'
group by tablespace_name;

prompt
prompt Free Space Fragmentation Index
prompt
prompt Max is 100, any tablespace with sufficient space and FSFI below 30 should be OK.
prompt

column fsfi format 999.9;

select TABLESPACE_NAME,
  SQRT(MAX(BLOCKS)/SUM(BLOCKS))*(100/SQRT(SQRT(COUNT(BLOCKS)))) Fsfi 
from dba_free_space 
where tablespace_name like '&TABLESPACE'
group by tablespace_name order by 1; 


prompt
prompt histogram of free fragment sizes (in KB)
prompt


with pivot_table as
(
select 
  bytes/1024 as frag_size_kb,
  CASE WHEN width_bucket( bytes/1024, 1, 64, 1) = 1 THEN 1 ELSE 0 END AS to64,
  CASE WHEN width_bucket( bytes/1024, 65, 128, 1) = 1 THEN 1 ELSE 0 END AS to128,
  CASE WHEN width_bucket( bytes/1024, 129, 256, 1) = 1 THEN 1 ELSE 0 END AS to256,
  CASE WHEN width_bucket( bytes/1024, 257, 512, 1) = 1 THEN 1 ELSE 0 END AS to512,
  CASE WHEN width_bucket( bytes/1024, 513, 1024, 1) = 1 THEN 1 ELSE 0 END AS to1024,
  CASE WHEN width_bucket( bytes/1024, 1025, 2048, 1) = 1 THEN 1 ELSE 0 END AS to2048,
  CASE WHEN width_bucket( bytes/1024, 2049, 4096, 1) = 1 THEN 1 ELSE 0 END AS to4096,
  CASE WHEN width_bucket( bytes/1024, 4097, 8192, 1) = 1 THEN 1 ELSE 0 END AS to8192,
    CASE WHEN width_bucket( bytes/1024, 8193, 10480000, 1) = 1 THEN 1 ELSE 0 END AS over8192
from dba_free_space 
where tablespace_name like '&TABLESPACE'
)
select sum(to64),
      sum(to128),
       sum(to256),
       sum(to512),
       sum(to1024),
       sum(to2048),
       sum(to4096),
       sum(to4096),
       sum(over8192)
from pivot_table;


prompt
prompt =========================================================================================
prompt

set feedback on



