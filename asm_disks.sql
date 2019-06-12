
col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10


select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','DATA') PARAM1 ,  nvl( '&2','%') PARAM2 from dual ;


define DISK_GROUP=&1
define DISK_NAME=&2

undefine 1
undefine 2


COLUMN PATH FORMAT a100
COLUMN TOTAL_GB FORMAT 999,999,999,999
COLUMN free_GB FORMAT 999,999,999,999
column name format A100

SELECT
	group_number,
	disk_number,
	mount_status,
	state,
	redundancy,
	library,
	total_mb/1024 TOTAL_GB,
	free_mb/1024  FREE_gb,
	name,
	path,
	product,
	create_date
FROM
	v$asm_disk
WHERE
 	upper(name) LIKE UPPER('%&DISK_NAME%')
 AND GROUP_NUMBER = (SELECT GROUP_NUMBER FROM V$ASM_DISKGROUP WHERE NAME = '&DISK_GROUP')
 ORDER BY
	group_number,
	disk_number;
	
