



--@sql/xplan.display_cursor.sql 







-- to get the last sql :
 select * from table( dbms_xplan.display_cursor(NULL, NULL,  format => 'ADVANCED' ) );
--select * from table( dbms_xplan.display_cursor( NULL, NULL,  'ALLSTATS LAST BASIC -COST  -BYTES +ALIAS +NOTE +OUTLINE') );

-- remember to set serveroutput off!

--select * from table ( dbms_xplan.display_cursor (null,null, 'ADVANCED'));

