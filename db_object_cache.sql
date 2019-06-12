define OWNER=&1

COLUMN EXECUTIONS FORMAT 999,999,999;
COLUMN Mem_used   FORMAT 999,999,999;
column owner format A30
column type format A20
column name format A20

SELECT owner,
       type,
       name,
       executions,
       sharable_mem       Mem_used,
       loads,
       pins ,
       SUBSTR(kept||' ',1,4)   "Kept?"
 FROM v$db_object_cache
 WHERE TYPE IN ('TRIGGER','PROCEDURE','PACKAGE BODY','PACKAGE')
and owner like '&OWNER'
 ORDER BY EXECUTIONS DESC;
