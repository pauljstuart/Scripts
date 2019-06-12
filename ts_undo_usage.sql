


column TOTAL_ACTIVE_MB format 999,999,999
column TOTAL_UNEXPIRED_MB format 999,999,999
column TOT_TS_SIZE_mb format 999,999,999
column pct_used format 999.9


select ue.tablespace_name, nvl(round((sum(ue.used_bytes) / df.tot_ts_size) * 100, 2),0) pct_used
from   (select tablespace_name, nvl(sum(bytes), 0) used_bytes
        from   dba_undo_extents
        where  status in ('ACTIVE','UNEXPIRED')
        and    tablespace_name in (select tablespace_name
                                     from dba_tablespaces
                                    where  retention like '%GUARANTEE')
        group by tablespace_name) ue
     , (select tablespace_name
             , sum (decode (autoextensible, 'YES', maxbytes, bytes)) tot_ts_size
        from   dba_data_files
        where  tablespace_name in (select tablespace_name
                                     from  dba_tablespaces
                                    where  retention like '%GUARANTEE')
        group by tablespace_name) df
where  ue.tablespace_name(+) = df.tablespace_name
group by ue.tablespace_name, df.tot_ts_size;



prompt
prompt breakdown into active and UNEXPIRED: 
prompt


column max_size_gb format 999,999,999
column unexpired_undo_gb format 999,999,999.9
column active_undo_gb format 999,999,999.9
column free_undo_gb format 999,999,999.9
column total_undo_gb format 999,999,999.9

with used_undo_extents as
(
  select tablespace_name, 
        sum(case when status = 'UNEXPIRED' then blocks else 0 end)*(SELECT VALUE/(1024*1024*1024)  FROM v$parameter WHERE NAME = 'db_block_size') as unexpired_undo_gb,
        sum(case when status = 'ACTIVE'    then blocks else 0 end)*(SELECT VALUE/(1024*1024*1024)  FROM v$parameter WHERE NAME = 'db_block_size') as active_undo_gb
  from dba_undo_extents
  group by tablespace_name
),
max_undo as 
(
  select tablespace_name
             , sum (decode (autoextensible, 'YES', maxbytes, bytes))/(1024*1024*1024) max_size_gb
        from   dba_data_files
        where  tablespace_name in (select tablespace_name
                                     from  dba_tablespaces
                                    where  retention like '%GUARANTEE')
        group by tablespace_name
 ) 
select max_undo.tablespace_name , 
       max_size_gb,  
       unexpired_undo_gb,
       active_undo_gb, 
       unexpired_undo_gb + active_undo_gb total_undo_gb, 
       (max_size_gb - unexpired_undo_gb - active_undo_gb) free_undo_gb,
       (unexpired_undo_gb + active_undo_gb)*100/max_size_gb as pct_used
from max_undo,  used_undo_extents 
where max_undo.tablespace_name = used_undo_extents.tablespace_name;







