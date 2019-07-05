

column T1_CARDINALITY format 999,999,999
column T2_CARDINALITY format 999,999,999
COLUMN JOIN_SELECTIVITY FORMAT 0.999999999999


-- calculate 1 column join selectivity  :

define OWNER1=APP_BO_STAGE
define TABLE1=MV_BO_PROFIT_CTR
define T1COL1=PROFIT_CTR
--
define OWNER2=MVDS
define TABLE2=POSTING
define T2COL1=SAP_MANAGEMENT_CENTER

select 1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct ))        as join_selectivity
from 
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1'
) T1COL1, 
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL1'
) T2COL1;



-- getting total row counts :

SELECT NUM_ROWS AS &TABLE1._STATS_ROWCOUNT
FROM DBA_TAB_STATISTICS
WHERE OWNER = '&OWNER1' AND TABLE_NAME = '&TABLE1';

SELECT COUNT(*) AS &TABLE1._ACTUAL_ROWCOUNT
FROM &OWNER1..&TABLE1;



SELECT NUM_ROWS AS &TABLE2._STATS_ROWCOUNT
FROM DBA_TAB_STATISTICS
WHERE OWNER = '&OWNER2' AND TABLE_NAME = '&TABLE2';

SELECT COUNT(*) AS &TABLE2._ACTUAL_ROWCOUNT
FROM &OWNER2..&TABLE2;



-- calculate 2 column join selectivity  :

define OWNER1=APP_BO_STAGE
define TABLE1=MV_BO_PROFIT_CTR
define T1COL1=PROFIT_CTR
define T1COL2=XXXXX
--
define OWNER2=MVDS
define TABLE2=POSTING
define T2COL1=SAP_MANAGEMENT_CENTER
define T2COL2=YYYY
select 1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct )) *
       1/(greatest( T1COL2.num_distinct ,  T2COL2.num_distinct ))        as join_selectivity
from 
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1'
) T1COL1, 
(
select num_distinct from all_tab_col_statistics 
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL2'
) T1COL2,
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL1'
) T2COL1,
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL2'
) T2COL2;




-- calculate 3 column join selectivity  :

define OWNER1=ONEBALANCE
define TABLE1=LAP_ASSET_REPORT
define T1COL1=LAP_ACC_REPORT_ID
define T1COL2=VALUE_DATE
define T1COL3=COMPLETE_ID
--
define OWNER2=ONEBALANCE
define TABLE2=LAP_ACCOUNT_REPORT
define T2COL1=ID
define T2COL2=VALUE_DATE	
define T2COL3=COMPLETE_ID

select 1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct )) *
       1/(greatest( T1COL2.num_distinct ,  T2COL2.num_distinct ))  *
       1/(greatest( T1COL3.num_distinct ,  T2COL3.num_distinct ))  
       as join_selectivity
from 
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1'
) T1COL1, 
(
select num_distinct from all_tab_col_statistics 
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL2'
) T1COL2,
(
select num_distinct from all_tab_col_statistics 
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL3'
) T1COL3,
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL1'
) T2COL1,
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL2'
) T2COL2,
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL3'
) T2COL3
;

PROMPT
PROMPT The selectivity and density from each column :
prompt

column T1COL1_selectivity format 0.999999999999
column T1COL1_density     format 0.999999999999
column T1COL2_selectivity format 0.999999999999
column T1COL2_density     format 0.999999999999
column T1COL3_selectivity format 0.999999999999
column T1COL3_density     format 0.999999999999

column T2COL1_selectivity format 0.999999999999
column T2COL1_density     format 0.999999999999
column T2COL2_selectivity format 0.999999999999
column T2COL2_density     format 0.999999999999
column T2COL3_selectivity format 0.999999999999
column T2COL3_density     format 0.999999999999

select 1/num_distinct as T1COL1_selectivity, density as T1COL1_density, histogram , num_buckets from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1';

select 1/num_distinct as T1COL2_selectivity, density as T1COL2_density, histogram , num_buckets from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL2';

select 1/num_distinct as T1COL3_selectivity, density as  T1COL3_density, histogram , num_buckets from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL3';

select 1/num_distinct as T2COL1_selectivity, density as T2COL1_density, histogram , num_buckets from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1';

select 1/num_distinct as T2COL2_selectivity, density as T2COL2_density, histogram , num_buckets from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL2';

select 1/num_distinct as T2COL3_selectivity, density as  T2COL3_density, histogram , num_buckets from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL3';




begin
  dbms_stats.gather_table_stats( ownname => '&OWNER1', tabname => '&TABLE1', 
        granularity => 'GLOBAL', 
         degree => 8, 
         method_opt => 'FOR COLUMNS SIZE AUTO &T1COL1,&T1COL2,&T1COL3', 
       estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE );
end;
/


begin
  dbms_stats.gather_table_stats( ownname => '&OWNER2', tabname => '&TABLE2', 
        granularity => 'GLOBAL', 
         degree => 8, 
         method_opt => 'FOR COLUMNS SIZE AUTO &T2COL1,&T2COL2,&T2COL3', 
       estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE );
end;
/
