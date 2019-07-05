


col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10


select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','%') PARAM1, nvl('&2','%') PARAM2 from dual ;


define SQL_ID=&1  

undefine 1
undefine 2



prompt 
prompt SQL profiles like &SQL_ID
prompt

COLUMN FORCE_MATCHING FORMAT a20
COLUMN DESCRIPTION FORMAT a50

select name, 
       category, 
       created,
       last_modified,
       status, 
       force_matching,
       signature,
      DESCRIPTION,
        regexp_replace(sql_text, '[[:cntrl:]]',null) as sql_text
from dba_sql_profiles
where   
    (DESCRIPTION LIKE '%&SQL_ID.%' OR NAME LIKE '%&SQL_ID.%')
order by last_modified;

