
column 1 new_value 1
column 2 new_value 2
column 3 new_value 3
select null as "1",      null as "2",      null as "3"
from   dual 
where  1=2;

column DBID            new_value DBID
column SQL_ID          new_value SQL_ID
column FORMAT          new_value FORMAT
column PLAN_HASH_VALUE new_value PLAN_HASH_VALUE

select DBID,      
	'&1'                 as sql_id,      
	nvl('&2', 'NULL')    as plan_hash_value,      
	nvl('&3', 'ADVANCED') as format
from   gv$database
where  inst_id = sys_context('userenv','instance');


undefine 1
undefine 2
undefine 3

with xplan_data0 as
        (
        select plan_table_output,  substr( '|....+....+....+....+....+....+....+....+....+....+....+', 1, length( regexp_substr( plan_table_output, '(\|\ +)', 2 ) ) ) as paul_string
        from  table(dbms_xplan.display_awr( '&SQL_ID' , &PLAN_HASH_VALUE, &DBID, 'ADVANCED ALLSTATS LAST'))
        )
select regexp_replace( plan_table_output, '(^\|[\* 0-9]+)(\|\ +)(.*)', '\1' || paul_string || '\3' ) as plan_table_output
from xplan_data0;


--select * from table( dbms_xplan.display_awr('&SQL_ID', &PLAN_HASH, NULL,  format => 'ADVANCED +OUTLINE' ) );

--@sql/xplan.display_awr.sql &SQL_ID &PLAN_HASH  "ADVANCED ALLSTATS LAST +PREDICATE"




