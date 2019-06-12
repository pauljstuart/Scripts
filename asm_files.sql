


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','DATA') PARAM1 from dual ;


define DISK_GROUP=&1

undefine 1
undefine 2
undefine 3



PROMPT  showing all datafiles :

column group_number format 999
column file_number format 999
column type format A10
column creation_date format A21
COLUMN NAME FORMAT a30
column size_gb format 999,999,999,999
column size_gb format 999,999,999,999

SELECT /*+ leading(ADG) use_hash(ADG) use_hash(f) use_hash(a)  */  f.group_number, ADG.NAME DISKGROUP_NAME,  f.file_number, a.name, f.type, f.block_size,  f.permissions,trunc(f.bytes/(1024*1024*1024),1) bytes_gb, trunc(f.space/(1024*1024*1024),1) allocated_space_gb, redundancy, creation_date
FROM v$asm_file f
inner join v$asm_alias a on  f.group_number=a.group_number and f.file_number=a.file_number
inner join v$asm_diskgroup ADG on ADG.group_number = F.group_number and ADg.name = '&DISK_GROUP'
WHERE F.GROUP_NUMBER = (SELECT GROUP_NUMBER FROM V$ASM_DISKGROUP WHERE NAME = '&DISK_GROUP');

/*
select type,sum(bytes)/1024/1024 Mb 
from v$asm_file where type in ('ARCHIVELOG','AUTOBACKUP','BACKUPSET','ONLINELOG','DATAFILE') 
group by type order by type; 
*/

select dg.name,f.type,sum(bytes)/1024/1024 Mb 
from v$asm_file f, v$asm_diskgroup dg 
where f.group_number=dg.group_number 
and dg.group_number= (SELECT GROUP_NUMBER FROM V$ASM_DISKGROUP WHERE NAME = '&DISK_GROUP')
--where type in ('ARCHIVELOG','AUTOBACKUP','BACKUPSET','ONLINELOG') 
group by dg.name,f.type order by dg.name,type; 




-- summing the size of each type of file in a particular diskgroup


COLUMN diskgroup_spacetotal_mb FORMAT 999,999,999,999
COLUMN type format A20


with 
pivot1 as
(
select  dg.name,
        f.type,
        sum(space)/1024/1024 total_mb
from v$asm_file f, v$asm_diskgroup dg 
where f.group_number=dg.group_number 
and dg.group_number= (SELECT GROUP_NUMBER FROM V$ASM_DISKGROUP WHERE NAME = '&DISK_GROUP')
--where type in ('ARCHIVELOG','AUTOBACKUP','BACKUPSET','ONLINELOG') 
group by dg.name,f.type order by dg.name,type
)
select pivot1.*, sum(total_mb) over ( partition by name) as diskgroup_spacetotal_mb
from pivot1;
