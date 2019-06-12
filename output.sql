


column P_PROCESS new_value 1 format A10
column P_SEARCH new_value 2 format A10
column P_REFERENCE new_value 3 format A10

select NULL P_PROCESS, null P_SEARCH, null P_REFERENCE from dual where 1=2;
select nvl( '&1','DEFAULT') P_PROCESS , nvl( '&2','%') P_SEARCH , nvl( '&3', '%' ) P_REFERENCE  from dual ;

define PROCESS=&1
define SEARCH=&2
define REFERENCE=&3

undefine 1
UNDEFINE 2
undefine 3


column  PROCESS_NAME   format A30
column  PROCESS_START_TIME  format A20
column  LOG_LEVEL format 999
column LOG_TIME  format A20
column  LOG_TEXT   format A100
column   REFERENCE format 999,999
column  ERROR_CODE format A10


SELECT *
FROM
(
select process_START_TIME, PROCESS_NAME, LOG_LEVEL,  LOG_TIME,  LOG_TEXT,REFERENCE, ERROR_CODE, ROW_NUMBER() OVER (ORDER BY LOG_TIME DESC) ROW_NUM
 from outputlog 
where log_text like '&SEARCH'
AND REFERENCE like '&REFERENCE'
AND PROCESS_NAME LIKE '&PROCESS'
order by log_TIME
)
WHERE ROW_NUM < 200; 
