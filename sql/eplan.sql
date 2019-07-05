 WHERE STATEMENT_ID = 'pjs';
commit;



alter session set current_schema=franco;

explain plan INTO franco.plan_table set statement_id='pjs' for  
SELECT :1,
          WORKFLOW_ID,




SELECT * FROM TABLE( DBMS_XPLAN.DISPLAY( table_name => 'franco.PLAN_TABLE', STATEMENT_ID => 'pjs', format => 'ADVANCED' ) );
