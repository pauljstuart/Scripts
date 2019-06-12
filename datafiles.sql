--
-- datafiles.sql
--
-- Show the layout of the datafiles for the database
--
-- Paul Stuart
-- Nov 2004
-- july 2012


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','%') PARAM1, nvl('&2','%') PARAM2 from dual ;


define TABLESPACE_NAME=&1


undefine 1
undefine 2
undefine 3

column file_name format a70;
column Auto format A4;
column max_size_gb format 999,999,999;
column size_gb format 999,999,999
column increment_gb format 999,999,999
column total_size_gb format 999,999,999,999
column total_db_size_gb format 999,999,999,999

prompt
prompt Data files for &TABLESPACE_NAME:
prompt

WITH pivot1 AS
(
select value/(1024*1024*1024) as block_size_gb from v$parameter where name = 'db_block_size' 
),
pivot2 as
(
select tablespace_name, file_id, 
       file_name, 
        status, 
        autoextensible Auto, 
        increment_BY*(select block_size_gb from pivot1) increment_gb,
        maxbytes/(1024*1024*1024) max_size_gb, 
        bytes/(1024*1024*1024) size_gb
from dba_data_files
where tablespace_name like '&TABLESPACE_NAME'
union all
select tablespace_name,  
       file_id,
       file_name, 
       status, 
       autoextensible Auto, 
      increment_BY*(select block_size_gb from pivot1) increment_gb,
       maxbytes/(1024*1024*1024) max_size_gb,
       bytes/(1024*1024*1024) size_gb
from dba_temp_files
where tablespace_name like '&TABLESPACE_NAME'
)
select pivot2.*, 
       sum(size_gb) over () total_size_gb
from pivot2
order by tablespace_name;

