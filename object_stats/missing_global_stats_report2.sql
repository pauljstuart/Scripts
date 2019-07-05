
----------------------------------------------------------------------------------------------
--
-- Global Stats Report
--
-- by Paul Stuart, Database Performance Team, 
--
-- Date : Dec 2016
--
-- This is a very simple report which identifies any tables or columns which are missing global statistics.
--
-- Input parameters :
--
--  input parameter 1 : SCHEMA_NAME 
--  input parameter 2 : REGULAR_EXPRESSION (filters out any tables which match this expression) 
--
-----------------------------------------------------------------------------------------------

column owner format A20
column table_name format A30
column column_name format A30
column last_analyzed format A12


set verify off
SET pagesize  9999
SET heading   ON
set linesize 300
set feedback on



col P_SCHEMA new_value 1 format A10
col P_REGEXP new_value 2 format A10

select null P_SCHEMA, null P_REGEXP from dual where 1=2;
select nvl( '&1','&_USER') P_SCHEMA, nvl('&2','%') P_REGEXP from dual ;


define SCHEMA_NAME=&1
define REGEXP_PATTERN=&2     

undefine 1
undefine 2



select S.owner, S.table_name, S.last_analyzed
from 
  dba_tab_statistics S  
where owner = '&SCHEMA_NAME'
and S.object_type = 'TABLE'
and table_name not like '%TEMP%'
and table_name not like '%TMP%'
and table_name not like 'M$%'
and table_name not like '%TEST%'
and table_name not like '%TST%'
and table_name not like '%LOG%'
and table_name not like '%BACKUP%'
and table_name not like 'M$%'
and not regexp_like( table_name, '&REGEXP_PATTERN')
and  S.last_analyzed is NULL ;

select owner, index_name, table_name,  last_analyzed
from dba_indexes 
where owner = '&SCHEMA_NAME'
and table_name not like '%TEMP%'
and table_name not like '%TMP%'
and table_name not like 'M$%'
and table_name not like '%TEST%'
and table_name not like '%TST%'
and table_name not like '%LOG%'
and table_name not like '%BACKUP%'
and table_name not like 'M$%'
and not regexp_like( table_name, '&REGEXP_PATTERN')
and  index_type != 'LOB'
and last_analyzed is NULL;

select owner, table_name, column_name, last_analyzed
from dba_tab_columns C
where owner = '&SCHEMA_NAME'
and table_name not like '%TEMP%'
and table_name not like '%TMP%'
and table_name not like 'M$%'
and table_name not like '%TEST%'
and table_name not like '%TST%'
and table_name not like '%LOG%'
and table_name not like '%BACKUP%'
and table_name not like 'M$%'
and not regexp_like( table_name, '&REGEXP_PATTERN')
and not exists (select 1 from dba_views V where V.owner = C.owner and V.view_name = C.table_name)
and last_analyzed is NULL;
