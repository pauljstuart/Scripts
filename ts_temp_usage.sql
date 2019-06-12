set echo off

col p1 new_value 1
col p2 new_value 2
col p3 new_value 3
select null p1, null p2, null p3 from dual where 1=2;
select nvl( '&1','TEMP1') p1 from dual ;

define TEMP_TABLESPACE_NAME=&1 
undefine 1
undefine 2
undefine 3




undefine 1
undefine 2



COLUMN PCT_USED FORMAT 99.9






prompt
prompt Based on dba_temp_free_space
prompt


column size_mb format 999,999,999
column total_mb format 999,999,999

select tablespace_name,
       tablespace_size/(1024*1024) total_max_mb, 
       (tablespace_size - free_space)/(1024*1024) total_used_mb , 
       (tablespace_size - free_space)*100/tablespace_size pct_used 
from dba_temp_free_space;

prompt
prompt Based on v$temp_space_header
prompt



select tablespace_name,  sum(bytes_used+bytes_free)/(1024*1024) total_mb , sum(bytes_used)/(1024*1024) used_mb, sum(bytes_free)/(1024*1024) free_mb
from v$temp_space_header
group by tablespace_name;



prompt
prompt instance unbalance
prompt


with pivot1 as
(
select 
   inst_id, 
   tablespace_name, 
   total_blocks instance_total, 
free_blocks instance_free, 
   sum(total_blocks) over (partition by tablespace_name) tablespace_total
from 
   gv$sort_segment
 where tablespace_name = '&TEMP_TABLESPACE_NAME'
)
select tablespace_name, inst_id, trunc(instance_free*100/tablespace_total) instance_percent
from pivot1;





prompt
prompt based on v$tempseg_usage :
prompt

column maxsize_gb format 999,999,999
column used_gb format 999,999,999
column free_gb format 999,999,999
column pct_used format A10

WITH  
u as
(
SELECT TABLESPACE, SUM(blocks) tot_used_blocks
  FROM gv$tempseg_usage
  GROUP BY TABLESPACE
),
f as
(
SELECT tablespace_name,
    SUM(DECODE(autoextensible, 'YES', maxblocks, blocks)) total_blocks
  FROM dba_temp_files
  GROUP BY tablespace_name
), 
blocksize as (select value/(1024*1024*1024) as bsize_gb from v$parameter where name = 'db_block_size')
SELECT f.tablespace_name, 
       to_char(trunc( f.total_blocks*(select bsize_gb from blocksize) ), '999,999,999') maxsize_gb, 
       to_char(trunc( u.tot_used_blocks*(select bsize_gb from blocksize) ),'999,999,999') used_gb, 
       to_char(trunc( (f.total_blocks - u.tot_used_blocks)*(select bsize_gb from blocksize) ),'999,999,999') free_gb,
       trunc((u.tot_used_blocks/f.total_blocks)*100 ) || '%' pct_used
FROM  f left outer join u on f.tablespace_name = u.tablespace;

PROMPT
prompt detail report from v$tempseg_usage for &TEMP_TABLESPACE_NAME :
prompt


column temp_used_mb format 999,999,999
column total_temp_used_mb format 999,999,999
column workarea_size_mb format 999,999,999.9
column expected_size_mb format 999,999,999.9
column actual_mem_used_mb format 999,999,999.9
column max_mem_used_mb format 999,999,999.9
column client_info format A10
column machine format A30

prompt
prompt note sql_id is often wrong in v$tempseg_usage
prompt

WITH pivot1 AS
(
select value/(1024*1024) as block_size_mb from v$parameter where name = 'db_block_size' 
)
 SELECT sysdate, b.username, b.inst_id,  b.segtype, b.sql_id,  b.tablespace,
                                      b.blocks*(select block_size_mb from pivot1) temp_used_mb, 
                                      sum( b.blocks*(select block_size_mb from pivot1) ) over () total_temp_used_mb ,
                                      a.inst_id, a.username, a.sid, a.serial#, a.osuser,  a.process, a.machine, a.sql_id, a.prev_sql_id, a.module, a.client_info,
                                      '|',
                                      C.SQL_ID, C.SQL_EXEC_ID, C.ACTIVE_TIME, C.WORK_AREA_SIZE/(1024*1024) workarea_size_mb, C.EXPECTED_SIZE/1024/1024 expected_size_mb, C.ACTUAL_MEM_USED/1024/1024 actual_mem_used_mb, C.MAX_MEM_USED/1024/1024 max_mem_used_mb, C.NUMBER_PASSES, C.TEMPSEG_SIZE/(1024*1024) tempseg_mb
                --                      D.sql_text
FROM  gv$tempseg_usage b
inner JOIN gv$session a  ON b.inst_id = a.inst_id  and a.saddr = b.session_addr
left outer join gv$sql_workarea_active C ON b.inst_id = C.inst_id and  b.tablespace = C.tablespace and b.SEGRFNO# = C.SEGRFNO# and b.SEGBLK# = C.SEGBLK#
--left outer join gv$sqlarea D ON c.inst_id = D.inst_id AND  c.sql_id = D.sql_id 
 WHERE 
 b.tablespace =  '&TEMP_TABLESPACE_NAME';


 /* 

-- a simple query on v$tempseg_usage

WITH pivot1 AS
(
select value/(1024*1024) as block_size_mb from v$parameter where name = 'db_block_size' 
)
SELECT sysdate, b.username, b.inst_id,  a.sid, a.serial#, a.osuser, b.segtype, 
       tablespace, 
       contents, 
        segtype, 
        extents, 
        blocks*(select block_size_mb from pivot1) size_mb,
        SUM(blocks*(select block_size_mb from pivot1)) over ( ) as total_mb,
         c.sql_text
     FROM  gv$tempseg_usage b
     inner JOIN gv$session a  ON b.inst_id = a.inst_id  and a.saddr = b.session_addr
     left outer join gv$sqlarea c ON b.inst_id = c.inst_id AND  b.sql_id = c.sql_id 
     WHERE 
           b.tablespace = '&TEMP_TABLESPACE_NAME';

*/

