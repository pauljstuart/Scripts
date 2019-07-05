----------------------------------------------------------------------------------------------
--
-- Global Missing Stats Report
--
-- by Paul Stuart, Database Performance Team,
--
-- Date : Oct 2018
--
-- This is a very simple report which identifies any partition tables or columns which are missing global statistics.
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
--
set verify off
SET pagesize  9999
SET heading   ON
set linesize 300
set tab off
set feedback off
--
set termout off
--
col REGEXP1 new_value 2
--
select null REGEXP1 from dual where 1=2; 
select nvl('&2','BKP') REGEXP1 from dual;
--
define SCHEMA_NAME=&1
define REGEXP_PATTERN=&2
--
undefine 1
undefine 2
set termout on
--



select owner, table_name, partitioned,  last_analyzed
from
  dba_tables 
where owner = '&SCHEMA_NAME'
and partitioned  = 'YES'
and last_analyzed is NULL
and table_name not like '%TEMP%'
and table_name not like '%TMP%'
and table_name not like 'M$%'
and table_name not like '%TEST%'
and table_name not like '%TST%'
and table_name not like '%LOG%'
and table_name not like '%BACKUP%'
and table_name not like 'M$%'
and table_name not like 'CMP%'
and not regexp_like( table_name, '&REGEXP_PATTERN');


select owner, index_name, table_name, partitioned,  last_analyzed
from dba_indexes
where owner = '&SCHEMA_NAME'
and  index_type != 'LOB'
and last_analyzed is NULL
and partitioned  = 'YES'
and table_name not like '%TEMP%'
and table_name not like '%TMP%'
and table_name not like 'M$%'
and table_name not like '%TEST%'
and table_name not like '%TST%'
and table_name not like '%LOG%'
and table_name not like '%BACKUP%'
and table_name not like 'M$%'
and table_name not like 'CMP%'
and not regexp_like( table_name, '&REGEXP_PATTERN');


--
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
and table_name not like 'CMP%'
and not regexp_like( table_name, '&REGEXP_PATTERN')
--and not exists (select 1 from dba_views V where V.owner = C.owner and V.view_name = C.table_name)
and exists (select 1 from dba_part_tables P where P.owner = C.owner and P.table_name = C.table_name)
and last_analyzed is NULL;
--
