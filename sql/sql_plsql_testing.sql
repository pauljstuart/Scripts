


-------------------------------------------------------------------------
-- run this block inside sql developer using F5
-------------------------------------------------------------------------


/* alter session set current_schema=PORTRECPROD; */
/*alter session set cursor_sharing = 'FORCE'; */
/* alter session set OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES='TRUE' ; */
ALTER SESSION SET  statistics_level='ALL';
alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss';



COLUMN MODULE FORMAT A30
set verify off
set wrap off
set linesize 3000
set pagesize 3000
set serveroutput off
define MODULE_NAME=PJS2
column sql_id_var           new_value my_sql_id
column child_number_var     new_value my_child_no
column sid                  new_value my_sid
column serial#              new_value my_serial

clear screen

prompt
prompt ================================ run test SQL ================================================================================
prompt



---------------------------------------------
-- insert bind variables here
---------------------------------------------


var B1 NUMBER                                                                                                                                                                                                                                                                                       
var B2 VARCHAR2(30)                                                                                                                                                                                                                                                                   
var B3 VARCHAR2(30)                                                                                                                                                                                                                                                                    
var B4 NUMBER                                                                                                                                                                                                                                                                                   
var B5 NUMBER                                                                                                                                                                                                                                                                                    
var B6 NUMBER

exec :B1 := 4833                                                                                                                                                                                                                                                                                       
exec :B2 :=  'BNPP'                                                                                                                                                                                                                                                                    
exec :B3 := 'CDS'                                                                                                                                                                                                                                                                     
exec :B4 := 48335                                                                                                                                                                                                                                                                                       
exec :B5 := 3303                                                                                                                                                                                                                                                                                        
exec :B6 := 4833 

exec dbms_application_info.set_module('&MODULE_NAME','testing');
SET TIMING ON


---------------------------------------------
-- insert sql text here
---------------------------------------------




select portrecaud0_.AUDITID as AUDITID451_, portrecaud0_.AuditDate as                                                                                                                                                                                                                                        
AuditDate451_, portrecaud0_.UserName as UserName451_,                                                                                                                                                                                                                                                        
portrecaud0_.Action as Action451_, portrecaud0_.AuditInfo as                                                                                                                                                                                                                                                 
AuditInfo451_, portrecaud0_.Type as Type451_, portrecaud0_.CompanyId as                                                                                                                                                                                                                                      
CompanyId451_, portrecaud0_.HasAttachments as HasAttac9_451_,                                                                                                                                                                                                                                                
portrecaud0_.PortfolioId as Portfol10_451_ from PortfolioAuditTrail                                                                                                                                                                                                                                          
portrecaud0_, PortfolioPosition portrecpos1_ where                                                                                                                                                                                                                                                           
portrecaud0_.ReconType='DAILY' and portrecaud0_.PortfolioId=portrecpos1_                                                                                                                                                                                                                                     
.PORTFOLIOID and portrecpos1_.ClientId=3266 and                                                                                                                                                                                                                                                              
portrecaud0_.CompanyId=3266 and portrecpos1_.Status='O'  
/

SET TIMING OFF

exec dbms_application_info.set_module(NULL,NULL);

prompt
prompt ========================================================================================================================
prompt


------------------------------
-- Now get the last SQL_ID
------------------------------

prompt
prompt Here is the SQL against &MODULE_NAME :
prompt

select sql_id as sql_id_var, child_number as child_number_var, module, last_active_time, sql_text
from v$sql
where  module = '&MODULE_NAME'
and sql_id is not null
AND ( SQL_TEXT like '%select%' or SQL_TEXT like '%SELECT%' )
order by last_active_time asc;


SELECT dbms_debug_jdwp.current_session_id sid,
       dbms_debug_jdwp.current_session_serial serial#
FROM dual;

------------------------------
-- Now get the execution plan
------------------------------

prompt
prompt
prompt
prompt

-- select * from table( dbms_xplan.display_cursor( '&my_sql_id', &my_child_no, 'ROWS IOSTATS MEMSTATS LAST') );

@sql/xplan.display_cursor.sql &my_sql_id &my_child_no  "ALLSTATS LAST BASIC -COST  -BYTES +OUTLINE +ALIAS +NOTE"









