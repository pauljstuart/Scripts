
column name format A50
column parameter1 format A30
column parameter2 format A30
column parameter3 format A30
column wait_class format A10

break on wait_class page skip 1 dup


select 
 name, 
 WAIT_CLASS ,
 EVENT_ID ,
 EVENT#   ,
 PARAMETER1  ,
 PARAMETER2 ,
 PARAMETER3
from v$event_name
where name like '&event_name'
order by 2;


