col PARAM1 new_value 1 format A10
col PARAM2 new_value 2 format A10
col PARAM3 new_value 3 format A10

select null PARAM1, null PARAM2, null PARAM3 from dual where 1=2;
select nvl( '&1','&_USER') PARAM1, nvl('&2','%') PARAM2, nvl('&3',0)  PARAM3 from dual ;


define USERNAME=&1
define TABLE_NAME=&2     
define ROW_SIZE=&3

undefine 1
undefine 2
undefine 3

column LOCATION format A100


SELECT *
FROM ALL_EXTERNAL_LOCATIONS
WHERE 
            TABLE_name LIKE '&TABLE_NAME'
            AND OWNER = '&USERNAME'
ORDER BY TABLE_NAME;

