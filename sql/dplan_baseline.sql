



define SQL_PLAN_NAME=&1;


column plan_table_output format A100
select * from table (dbms_xplan.display_sql_plan_baseline(NULL, '&SQL_PLAN_NAME', 'typical OUTLINE'));

