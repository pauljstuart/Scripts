

COLUMN property_value FORMAT A80
COLUMN dbid FORMAT 9999999999




select dbid, name, db_unique_name, open_mode, database_role  from v$database;


select property_name, property_value
from database_properties
where property_name = 'GLOBAL_DB_NAME' ;
