
col p1 new_value 1
col p2 new_value 2
select null p1, null p2, null p3 from dual where 1=2;
select nvl( '&1','%') p1 from dual ;

define SQL_ID=&1     

undefine 1
undefine 2



-- from SQL monitor

COLUMN bind_variables format A200

select sql_id, 
        sql_exec_id,
       extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=1]/attribute::name') || '  '  || extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=1]') || ' ' ||
      extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=2]/attribute::name') || '  '  || extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=2]') || ' ' ||
      extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=3]/attribute::name') || '  '  || extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=3]') || ' ' ||
      extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=4]/attribute::name') || '  '  || extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=4]') || ' ' ||
      extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=5]/attribute::name') || '  '  || extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=5]') || ' ' ||
      extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=6]/attribute::name') || '  '  || extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=6]') || ' ' ||
      extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=7]/attribute::name') || '  '  || extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=7]') || ' ' ||
      extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=8]/attribute::name') || '  '  || extractvalue( xmltype(binds_xml) , '/binds/bind[@pos=8]') bind_variables
from v$sql_monitor
where binds_xml is not null
and sql_id like '&SQL_ID';




/*

SELECT SQL_ID,
       NAME, 
       POSITION, 
       DATATYPE_STRING, 
       VALUE_STRING
FROM v$sql_bind_capture 
WHERE sql_id='&SQL_ID';





SELECT snap_id, SQL_ID,NAME,POSITION,DATATYPE_STRING,VALUE_STRING
FROM DBA_HIST_SQLBIND  
where SNAP_ID between 11621 and 11767
and SQL_ID = 'a8j39qb13tqkr'
ORDER by 1;
*/
