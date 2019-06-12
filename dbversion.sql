 

column oracle_home format A50

select inst_id, substr(value, 1, length(value) - length(substr(value, instr(value,'dbs')))) oracle_home
from gv$parameter
where name = 'spfile';


column product format A40
column version format A20
column status  format A20

select * from product_component_version;



prompt
prompt patching history :
prompt


COLUMN comments FORMAT A30

--select * from sys.registry$history;
