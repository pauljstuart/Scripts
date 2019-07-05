


-- calculate 3 column join selectivity  :

-- setup the column variables :

define OWNER1=MVDS
define TABLE1=POSTING
define T1COL1=PARTITION_ID
define T1COL2=WORKFLOW_ID

--
define OWNER2=MVDS
define TABLE2=NEUTRAL_CONTROL
define T2COL1=PARTITION_ID
define T2COL2=WORKFLOW_ID

--- 

column col_name format A20
column column_selectivity format  0.999999999999
column column_density format  0.999999999999
column ndv format 999,999,999,999,999
COLUMN JOIN_SELECTIVITY FORMAT 0.999999999999


-- display the column data types  :

select owner, table_name, column_name, data_type
from all_tab_columns
where owner = '&OWNER1' and table_name in ('&TABLE1') AND COLUMN_NAME IN ('&T1COL1','&T1COL2')
UNION ALL
select owner, table_name, column_name, data_type
from all_tab_columns
where owner = '&OWNER2' and table_name in ('&TABLE2') AND COLUMN_NAME IN ('&T2COL1','&T2COL2');



PROMPT
PROMPT The selectivity and density from each column :
prompt




column column_selectivity format  0.999999999999
column column_density format  0.999999999999
column ndv format 999,999,999,999,999





select table_name,  column_name,num_distinct as NDV, 1/num_distinct as column_selectivity, density density, histogram , num_buckets,  num_nulls 
from all_tab_col_statistics
where 
    (table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1')
OR  (table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL2')
OR  (table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL1')
OR  (table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL2');



-- calculating the join selectivity and cardinality :

column &T1COL1._selectivity format 0.999999
column &T1COL2._selectivity format 0.999999
column T1_&T1COL1._ndv FORMAT 999,999,999
column T1_&T1COL2._ndv FORMAT 999,999,999
column T2_&T2COL1._ndv FORMAT 999,999,999
column T2_&T2COL2._ndv FORMAT 999,999,999
column join_cardinality FORMAT 999,999,999,999


-- one column :

select  T1COL1.num_distinct as  T1_&T1COL1._ndv ,  
        T2COL1.num_distinct  as T2_&T2COL1._ndv,
       1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct )) as &T1COL1._selectivity,
       1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct ))        as join_selectivity ,
      1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct )) *  T1_filtered_cardinality.num_rows * T2_filtered_cardinality.num_rows as join_cardinality

from 
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1'
) T1COL1, 
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL1'
) T2COL1,
( 
--select num_rows from dba_tables where owner = '&OWNER1' AND table_name = '&TABLE1'
select 180 as num_rows from dual
) T1_filtered_cardinality,
( 
--select num_rows from dba_tables where owner = '&OWNER1' AND table_name = '&TABLE1'
select 18000000 as num_rows from dual
) T2_filtered_cardinality;

-- 2 join columns :

select  T1COL1.num_distinct as  T1_&T1COL1._ndv ,  
        T2COL1.num_distinct  as T2_&T2COL1._ndv,
       1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct )) as &T1COL1._selectivity,
       T1COL2.num_distinct as T2_&T1COL2._ndv ,  
      T2COL2.num_distinct as T2_&T2COL2._ndv,
       1/(greatest( T1COL2.num_distinct ,  T2COL2.num_distinct ))  as &T1COL2._selectivity,
       1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct )) *
       1/(greatest( T1COL2.num_distinct ,  T2COL2.num_distinct ))        as join_selectivity ,
      1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct )) *  1/(greatest( T1COL2.num_distinct ,  T2COL2.num_distinct )) * T1_filtered_cardinality.num_rows * T2_filtered_cardinality.num_rows as join_cardinality

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
) T2COL2,
( 
--select num_rows from dba_tables where owner = '&OWNER1' AND table_name = '&TABLE1'
select 911 as num_rows from dual
) T1_filtered_cardinality,
( 
--select num_rows from dba_tables where owner = '&OWNER1' AND table_name = '&TABLE1'
select 611000000 as num_rows from dual
) T2_filtered_cardinality;


@show_histogram &OWNER1 &TABLE1 &T1COL1

---- an example of doing a join analysis 
 


SELECT /*+ PARALLEL(16 */
     Z.PARTITION_ID, Z.WORKFLOW_ID, COUNT(*)
FROM
      mvds.posting Z,
      mvds.neutral_control NC
WHERE
      nc.partition_id                = z.partition_id
    AND nc.intraday_location_id NOT IN ( 'USRGA', 'GRPCN','GRPCP')
    AND nc.workflow_id               = z.workflow_id
AND z.GAAP_CODE IN ('001', '002', '007')
GROUP BY  Z.PARTITION_ID, Z.WORKFLOW_ID
ORDER BY Z.PARTITION_ID;


PARTITION_ID                                 WORKFLOW_ID         COUNT(*)
---------------- --------------------------------------- ----------------
1358_WMCH1                                          1358           83,229
1358_WMCH2                                          1358        9,029,082
1358_WMCH3                                          1358           22,495
1370_WMCH1                                          1370           70,860
1370_WMCH2                                          1370        8,817,962
1370_WMCH3                                          1370           21,890
1371_WMCH1                                          1371           70,860
1371_WMCH2                                          1371        8,818,560
1371_WMCH3                                          1371           21,890
1374_WMCH1                                          1374           70,860
1374_WMCH2                                          1374        8,817,389


------------------------------------  PL/SQL code to calculate cardinality ---------------------------------------------------------------------------------------------------------------

set serveroutput on
declare 

T1COL1_num_distinct INTEGER;
T2COL1_num_distinct INTEGER;
T1COL2_num_distinct INTEGER;
T2COL2_num_distinct INTEGER;
T1COL3_num_distinct INTEGER;
T2COL3_num_distinct INTEGER;
T1COL1_density NUMBER;
T2COL1_density NUMBER;
T1COL2_density NUMBER;
T2COL2_density NUMBER;
T1COL3_density NUMBER;
T2COL3_density NUMBER;


T1_num_rows INTEGER;
T2_num_rows INTEGER;

join_selectivity  NUMBER;
join_cardinality INTEGER;
join_selectivity_col1 NUMBER ;
join_selectivity_col2 NUMBER ;
join_selectivity_col3 NUMBER ;
begin


select num_distinct into T1COL1_num_distinct from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1';

select num_distinct into T1COL2_num_distinct from all_tab_col_statistics 
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL2';


select num_distinct into T2COL1_num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL1';

select num_distinct into T2COL2_num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL2';


SELECT num_rows INTO T1_num_rows from dba_tables where owner = '&OWNER1' and table_name = '&TABLE1';
SELECT num_rows INTO T2_num_rows from dba_tables where owner = '&OWNER2' and table_name = '&TABLE2';

-- enter filtered cardinality here :
T1_num_rows := 400000000;
T2_num_rows := 900;

join_selectivity :=  1/(greatest( T1COL1_num_distinct ,  T2COL1_num_distinct )) *
                     1/(greatest( T1COL2_num_distinct ,  T2COL2_num_distinct ))   ;

join_selectivity_col1 :=  1/(greatest( T1COL1_num_distinct ,  T2COL1_num_distinct )) ;
join_selectivity_col2 :=  1/(greatest( T1COL2_num_distinct ,  T2COL2_num_distinct )) ;


join_cardinality := join_selectivity * T1_num_rows * T2_num_rows;

DBMS_OUTPUT.PUT_LINE('join selectivity col1 : ' || lpad(to_char(join_selectivity_col1,'0.999999'),35)  );
DBMS_OUTPUT.PUT_LINE('join selectivity col2 : ' || lpad(to_char(join_selectivity_col2,'0.999999'),35)  );


DBMS_OUTPUT.PUT_LINE('Overall join selectivity : ' || lpad(to_char(join_selectivity,'0.999999'),35)  );

DBMS_OUTPUT.PUT_LINE('T1 filtered cardinality : ' || lpad(to_char(T1_num_rows,'999,999,999,999,999'),35)  );
DBMS_OUTPUT.PUT_LINE('T2 filtered cardinality : ' || lpad(to_char(T2_num_rows,'999,999,999,999,999'),35)  );


DBMS_OUTPUT.PUT_LINE('Overall join cardinality : ' || lpad(to_char(join_cardinality,'999,999,999,999,999'),35));


DBMS_OUTPUT.PUT_LINE('Using the density :' );


select density into T1COL1_density from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1';

select density into T1COL2_density from all_tab_col_statistics 
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL2';


select density into T2COL1_density from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL1';

select density into T2COL2_density from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL2';



join_selectivity := least( T1COL1_density ,  T2COL1_density ) *
       least( T1COL2_density ,  T2COL2_density )   ;



join_selectivity_col1 :=  least( T1COL1_density ,  T2COL1_density ) ;
join_selectivity_col2 :=     least( T1COL2_density ,  T2COL2_density )   ;

join_cardinality := join_selectivity * T1_num_rows * T2_num_rows;

DBMS_OUTPUT.PUT_LINE('join selectivity col1 : ' || join_selectivity_col1 );
DBMS_OUTPUT.PUT_LINE('join selectivity col2 : ' || join_selectivity_col2 );


DBMS_OUTPUT.PUT_LINE('join selectivity : ' || join_selectivity );
DBMS_OUTPUT.PUT_LINE('join cardinality : ' || join_cardinality );

end;
/

--------------------------------------------------------------------------------------------------------------------------

-- old code - calculating the join selectivity :

select 1/(greatest( T1COL1.num_distinct ,  T2COL1.num_distinct )) *
       1/(greatest( T1COL2.num_distinct ,  T2COL2.num_distinct ))  
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
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL1'
) T2COL1,
(
select num_distinct from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL2'
) T2COL2
;



select least( T1COL1.density ,  T2COL1.density ) *
       least( T1COL2.density ,  T2COL2.density )   
       as join_selectivity
from 
(
select density from all_tab_col_statistics
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL1'
) T1COL1, 
(
select density from all_tab_col_statistics 
where table_name = '&TABLE1' and owner = '&OWNER1' AND COLUMN_NAME = '&T1COL2'
) T1COL2,
(
select density from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL1'
) T2COL1,
(
select density from all_tab_col_statistics
where table_name = '&TABLE2' and owner = '&OWNER2' AND COLUMN_NAME = '&T2COL2'
) T2COL2
;

--------------------------------------------------------------------------------------------------------------------------






---------------------- Fixing the column values ----------------------------------------------------------------------------------



-- MVDSS1 original values :

begin
 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'NEUTRAL_CONTROL', colname => 'PARTITION_ID',
 distcnt => 4848 );

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'NEUTRAL_CONTROL', colname => 'WORKFLOW_ID',
 distcnt => 722 );

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'POSTING', colname => 'PARTITION_ID',
 distcnt => 3158 );

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'POSTING', colname => 'WORKFLOW_ID',
 distcnt => 589 );


end;
/

-- MVDST1 original values :



begin
 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'NEUTRAL_CONTROL', colname => 'PARTITION_ID',
 distcnt => 939 );

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'NEUTRAL_CONTROL', colname => 'WORKFLOW_ID',
 distcnt => 111 );

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'POSTING', colname => 'PARTITION_ID',
 distcnt => 397 );

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'POSTING', colname => 'WORKFLOW_ID',
 distcnt => 116 );


end;
/

begin
  dbms_stats.gather_table_stats( ownname => '&OWNER1', tabname => '&TABLE1', 
        granularity => 'GLOBAL', 
         degree => 32, 
         method_opt => 'FOR COLUMNS SIZE AUTO &T1COL1,&T1COL2', 
       estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE );
end;
/


begin
  dbms_stats.gather_table_stats( ownname => '&OWNER2', tabname => '&TABLE2', 
        granularity => 'GLOBAL', 
         degree => 32, 
         method_opt => 'FOR COLUMNS SIZE AUTO &T2COL1,&T2COL2', 
       estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE );
end;
/

begin
  dbms_stats.gather_table_stats( ownname => 'MVDS', tabname => 'POSTING', 
        granularity => 'GLOBAL', 
         degree => 32, 
         method_opt => 'FOR COLUMNS SIZE AUTO GAAP_CODE', 
       estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE );
end;
/


begin

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'NEUTRAL_CONTROL', colname => 'WORKFLOW_ID',
 distcnt => 40 );
 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'POSTING', colname => 'WORKFLOW_ID',
 distcnt => 40 );


end;
/





begin

 DBMS_STATS.set_column_stats (ownname => '&OWNER1', tabname =>
  '&TABLE1', colname => '&T1COL2',
 density => 0.002 );

 DBMS_STATS.set_column_stats (ownname => '&OWNER2', tabname =>
  '&TABLE2', colname => '&T2COL2',
 density => 0.002);
end;
/


begin
 DBMS_STATS.set_column_stats (ownname => '&OWNER1', tabname =>
  '&TABLE1', colname => '&T1COL1',
 density => 0.05 );

 DBMS_STATS.set_column_stats (ownname => '&OWNER2', tabname =>
  '&TABLE2', colname => '&T2COL1',
 density => 0.05 );


 DBMS_STATS.set_column_stats (ownname => '&OWNER1', tabname =>
  '&TABLE1', colname => '&T1COL2',
 density => 0.05 );

 DBMS_STATS.set_column_stats (ownname => '&OWNER2', tabname =>
  '&TABLE2', colname => '&T2COL2',
 density => 0.05 );
end;
/

commit;


begin
 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'NEUTRAL_CONTROL', colname => 'PARTITION_ID',
 distcnt => 80 );

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'NEUTRAL_CONTROL', colname => 'WORKFLOW_ID',
 distcnt => 80 );

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'POSTING', colname => 'PARTITION_ID',
 distcnt => 80 );

 DBMS_STATS.set_column_stats (ownname => 'MVDS', tabname =>
  'POSTING', colname => 'WORKFLOW_ID',
 distcnt => 80 );


end;
/


-- setting the density manually :

SET serveroutput ON
DECLARE
  srec DBMS_STATS.STATREC;
  low_value_raw RAW (32);
  high_value_raw RAW (32);
  low_value_value  NUMBER;
  high_value_value NUMBER;
  max_value        NUMBER;
  m_distcnt        NUMBER;
  m_density        NUMBER;
  m_nullcnt        NUMBER;
  m_avgclen        NUMBER;
  novals DBMS_STATS.NUMARRAY;
BEGIN
  -------------------- get the current values from get_column_stats----------------------------------------

  DBMS_STATS.get_column_stats (ownname => '&OWNER2',
       tabname =>'&TABLE2', colname => '&T2COL1',
  distcnt => m_distcnt, density => m_density, nullcnt => m_nullcnt, srec => srec, avgclen => m_avgclen );

  DBMS_OUTPUT.put_line ('                                               ');
  DBMS_OUTPUT.put_line ('============== Get Column Stats =================');
  DBMS_OUTPUT.put_line ('Distinct Value Count:' || m_distcnt);
  DBMS_OUTPUT.put_line ('Column Density:' || m_density);
  DBMS_OUTPUT.put_line ('Null Value Count:' || m_nullcnt);
  DBMS_OUTPUT.put_line ('Average Column Length:' || m_avgclen);
  DBMS_OUTPUT.put_line (' The Number of the input parameter:' || srec.epc);
  DBMS_OUTPUT.put_line (' Minimum raw:' || srec.minval);
  DBMS_OUTPUT.put_line (' Maximum raw:' || srec.maxval);

/*
  FOR i IN 1 .. srec.novals.COUNT
  LOOP
    DBMS_OUTPUT.put_line ( ' The Input Value ' || i ||  ' For Novals Number Array Is:' || srec.novals (i) );
  END LOOP;
  DBMS_OUTPUT.put_line ('                                               ');
 
 
  --------------------------- prepare the novals array with the correct values ------------------------------------
  -- use this to set them to an arbitrary value
  low_value_value  := 20160226;
  high_value_value := 20160226;
  novals           := DBMS_STATS.numarray (low_value_value,high_value_value);
  srec.bkvals      := NULL;
  srec.epc         := 2;
  DBMS_OUTPUT.put_line ('Setting the column stats now.');
  DBMS_STATS.prepare_column_values (srec, novals);
  ----------------------- now set the column stats with new values --------------------------------------------------------------
  DBMS_OUTPUT.put_line ('                                               ');
  DBMS_STATS.set_column_stats (ownname => '&OWNER1', tabname =>
  '&TABLE1', colname => '&T1COL1',
  distcnt => m_distcnt, density => m_density, nullcnt => m_nullcnt, srec =>
  srec, avgclen => m_avgclen );
*/


 DBMS_STATS.set_column_stats (ownname => '&OWNER2', tabname =>
  '&TABLE2', colname => '&T2COL1',
 density => 0.1 );

  ----  Check the values by after executing the dbms_stats.set_column_values  ----------------------
  DBMS_STATS.get_column_stats (ownname => '&OWNER2', tabname =>
  '&TABLE2', colname => '&T2COL1',
  distcnt => m_distcnt, density => m_density, nullcnt => m_nullcnt, srec =>
  srec, avgclen => m_avgclen );

  DBMS_OUTPUT.put_line ('============== After Set Column Stats ===========');
  DBMS_OUTPUT.put_line ('Distinct Value Count:' || m_distcnt);
  DBMS_OUTPUT.put_line ('Column Density:' || m_density);
  DBMS_OUTPUT.put_line ('Null Value Count:' || m_nullcnt);
  DBMS_OUTPUT.put_line ('Average Column Length:' || m_avgclen);
  DBMS_OUTPUT.put_line (' The Number of the input parameter:' || srec.epc);
  DBMS_OUTPUT.put_line (' Minimum raw:' || srec.minval);
  DBMS_OUTPUT.put_line (' Maximum raw:' || srec.maxval);

/*
  FOR i IN 1 .. srec.novals.COUNT
  LOOP
    DBMS_OUTPUT.put_line ( ' The Input Value ' || i ||
    ' For Novals Number Array Is:' || srec.novals (i) );
  END LOOP;
  COMMIT;
*/

end;
/
