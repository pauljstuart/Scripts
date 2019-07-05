
prompt
prompt normal tablespaces :
prompt

column max_size_mb format 999,999,999;
column total_used_mb format 999,999,999;
column free_mb format 999,999,999;
column tablespace_name format A30
column pct_used format 999.9;
WITH 
 used_size as
  (
  SELECT TABLESPACE_NAME, SUM(blocks)*(select value/(1024*1024) from v$parameter where name = 'db_block_size' ) total_used_mb
  FROM dba_segments
  where tablespace_name not in ('USERS','TOOLS','SYSAUX','SYSTEM') 
   and tablespace_name not like 'UNDO%'
   and tablespace_name not like 'TEMP%'
  GROUP BY TABLESPACE_NAME
  ),
max_size as
(
SELECT tablespace_name,
    SUM(DECODE(autoextensible, 'YES', maxblocks, blocks))*(select value/(1024*1024) from v$parameter where name = 'db_block_size' )  max_size_mb
  FROM dba_data_files
  where tablespace_name not in ('USERS','TOOLS','SYSAUX','SYSTEM') 
   and tablespace_name not like 'UNDO%'
   and tablespace_name not like 'TEMP%'
  GROUP BY tablespace_name
)
SELECT max_size.tablespace_name, 
       max_size_mb,
       total_used_mb,
       max_size_mb - total_used_mb  free_mb,
      NVL( total_used_mb*100/max_size_mb,0) pct_used
FROM max_size
LEFT OUTER JOIN used_size on max_size.tablespace_name = used_size.tablespace_name
order by 5 desc;

prompt
prompt UNDO tablespaces : 
prompt

column max_size_mb format 999,999,999
column unexpired_undo_mb format 999,999,999
column active_undo_mb format 999,999,999
column free_undo_mb format 999,999,999
column total_used_mb format 999,999,999

with used_undo_extents as
(
  select tablespace_name, 
        sum(case when status = 'UNEXPIRED' then blocks else 0 end)*(SELECT VALUE/(1024*1024)  FROM v$parameter WHERE NAME = 'db_block_size') as unexpired_undo_mb,
        sum(case when status = 'ACTIVE'    then blocks else 0 end)*(SELECT VALUE/(1024*1024)  FROM v$parameter WHERE NAME = 'db_block_size') as active_undo_mb
  from dba_undo_extents
  group by tablespace_name
),
max_undo as 
(
  select tablespace_name
             , sum (decode (autoextensible, 'YES', maxbytes, bytes))/(1024*1024) max_size_mb
        from   dba_data_files
        where  tablespace_name in (select tablespace_name
                                     from  dba_tablespaces
                                    where  retention like '%GUARANTEE')
        group by tablespace_name
 ) 
select max_undo.tablespace_name , 
       max_size_mb,  
       unexpired_undo_mb,
       active_undo_mb, 
       unexpired_undo_mb + active_undo_mb total_used_mb, 
       (max_size_mb - unexpired_undo_mb - active_undo_mb) free_undo_mb,
       NVL( (unexpired_undo_mb + active_undo_mb)*100/max_size_mb, 0) as pct_used
from max_undo,  used_undo_extents 
where max_undo.tablespace_name = used_undo_extents.tablespace_name;


prompt
prompt TEMP usage :
prompt

column maxsize_mb format 999,999,999
column used_mb format 999,999,999
column free_mb format 999,999,999


WITH  
u as
(
SELECT TABLESPACE, SUM(blocks)*(select value/(1024*1024) from v$parameter where name = 'db_block_size') total_used_mb
  FROM gv$tempseg_usage
  GROUP BY TABLESPACE
),
f as
(
SELECT tablespace_name,
    SUM(DECODE(autoextensible, 'YES', maxblocks, blocks))*(select value/(1024*1024) from v$parameter where name = 'db_block_size') as max_size_mb
  FROM dba_temp_files
  GROUP BY tablespace_name
)
SELECT f.tablespace_name, 
       max_size_mb, 
       total_used_mb, 
       max_size_mb - total_used_mb free_mb,
       NVL( total_used_mb*100/max_size_mb, 0)  pct_used
FROM  f left outer join u on f.tablespace_name = u.tablespace;





