
with start1 as
(
select name,   value,  
    to_number(substr(value,2,2))*86400  + to_number(substr(value,5,2))*3600 +to_number(substr(value,8,2))*60  +to_number(substr(value,11,2))apply_lag_secs
from v$dataguard_stats
where name = 'apply lag'
)
select name,  to_char( apply_lag_secs ,'999,999,999,999') apply_lag_secs
from start1
where apply_lag_secs >= 0;

