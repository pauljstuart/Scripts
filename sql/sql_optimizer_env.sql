
select
        child_number, name, value
from    gv$sql_optimizer_env
where
        sql_id = '&SQL_ID'
order by
        child_number,
        name;    

