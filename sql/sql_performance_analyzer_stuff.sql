


----------------------------------------------------------
-- running a SQL tuning task using SQL Performance Analyzer
-----------------------------------------------------------






  
  
  EXEC DBMS_SQLPA.EXECUTE_ANALYSIS_TASK( task_name         => :sts_task, execution_type    => 'CONVERT_SQLSET', execution_name    => 'after_change');
  
  
  SELECT DBMS_SQLPA.REPORT_ANALYSIS_TASK(:sts_task) from dual;






-------------------------------------------------------------------------------------
---  Using SPA to analyze before and after :
-------------------------------------------------------------------------------------



11.  Prepare your SQL tuning set

You may want to remove any DML from the STS! :

begin
  dbms_sqltune.delete_sqlset( 'MSINF_9355', ' upper(sql_text) like ''%DELETE%'' ' );
  dbms_sqltune.delete_sqlset( 'MSINF_9355', ' upper(sql_text) like ''%UPDATE%'' ' );
  dbms_sqltune.delete_sqlset( 'MSINF_9355', ' upper(sql_text) like ''%INSERT%'' ' );
  dbms_sqltune.delete_sqlset( 'MSINF_9355', ' upper(sql_text) like ''%BEGIN%'' ' );
end;


12.  Make a snapshot

13.	Configure the baseline environment

ie set the parameter to its initial value

14.	Create the Analysis Task


declare
   STS_TASK VARCHAR(64);
begin
  sts_task := DBMS_SQLPA.CREATE_ANALYSIS_TASK(  sqlset_name    =>   'MSINF_9355', task_name => 'MSINF_9355_SPA_TASK'); 
  DBMS_OUTPUT.PUT_LINE('output ' || sts_task );
end;


 
15.	execute the sql performance analyzer task

BEGIN
dbms_sqlpa.execute_analysis_task(
	task_name => 'MSINF_9355_SPA_TASK', 
	execution_type => 'TEST EXECUTE',
	execution_name => 'initial_sql_trial');
END;



16.	reconfigure the environment
change the value to its new setting

17.	analyze the changed environment

Make sure you give it a different execution_name !

begin
	dbms_sqlpa.execute_analysis_task(
		task_name => 'MSINF_9355_SPA_TASK',
		execution_name => 'post_change_sql_trial' );
end;



How to do when upgrading from 10g to 11g?

First, go ahead and do the upgrade in a test environment.
Then, you make sure that the parameter OPTMIZER_FEATURES_ENABLE is set to the version of your 10g database.
You then run the pre-change analysis with the that parameter set .

You then set the OPTIMIZER_FEATURES_ENABLE to 11.2.0.0.0 and run the analysis again.


18.	compare the results

BEGIN
   DBMS_SQLPA.EXECUTE_ANALYSIS_TASK(task_name => 'my_spa_task', 
	execution_type => 'COMPARE PERFORMANCE', 
	execution_name => 'my_exec_compare', 
	execution_params => dbms_advisor.arglist('comparison_metric', 'buffer_gets'));
END;


19.	generate the analysis Report

var rep CLOB;
exec :rep := DBMS_SQLPA.REPORT_TUNING_TASK('MY_PARAMETER_TEST_001', 'text' );

20.	



Data dictionary views of interest

DBA_ADVISOR_EXECUTIONS
DBA_ADVISOR_TASKS
DBA_ADVISOR_FINDINGS
DBA_ADVISOR_SQLPLANS
DBA_ADVISOR_SQLSTATS


