--
--
prompt PGA stat for the instance you are on now :
--

column name format a50
column value_mb  format 999,999,999,999 


select name,  value/(1024*1024)  as value_mb
from v$pgastat
where unit = 'bytes';

select name, value from v$pgastat where unit = 'percent'; 

