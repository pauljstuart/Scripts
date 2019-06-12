



col P1 new_value 1 format A10
col P2 new_value 2 format A10

select null p1, null p2 from dual where 1=2;
select nvl( '&1','%') p1, nvl('&2','%') p2 from dual ;

  
define SEARCH=&1  


undefine 1
undefine 2
undefine 3

COLUMN name  FORMAT a40
COLUMN value FORMAT a70
COLUMN SID   FORMAT A15


prompt 
prompt spfile : &SEARCH
prompt 



break on SID duplicates skip page

SELECT 
      sid, name, value
FROM 
     v$spparameter
WHERE 
   value is not null 
   and name like '&SEARCH'
 and isspecified = 'TRUE'
ORDER by  SID, name;






   
