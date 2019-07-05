



col P_USER new_value 1 format A20
col P_TABLENAME new_value 2 format A20
col P_PARTNAME new_value 3 format A20

select null P_USER, null P_TABLENAME, null P_PARTNAME from dual where 1=2;
select nvl( '&1','&_USER') P_USER, nvl('&2','%') P_TABLENAME, nvl('&3','%')  P_PARTNAME from dual ;


define OWNER=&1
define TABLE_NAME=&2     
define PART_NAME=&3

undefine 1
undefine 2
undefine 3


prompt
prompt Querying for &TABLE_NAME in &OWNER, &DAYS_AGO days ago.
prompt


PROMPT
PROMPT DBA_TAB_STATS_HISTORY :
PROMPT

select owner, table_name, partition_name, subpartition_name, stats_update_time
from dba_tab_stats_history
where table_name like '&TABLE_NAME'
AND owner = '&OWNER'
AND stats_update_time > trunc(sysdate) - &DAYS_AGO
order by stats_update_time;


prompt
prompt _opstat_tab_history : GLOBAL :
prompt

COLUMN ANALYZETIME FORMAT a20

select obj#, analyzetime,  rowcnt as NUM_ROWS, samplesize
from sys.wri$_optstat_tab_history 
where obj# in (select object_id from dba_objects where object_name = '&TABLE_NAME' and owner = '&OWNER' and subobject_name is null)
and  analyzetime > trunc(sysdate) - &DAYS_AGO
 order by analyzetime asc; 



prompt
prompt _opstat_tab_history : PARTITIONS :
prompt


select obj#, (SELECT distinct OBJECT_NAME FROM DBA_OBJECTS WHERE OBJECT_ID = O.obj#) as object_name, (SELECT distinct subOBJECT_NAME FROM DBA_OBJECTS WHERE OBJECT_ID = O.obj#) as subobject_name ,analyzetime,  rowcnt as NUM_ROWS, samplesize
from sys.wri$_optstat_tab_history O
INNER JOIN DBA_OBJECTS DO on DO.object_id = O.obj#
where DO.object_name = '&TABLE_NAME' and DO.owner = '&OWNER' and DO.subobject_name like '&PART_NAME'
--where obj# in (select object_id from dba_objects where object_name = '&TABLE_NAME' and owner = '&OWNER' and subobject_name = '&PART_NAME')
and  analyzetime > trunc(sysdate) - &DAYS_AGO
 order by analyzetime asc; 





