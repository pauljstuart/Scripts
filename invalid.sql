
column object_name format A40
column object_type format A40;

clear screen


select owner, object_name, object_type,LAST_DDL_TIME, status
from dba_objects 
where status = 'INVALID'
order by owner ;


