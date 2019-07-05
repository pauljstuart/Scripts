

--------------------------------------------------------
-- how to get the SQL_HANDLE given only the sql_id - part 1
-------------------------------------------------------

SET HEADING ON
SELECT distinct DSPBL.sql_handle, DSPBL.plan_name, SQL.sql_id,      created, 
     enabled, 
     accepted
FROM dba_sql_plan_baselines DSPBL, gv$sql SQL
WHERE DSPBL.signature = SQL.exact_matching_signature
and SQL.sql_id='5rpuur56jpmca';



---------------------------------------------------
-- How to get the SQL_handle given only the SQl_id  - part 2
---------------------------------------------------

DECLARE
    l_sql   VARCHAR2 (32000);
    TargetSQL   VARCHAR2(32000);
    ClippedTargetSQL VARCHAR2(2000);
    TargetSQL_ID VARCHAR2(32);
BEGIN
    TargetSQL_ID := '9p52amsvd1p99' ;
    dbms_output.put_line('SQL_ID : ' || TargetSQL_ID );
    select sql_text INTO TargetSQL from dba_hist_sqltext where sql_id = TargetSQL_ID;
    
    ClippedTargetSQL := substr( TargetSQL, 1, 1000);
    
    FOR clrec_data IN (SELECT * FROM dba_sql_plan_baselines  where created > SYSDATE - 30)
    LOOP
        l_sql := substr( clrec_data.sql_text, 1, 1000);
        IF ( l_sql = ClippedTargetSQL )
        THEN
            DBMS_OUTPUT.put_line ('sql handle : ' || clrec_data.sql_handle);
            EXIT;
        END IF;
    END LOOP;
END;

-------------------------------------------------
-- The switch : loading a new SQL_ID and plan against an existing SQL_HANDLE
--------------------------------------------------

 declare
   num_loaded   number;
begin
  num_loaded := dbms_spm.load_plans_from_cursor_cache(  sql_id=>'&new_sql_id',  
                                  plan_hash_value=> &new_plan_hash_value, 
                                  sql_handle=>'&existing_sql_handle', 
                                  enabled=>'YES');
  dbms_output.put_line('loaded : ' || num_loaded);
end;


-------------------------------------------------
-- or to get the plan from a baseline
--------------------------------------------------
column plan_table_output format A100
select * from table (dbms_xplan.display_sql_plan_baseline('SQL_55a95ad05fd7c1fc', 'SQL_PLAN_5baauu1gxghgwfc922566', 'typical'));


-- and leaving the SQL handle out :
column plan_table_output format A100
select * from table (dbms_xplan.display_sql_plan_baseline(NULL, 'SQL_PLAN_5baauu1gxghgwfc922566', 'typical'));

--------------------------------
--  including the HINTS
---------------------------------

column plan_table_output format A100
select * from table (dbms_xplan.display_sql_plan_baseline(NULL, 'SQL_PLAN_5baauu1gxghgwfc922566', 'typical OUTLINE'));




----------------------------------------
-- dropping a baseline
-------------------------------------

declare
   num_loaded   number;
begin
  num_loaded := dbms_spm.drop_sql_plan_baseline(plan_name => 'SQL_PLAN_5baauu1gxghgwfc922566');
  dbms_output.put_line('deleted : ' || num_loaded);
end;



----------------------------
-- loading/creating from cursor cache
----------------------------

declare
  ret number;
begin
  ret := dbms_spm.load_plans_from_cursor_cache(sql_id=>'4rxs2ux3zzanp', plan_hash_value => 3537504715, enabled=>'YES', fixed=>'NO');
  dbms_output.put_line('loaded ' || ret );
end;



--------------------------------------------------------
-- Retrieving an old plan from the AWR into a baseline
--------------------------------------------------------

-- first, create the STS and load the plan in to it :

set serveroutput on
DECLARE
     baseline_ref_cursor  DBMS_SQLTUNE.sqlset_cursor;
    s_sts_name VARCHAR2(128) := 'PERF_STS';
    return_value NUMBER;
BEGIN
  OPEN baseline_ref_cursor FOR
    SELECT VALUE(p) 
     FROM TABLE(DBMS_SQLTUNE.select_workload_repository( begin_snap =>    43989, end_snap => 44031,
                                      basic_filter => q'#sql_id='0cz26t6k2cx5t' and plan_hash_value=4106127154 #',
                                      attribute_list => 'ALL')) p;

  for i in (select 1 from all_sqlset where name = s_sts_name)
  loop
       DBMS_SQLTUNE.drop_sqlset (s_sts_name);
  end loop;

  DBMS_SQLTUNE.create_sqlset (s_sts_name);
  DBMS_SQLTUNE.LOAD_SQLSET(s_sts_name, baseline_ref_cursor);

  select count(distinct sql_id ) into return_value  from dba_sqlset_plans where sqlset_name = s_sts_name ;

  dbms_output.put_line('Loaded ' || return_value || ' SQL IDs into ' || s_sts_name);

END;

-- looking at the plan :

select * from table ( DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE (
      sql_handle => 'SQL_ad7a99fa75f51b40', 
      plan_name => 'SQL_PLAN_auyntz9uza6u05cfcf994'));


-- Now load a baseline, from a STS

DECLARE
  l_spm_return NUMBER;
BEGIN
  l_spm_return := dbms_spm.load_plans_from_sqlset( sqlset_name   => 'CAESAR_STS');
  COMMIT;
  dbms_output.put_line('return is ' || l_spm_return);
END;


-- extracting outline hints :

select
extractvalue(value(d), '/hint') as outline_hints
from
xmltable('/outline_data/hint'
passing (
select
xmltype(comp_data) as xmlval
from
sqlobj$data sod, sqlobj$ so
where so.signature = sod.signature
and so.plan_id = sod.plan_id
and comp_data is not null
and name like '&baseline_plan_name'
)
) d;



/*
 * This PL/SQL block will create a SQL plan baseline from a SQL_ID which is inside the AWR.
 * 
 * Input parameters - you must specify the SQL_ID and the desired sql plan hash value too.
 *
 */
set serveroutput on
DECLARE
  -- specify your target SQL_ID and plan hash value here :
  s_target_sqlid VARCHAR2(13) := '5vw8dft6cr3w9';
  s_target_plan_hash VARCHAR2(128) := '3608985393';

     baseline_ref_cursor  DBMS_SQLTUNE.sqlset_cursor;
    s_sts_name VARCHAR2(256);
    i_starting_snapid NUMBER;
  i_end_snapid NUMBER;
  i_days_ago NUMBER := 40;
  return_value NUMBER;
  l_spm_return NUMBER;
  l_sql   VARCHAR2 (32000);
  TargetSQL   VARCHAR2(32000);
   ClippedTargetSQL VARCHAR2(2000);
   
BEGIN
    DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
  -- get the beginning and ending snap ids :
  SELECT min(snap_id) into i_starting_snapid  FROM dba_hist_snapshot WHERE trunc(begin_interval_time, 'DD')  >  trunc(SYSDATE - i_days_ago, 'DD') and dbid = (select dbid from v$database) ;
  SELECT max(snap_id) into i_end_snapid  FROM dba_hist_snapshot where dbid = (select dbid from v$database);

  dbms_output.put_line('The starting snapid is ' || i_starting_snapid );

  select  mod(abs(dbms_random.random),100000)+1 into s_sts_name from dual ;
  s_sts_name :=  'PERF_SUPPORT_STS_' || lpad(s_sts_name, 6, '0');
  dbms_output.put_line('The SQL Tuning Set is : ' || s_sts_name);

  -- Create a SQL tuning set, and load the desired SQL in to it :
  DBMS_SQLTUNE.create_sqlset ( s_sts_name);
  dbms_output.put_line('Loading in ' || s_target_sqlid || ' plan ' || s_target_plan_hash );
  OPEN baseline_ref_cursor FOR
  SELECT VALUE(p) 
  FROM TABLE(DBMS_SQLTUNE.select_workload_repository(   begin_snap => i_starting_snapid, end_snap => i_end_snapid,
                                                         basic_filter => q'#sql_id='#' || s_target_sqlid || q'#' and plan_hash_value=#' || s_target_plan_hash 
                                                         , attribute_list => 'ALL')) p;

  DBMS_SQLTUNE.LOAD_SQLSET( s_sts_name, baseline_ref_cursor);


 select count(distinct sql_id ) into return_value  from dba_sqlset_plans where sqlset_name = s_sts_name ;

 dbms_output.put_line('Loaded ' || return_value || ' SQL IDs into ' || s_sts_name);

  dbms_output.put_line('Creating the sql plan baseline from ' || s_sts_name);
   
  l_spm_return := dbms_spm.load_plans_from_sqlset( sqlset_name   => s_sts_name);
  COMMIT;
  dbms_output.put_line('The return value from creating the baseline is : ' || l_spm_return);

  -- Now get the SQL handle for our target SQL ID :

    select sql_text INTO TargetSQL from dba_hist_sqltext where sql_id = s_target_sqlid  and dbid = (select dbid from v$database);
    
    ClippedTargetSQL := substr( TargetSQL, 1, 1000);
    
    FOR clrec_data IN (SELECT * FROM dba_sql_plan_baselines  where created > SYSDATE - i_days_ago)
    LOOP
        l_sql := substr( clrec_data.sql_text, 1, 1000);
        IF ( l_sql = ClippedTargetSQL )
        THEN
            DBMS_OUTPUT.put_line ('sql handle : ' || clrec_data.sql_handle);
            EXIT;
        END IF;
    END LOOP;

END;


-- to check if the baseline is there :

select * from dba_sql_plan_baselines
where sql_handle = 'SQL_e9037343e9c677f9'





----------------------------------------------------------------------
--
-- now pack only the SQL baselines from a particular STS or driving table
--
-----------------------------------------------------------------------


create table desired_sql (sql_plan VARCHAR2(256) ); 

insert into desired_sql values ('SQL_PLAN_0m294ncu6zkj1e405d46a'); 
insert into desired_sql values ('SQL_PLAN_4s3cdms1aucxqf59c5404'); 
insert into desired_sql values ('SQL_PLAN_g8j1gcbxdx7sh5eb500d8'); 


exec DBMS_SPM.CREATE_STGTAB_BASELINE('DEV92A_GOOD_BASELINES');

DECLARE

  CURSOR desired_sql_cur IS 
    SELECT sql_plan
    FROM desired_sql;  

    /*   
    CURSOR desired_sql_cur IS 
    SELECT force_matching_signature
    FROM dba_sqlset_statements  
    WHERE sqlset_name = 'MSCR-4770';
   */
  total_packed      number;
  this_result       number;
  this_sql          VARCHAR2(256);
  this_sql_handle   VARCHAR2(256);
  
BEGIN
  total_packed := 0;
  
  OPEN desired_sql_cur;
  LOOP
      FETCH desired_sql_cur INTO this_sql;
      EXIT WHEN desired_sql_cur%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE( 'Looking at plan : ' || this_sql  );
      
      /*
      select sql_handle INTO this_sql_handle from  dba_sql_plan_baselines where plan_name = ''||this_sql||''   ;
      DBMS_OUTPUT.PUT_LINE( 'Packing sql_handle : ' || this_sql_handle  );
      */
      
      this_result := 0;
      this_result := DBMS_SPM.PACK_STGTAB_BASELINE( table_name  =>'MSCR4770_BASELINES', plan_name =>  ''||this_sql||''   ) ;
     total_packed := total_packed + this_result;
  END LOOP;
     
   DBMS_OUTPUT.PUT_LINE( 'There were '  || total_packed || ' baselines packed.'  );
END;


-----------------------------------
-- packing and unpacking for export
-----------------------------------


exec DBMS_SPM.CREATE_STGTAB_BASELINE('UAT_4RXS');



declare
   num_loaded   number;
begin
  num_loaded := dbms_spm.pack_stgtab_baseline( table_name => 'MSCR4563', plan_name => 'SQL_PLAN_5baauu1gxghgwfc922566', sql_handle => 'SQL_55a95ad05fd7c1fc');
  dbms_output.put_line('packed : ' || num_loaded);
end;



declare
   num_loaded   number;
begin
  num_loaded := dbms_spm.unpack_stgtab_baseline( table_name => 'MSCR4563', owner => 'PSTUART', plan_name => 'SQL_PLAN_5baauu1gxghgwfc922566', sql_handle => 'SQL_55a95ad05fd7c1fc');
  dbms_output.put_line('loaded : ' || num_loaded);
end;

--
-- unpacking all baselines :
-- 

declare
   num_loaded   number;
begin
  num_loaded := dbms_spm.unpack_stgtab_baseline( table_name => 'MSCR4770_BASELINES' );
  dbms_output.put_line('baselines loaded : ' || num_loaded);
end;


importing :

impdp dba_utils_owner  DUMPFILE=expdat.dmp tables=PSTUART.MSCR4770_BASELINES REMAP_SCHEMA=PSTUART:DBA_UTILS_OWNER

--------------------------------------------------------
-- modifying an attribute
--------------------------------------------------------

declare
   num_loaded   number;
begin
  num_loaded := dbms_spm.alter_sql_plan_baseline(  plan_name => 'SQL_PLAN_3bpnpstkcdfmp2888e6d5', attribute_name => 'enabled', attribute_value => 'NO');
  dbms_output.put_line('modified : ' || num_loaded);
end;


--------------------------------------------------------
-- evolving a plan :
--------------------------------------------------------

declare
   num_loaded   CLOB;
begin
 num_loaded := dbms_spm.evolve_sql_plan_baseline( sql_handle => 'SQL_9be4dbd1d217ea9e', plan_name => 'SQL_PLAN_9rt6vu791guny491de24d', verify => 'NO');
  dbms_output.put_line('evolved : ' || num_loaded);
end;






-----------------------------------------------
-- Load ALL the plans from a STS into the  SQL base
-----------------------------------------------


DECLARE
  results    PLS_INTEGER;
BEGIN

results := DBMS_SPM.LOAD_PLANS_FROM_SQLSET ( sqlset_name  => 'dev92a_good_baselines');
DBMS_OUTPUT.PUT_LINE('There were ' || results || ' loaded.' );

END;



-- loading a single plan into the base, from a STS

declare 
  result  number;
begin
result := DBMS_SPM.LOAD_PLANS_FROM_SQLSET( sqlset_name  => 'dev92apatch_4', basic_filter => ' module = ''gdfp_5''  ');
end;



*************************************************************
*
* Change the attributes of the SQL plans in the base
*
************************************************************


DECLARE

  
  CURSOR desired_sql_ids_cur IS 
    SELECT sql_id
    FROM dba_sqlset_statements  
   WHERE sqlset_name = 'dev92a_good_baselines';

  CURSOR desired_sql_handles IS
    SELECT sql_handle
    FROM   dba_sql_plan_baselines
    WHERE sql_id
  results      number;
  this_sql     VARCHAR2(256);

BEGIN
  results := 0;
  
  OPEN desired_sql_ids_cur;
  LOOP
      FETCH desired_sql_ids_cur INTO this_sql;
      EXIT WHEN desired_sql_ids_cur%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE( 'Changing  : ' || this_sql  );
      
      DBMS_SPM.ALTER_SQL_PLAN_BASELINE( sql_handle  =>  this_handle,attribute_name => 'MODULE', attribute_value => 'good_plan_for_export');

      results := results +1;
  END LOOP;
   DBMS_OUTPUT.PUT_LINE( 'There were '  || results || ' modified.'  );
END;

