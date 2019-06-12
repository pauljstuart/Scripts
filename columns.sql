

col P_OWNER new_value 1 format A10
col P_TABLE_NAME new_value 2 format A20
col P_COL_NAME new_value 3 format A20

select null P_OWNER, null P_TABLE_NAME, null P_COL_NAME from dual where 1=2;
select nvl( '&1','&_USER') P_OWNER, nvl('&2','%') P_TABLE_NAME, nvl('&3','%')  P_COL_NAME from dual ;


define OWNER=&1
define TABLE_NAME=&2
define COLUMN_NAME=&3

undefine 1
undefine 2
undefine 3
column DATA_LENGTH format 999,999
column DATA_PRECISION format 999.999
column DATA_SCALE format 999,999
column nullable format A10
column default_length format 9999,999
column comments format A100
prompt
prompt Columns for table : &OWNER - &TABLE_NAME
prompt


SELECT 
   DTC.owner, 
   DTC.table_name,
   DTC.column_name,
   column_id,
   data_type,
   data_length,
   data_precision,
   data_scale,
   nullable,
   default_length,
   data_default, 
   comments
FROM dba_tab_columns DTC
inner join dba_col_comments DTC2 on DTC.owner = DTC2.owner and DTC.table_name = DTC2.table_name and DTC.column_name = DTC2.column_name 
WHERE 
    DTC.table_name LIKe '&TABLE_NAME'
AND DTC.owner LIKE '&OWNER'
AND DTC.column_name like '&COLUMN_NAME'
order by column_id;


prompt
prompt hidden columns 
prompt

select table_name, column_name
from dba_tab_cols T1
where owner = '&OWNER'
and table_name = '&TABLE_NAME'
and  not exists (select 1 from dba_tab_columns T2 where owner = '&OWNER' and table_name = '&TABLE_NAME' and T1.column_name = T2.column_name );


prompt
prompt Indexes for column  : &COLUMN_NAME
prompt


SELECT T1.owner, t1.table_name, 
       t1.index_name, 
       t1.tablespace_name,  
       t1.index_type Type , 
       t2.COLUMN_position column_pos,
       t2.COLUMN_name, t1.status, 
       t1.blevel BLVL, t1.last_analyzed
from dba_indexes t1, dba_ind_COLUMNs t2
where t1.index_name = t2.index_name
AND T1.owner = '&OWNER'
AND T2.column_name LIKE '&COLUMN_NAME'
and t1.table_name = '&TABLE_NAME'
order by t1.table_name, t1.index_name, t2.COLUMN_position ;

