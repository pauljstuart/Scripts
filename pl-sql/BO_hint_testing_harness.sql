
-- creating the STS :


DECLARE
        ref_cur DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN


DBMS_SQLTUNE.delete_SQLSET('BO_QUERIES_ETIME');

open ref_cur for select VALUE(p) from table( DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY( 
                      begin_snap => 524, end_snap => 1060, 
              basic_filter => q'#parsing_schema_name = 'APP_BO_ONSHORE' and elapsed_time > 120*1000000 and command_type = 3 and sql_id in (
'5k0axx9crwa0r',
'5xfmjusf5hd96',
'2x9jsnvyxhpkg',
'0byrfzgktpx3c',
'anbaf6p0uzvws',
'dd5tpajpj46v1',
'gsfp2banbtsm2',
'5wth4zm4pwuyu',
'5urjfjczc1yrg',
'79r4wtqvs2d8v',
'df5wg8k0adbvf',
'59vxbtmxp36w7',
'cqpwyc4c07dqz',
'b962xn1uc5f3m',
'1rt88rcy2ntsv',
'78wrpq017a4u6',
'1zy9ucrb9ypsq',
'6kzkm6r0z0s8a',
'c3prz2ny1ctvn',
'25q8pw4bdpnhd')
 #'
     )) p;
DBMS_SQLTUNE.LOAD_SQLSET('BO_QUERIES_ETIME', ref_cur);
end;


BEGIN
DBMS_SQLTUNE.CREATE_SQLSET ( sqlset_name => 'BO_QUERIES_ETIME', description => 'BO Queries to check');

END;
exec dbms_sqltune.drop_sqlset ('BO_QUERIES_ETIME');

EXEC DBMS_SQLTUNE.delete_SQLSET('BO_QUERIES_ETIME');


@awr/awr_snapshot

----------------------------------------------------------------------------
-- Load in all the SQL from a set of AWR snapshots (ie a after period)
----------------------------------------------------------------------------

DECLARE
        ref_cur DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN

DBMS_SQLTUNE.delete_SQLSET('BO_QUERIES_ETIME');

open ref_cur for select VALUE(p) from table( DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY( 
                      begin_snap => 524, end_snap => 773, 
              basic_filter => q'#parsing_schema_name = 'APP_BO_ONSHORE' and elapsed_time > 120*1000000 and command_type = 3 and sql_id = '76nd7dx8g4wjd' #'
     )) p;
DBMS_SQLTUNE.LOAD_SQLSET('BO_QUERIES_ETIME', ref_cur);
end;


desc user_sqlset_statements

@AWR/AWR_SNAPSHOT
SELECT count(*) FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET( 'BO_QUERIES_ETIME' ) );

set serveroutput on 


select sqlset_name, 
	sql_id, 
	plan_hash_value, 
	elapsed_time, 
	cpu_time, 
	buffer_gets, 
	disk_reads, 
	rows_processed, 
	fetches, 
	executions, 
	optimizer_cost,
  DBMS_LOB.SUBSTR(sql_text, 50, dbms_lob.getlength(sql_text) -50 )
  sql_text
from ALL_sqlset_statements
WHERE SQLSET_NAME = 'BO_QUERIES_ETIME'
AND SQLSET_OWNER = 'PERF_SUPPORT'

and sql_id = '76nd7dx8g4wjd';


exec  dbms_sqltune.delete_sqlset( 'BO_QUERIES_ETIME', ' sql_text like ''%PJS%'' ' );

@ash/awr_sqlstats ('37gg588cq01vw')


--------------------------------------------------------------------------------------------------------------------------------------------------
-- BO testing harness
-------------------------------------------------------------------------------------------------------------------------------------------------



clear screen
set serveroutput on 
set echo off



alter session set current_schema=APP_BO_ONSHORE;
ALTER SESSION SET  statistics_level='ALL';




declare

  cursor_name      INTEGER;
  cursor_name2      INTEGER;

 new_hint VARCHAR2(4000) := ' /*+ monitor parallel(4) OPT_ESTIMATE(JOIN (FC0.Z FC0.NC) MIN=100000000)    USE_merge(FC0.lh) use_merge(FC0.ah) use_merge(FC0.fh)   PQ_DISTRIBUTE(FC0.fh HASH HASH) PQ_DISTRIBUTE(FC0.ah HASH HASH) PQ_DISTRIBUTE(FC0.lh HASH HASH)  PQ_DISTRIBUTE(gcr_core HASH HASH) leading( FC0.lh FC0.nc FC0.z FC0.ah FC0.fh)  use_hash (gcr_core)  Full(gcr_derived) use_hash (gcr_derived)   Full(gcr_inst) use_hash (gcr_inst) Full(gcr_lnf) use_hash (gcr_lnf)   use_hash(prod) use_hash(prod_supplemental)      */ ';

  module_string VARCHAR2(256);
  vSQL_ID VARCHAR2(13);
  iSQL_CHILD NUMBER;
  iSQL_EXEC_ID NUMBER;
  Plan_Cost NUMBER;
  Percent_Difference NUMBER;
  i_ret NUMBER;
  total_fetches NUMBER;
  i_elapsed_time NUMBER;
  timestart        NUMBER ;
  ret  INTEGER;

  i_elapsed_time1 INTEGER;
  i_LIO1 INTEGER;
  i_fetches1 INTEGER;
  sql_id1 VARCHAR2(13);

  i_elapsed_time2 INTEGER;
  i_LIO2 INTEGER;
  i_fetches2 INTEGER;
  sql_id2 VARCHAR2(13);

begin


  DBMS_OUTPUT.PUT_LINE( chr(10) || 'ORIG_SQL_ID  SQL_ID1  FETCHES1  ETIME1 LIO1 --- SQL_ID2 FETCHES2 ETIME2 LIO2' );

  for sts_cursor in (


select sqlset_name, 
	sql_id, 
   sql_text, 
  regexp_replace( sql_text, '(.*)\/\*\+(.*)\*\/(.*)', '\1' || new_hint || '\3' ) as sql_text_newhint,
	optimizer_cost
from user_sqlset_statements
where sqlset_name = 'BO_QUERIES_ETIME'
and sql_id = 'cqpwyc4c07dqz'
order by elapsed_time


  )
  loop
  
  /*
      if ( sts_cursor.optimizer_cost < 1000000) 
    then
       continue;
    end if;
  */

---------------------------------------------------------------------------------------------------------------
    -- now parse and run the unmodified statement :

   -- dbms_output.put_line('Examining ' || sts_cursor.sql_id );

  
    select    mod(abs(dbms_random.random),100000)+1 into module_string from dual ;
    module_string :=  'PJS2_' || module_string;
    total_fetches := 0;
    timestart  := dbms_utility.get_time();


   BEGIN
    if ( DBMS_SQL.IS_OPEN(cursor_name) )
    THEN
       DBMS_SQL.CLOSE_CURSOR(cursor_name);
    end if;
    cursor_name := DBMS_SQL.OPEN_CURSOR;
    dbms_application_info.set_module(module_string,'testing');
    DBMS_SQL.PARSE(cursor_name,   '/* ' || module_string || ' */ '  || sts_cursor.sql_text  , DBMS_SQL.NATIVE);
     ret := DBMS_SQL.EXECUTE(cursor_name);
    dbms_application_info.set_module( NULL, NULL);
    EXCEPTION
      WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Issues compiling SQL ' || sts_cursor.sql_id || ' ' || SQLERRM);
      dbms_application_info.set_module( NULL, NULL);
     CONTINUE;
   end ;

  -- fetch all the rows 
  
   LOOP                                        
    ret := DBMS_SQL.FETCH_ROWS(cursor_name);
    EXIT WHEN ret = 0;
    total_fetches := total_fetches + 1;
  END LOOP;

  DBMS_SQL.CLOSE_CURSOR(cursor_name);

  i_elapsed_time1 := (dbms_utility.get_time() - timestart)/100;

  select buffer_gets into i_LIO1 from v$sql where module =  module_string;
  i_fetches1 := total_fetches;
  select sql_id into sql_id1 from   v$sql where module =  module_string;


---------------------------------------------------------------------------------------------------------------
    -- now parse and run the hinted statement :
  
     select    mod(abs(dbms_random.random),100000)+1 into module_string from dual ;
    module_string :=  'PJS2_' || module_string;
    total_fetches := 0;
    timestart  := dbms_utility.get_time();


   BEGIN
    if ( DBMS_SQL.IS_OPEN(cursor_name) )
    THEN
       DBMS_SQL.CLOSE_CURSOR(cursor_name);
    end if;
    cursor_name := DBMS_SQL.OPEN_CURSOR;
    dbms_application_info.set_module(module_string,'testing');
    DBMS_SQL.PARSE(cursor_name,  '/* ' || module_string || ' */ ' ||  sts_cursor.sql_text_newhint  , DBMS_SQL.NATIVE);
     ret := DBMS_SQL.EXECUTE(cursor_name);
    dbms_application_info.set_module( NULL, NULL);
    EXCEPTION
      WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Issues compiling SQL_ID '  || sts_cursor.sql_id || ' - ' || SQLERRM);
      dbms_application_info.set_module( NULL, NULL);

     CONTINUE;
   end ;

  -- fetch all the rows 
  
   LOOP                                        
    ret := DBMS_SQL.FETCH_ROWS(cursor_name);
    EXIT WHEN ret = 0;
    total_fetches := total_fetches + 1;
  END LOOP;

  DBMS_SQL.CLOSE_CURSOR(cursor_name);

  i_elapsed_time2 := (dbms_utility.get_time() - timestart)/100;
  select buffer_gets into i_LIO2 from v$sql where module =  module_string;
   i_fetches2 := total_fetches;
  select sql_id into sql_id2 from   v$sql where module =  module_string;



    DBMS_OUTPUT.PUT_LINE(  sts_cursor.sql_id  || ' ' || sql_id1 || ' ' || i_fetches1 || ' ' || i_elapsed_time1 || ' ' || i_LIO1 || ' --- ' || sql_id2 || ' ' || i_fetches2 || ' ' || i_elapsed_time2 || ' ' || i_LIO2 );

 

  end loop;

end;
/

alter session set current_schema=perf_support;



-- CODE to get the sql_exec_id from SQL monitor :

/*
  BEGIN
    select distinct SS.sql_id, SS.child_number ,SM.sql_exec_id  INTO  vSQL_ID, iSQL_CHILD, iSQL_EXEC_ID
    FROM v$sql SS
    left outer join v$sql_monitor SM ON SS.child_address = SM.sql_child_address
    WHERE SS.module = module_string;
  EXCEPTION
    when NO_DATA_FOUND 
    THEN
       dbms_output.put_line('Couldnt find the SQL_ID ' || sts_cursor.sql_id );
    when TOO_MANY_ROWS 
    then
       dbms_output.put_line('Module ' || module_string || ' has duplicate SQL!');
       CONTINUE;
  end;
*/




PL/SQL procedure successfully completed.


ORIG_SQL_ID  --- SQL_ID1  FETCHES1  ETIME1 LIO1 --- SQL_ID2 FETCHES2 ETIME2 LIO2
5urjfjczc1yrg dxzt5d0yrd1nm 1374139 1080 44600184 --- 6t1qaaxg8yyz8 1374139 561 39844327
c3prz2ny1ctvn 0ynb9p8y3j7u7 1374139 1089 44600146 --- 9z1prt8p2g0m8 1374139 548 39718050
5wth4zm4pwuyu 9rv2urfdjsq86 3447546 813 65542759 --- 2s1ypj03u5x9n 3447546 534 55739045
6kzkm6r0z0s8a dcwxyr3hwmshx 3447546 705 21101306 --- br37wt3w524g4 3447546 477 18131111
b962xn1uc5f3m 48gfj86akr614 7380764 1739 330870451 --- 12xdtsbb4bs70 7380764 1402 305718512
anbaf6p0uzvws 2yum4j83q0kyu 107678 3790 730520604 --- 3kn6xtmhd3bg5 107678 3180 698501418
79r4wtqvs2d8v 5pz10pmbmbx0n 2398501 1991 28339802 --- akdh0fy21bkjp 2398501 1068 5350076
1rt88rcy2ntsv chthztsugafau 107678 3626 731215214 --- aw3unfarxg0zb 107678 3169 694832794
0byrfzgktpx3c 2rwnupnd982rb 7380764 1548 331310886 --- fabsmx4bfuz6t 7380764 1634 305104446
2x9jsnvyxhpkg cdqr0m93trt15 194606 4684 1431824890 --- dgyj2f3apfcty 194606 1020 182878299
25q8pw4bdpnhd dhf104snbu962 2398501 1738 26955778 --- a9f6chmsr3p6g 2398501 951 4198059
5k0axx9crwa0r cd2gt41u5224t 708628 4733 1440042575 --- 6ts6bj0wu4n9z 708628 2051 229920947
5xfmjusf5hd96 89kza7pduyaht 13551 3452 603801883 --- 822xhdh3540dj 13551 2561 535693261
df5wg8k0adbvf 6br75w5ut9q55 708628 4567 1444079408 --- c9btwt6kcaczp 708628 2204 228829217
gsfp2banbtsm2 2sjcch6t8fuz0 301589 6470 1571789926 --- dzj30ahsgb3fj 301589 3775 1399198579
1zy9ucrb9ypsq 4b7fx3zrp50kw 301589 4832 1513356113 --- fsswy7s3c75hc 301589 4164 1312032894
dd5tpajpj46v1 d17an9fduz3aw 1083616 3447 690749627 --- 8j65jap624cr0 1083616 2895 663562228
78wrpq017a4u6 c3ngtm3yz7d6w 1083616 3273 690713951 --- d3suhqsg93a75 1083616 2753 659324030
59vxbtmxp36w7 6x0fng6muzxaa 13551 3602 601823859 --- c5uvnudxz4trm 13551 2547 535709475
cqpwyc4c07dqz 3zjr53ht3z4h1 194606 4496 1421818717 --- 0d8mam1fqv9mp 194606 1011 182844957



ORIG_SQL_ID  SQL_ID1  FETCHES1  ETIME1 LIO1 --- SQL_ID2 FETCHES2 ETIME2 LIO2
cqpwyc4c07dqz 1apmdpc4dnj5r 194606 4373 1411370119 --- 1fynfc4vurbur 194606 1056 182797928


