


col P_USER new_value 1 format A10
col P_PKEY new_value 2 format A10


select null P_USER, null P_PKEY  from dual where 1=2;
select nvl( '&1','&_USER') P_USER, nvl('&2','%') P_PKEY from dual ;

define OWNER=&1
define PRIMARY_KEY=&2     

undefine 1
undefine 2



COLUMN child_owner FORMAT A30
COLUMN column_name FORMAT A30
COLUM child_constraint_name FORMAT A30


SELECT A.owner, A.constraint_name, A.constraint_type, A.table_name, T.partitioned table_partitioned, A.index_owner, A.index_name, A.status, I.uniqueness, I.partitioned as index_partitioned
FROM dba_constraints A
INNER JOIN DBA_INDEXES I on I.owner = A.owner and I.index_name = A.index_name
inner join dba_tables T on T.owner = A.owner and T.table_name = A.table_name
WHERE (A.constraint_name LIKE '&PRIMARY_KEY' or A.table_name like '&PRIMARY_KEY' )
AND constraint_type = 'P'
AND A.OWNER LIKE '&OWNER';


prompt
prompt Foreign keys for &PRIMARY_KEY :
prompt

SELECT C.owner,
       C.r_constraint_name parent_key,
       C.owner child_owner, 
       C.table_name child_table, 
       C.constraint_name as child_constraint_name, 
       A.column_name,
       A.position,
       C.constraint_type
FROM DBA_cons_columns A
INNER JOIN DBA_constraints C ON A.constraint_name = C.constraint_name AND A.owner = C.owner
WHERE C.r_constraint_name LIKE '&PRIMARY_KEY'
AND C.OWNER LIKE '&OWNER';


undefine OWNER
undefine PRIMARY_KEY
