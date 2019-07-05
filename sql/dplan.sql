set echo off

define MY_SQL_ID=&1
define MY_CHILD_NO=&2

--@sql/xplan.display_cursor.sql &my_sql_id &my_child_no  "ALLSTATS LAST BASIC -COST  -BYTES +OUTLINE +ALIAS +NOTE"

/*
SELECT x.plan_table_output
FROM table(dbms_xplan.display_cursor('01zcawnwqvdp1',0 ,'BASIC')) x;
*/


@sql/display_cursor.sql &my_sql_id &my_child_no  "ALLSTATS LAST ALL  -BYTES +NOTE +OUTLINE +ALIAS  +PARTITION +PARALLEL -PROJECTION"
