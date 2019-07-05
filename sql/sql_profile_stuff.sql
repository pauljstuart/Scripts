
-- dropping a profile

begin
dbms_sqltune.drop_sql_profile (
name => 'SQL_profile_PJS80',
ignore => true);
end;


-- disabling a profile

EXEC DBMS_SQLTUNE.ALTER_SQL_PROFILE('sql_profile_name','STATUS','DISABLED');


-- changing the category

begin
     DBMS_SQLTUNE.ALTER_SQL_PROFILE ( name => 'PROF_80umtq61vctf4_763151165', 
     attribute_name => 'CATEGORY', 
     value => 'CAT_80umtq61vctf4_bindset1');
end;




-- creating a profile with just one hint in it :

DECLARE

sql_text_string  CLOB;
hints            SYS.SQLPROF_ATTR;
sql_id_cur      SYS_REFCURSOR;

BEGIN

------------------------  Get the SQL Text ----------------------------

-- either from the AWR :

--OPEN sql_id_cur  FOR q'#select sql_text from dba_hist_sqltext where sql_id = '&SQL_ID' #';
--FETCH sql_id_cur INTO sql_text_string;

-- or enter text directly :

sql_text_string  := q'#select count(*) from dba_users#';

----------------------- setup the SQL profile -------------------------

hints := SYS.SQLPROF_ATTR(
    q'#BEGIN_OUTLINE_DATA#',
    q'#GATHER_PLAN_STATISTICS#',
    q'#MONITOR#',
    q'#END_OUTLINE_DATA#');


DBMS_SQLTUNE.IMPORT_SQL_PROFILE (
  sql_text    => sql_text_string,
  profile     => hints,
  name        => 'SQL_test_profile' ,
  description => 'SQL profile for testing',
  category    => 'DEFAULT',
  validate    => TRUE,
  replace     => TRUE,
  force_match => FALSE );


/* TRUE:FORCE (match even when different literals in SQL). FALSE:EXACT (similar to CURSOR_SHARING) */ 

END;
/


---------------------------------------------------------------------------------------------------------------------------------------------------

-- slightly more complext with drop statement :


DECLARE

sql_text_string  CLOB;
hints            SYS.SQLPROF_ATTR;
sql_id_cur      SYS_REFCURSOR;
s_profile_name   VARCHAR2(64) := 'SQL_profile_8sjg9xunbjmv0';

BEGIN


  for i in (select 1 from dba_sql_profiles where name = s_profile_name  )
  loop
      dbms_sqltune.drop_sql_profile ( name => s_profile_name, ignore => true);
  end loop;

------------------------  Get the SQL Text ----------------------------


OPEN sql_id_cur  FOR q'#select sql_text from dba_hist_sqltext where sql_id = '8sjg9xunbjmv0' #';
FETCH sql_id_cur INTO sql_text_string;


----------------------- setup the SQL profile -------------------------

hints := SYS.SQLPROF_ATTR(
   q'#BEGIN_OUTLINE_DATA#',
   q'#IGNORE_OPTIM_EMBEDDED_HINTS#',
   q'#OPTIMIZER_FEATURES_ENABLE('11.2.0.4')#',
   q'#DB_VERSION('11.2.0.4')#',
   q'#ALL_ROWS#',
   q'#OUTLINE_LEAF(@"SEL$1")#',
   q'#OUTLINE_LEAF(@"SEL$2")#',
   q'#OUTLINE_LEAF(@"SET$1")#',
   q'#OUTLINE_LEAF(@"SEL$07BDC5B4")#',
   q'#MERGE(@"SEL$4")#',
   q'#OUTLINE(@"SEL$3")#',
   q'#OUTLINE(@"SEL$4")#',
   q'#NO_ACCESS(@"SEL$07BDC5B4" "AC"@"SEL$4")#',
   q'#FULL(@"SEL$07BDC5B4" "J"@"SEL$4")#',
   q'#LEADING(@"SEL$07BDC5B4" "AC"@"SEL$4" "J"@"SEL$4")#',
   q'#USE_HASH(@"SEL$07BDC5B4" "J"@"SEL$4")#',
   q'#FULL(@"SEL$2" "LGS"@"SEL$2")#',
   q'#INDEX(@"SEL$2" "LGD"@"SEL$2" ("LAP_GROUP_DETAILS"."GROUP_ID"))#',
   q'#LEADING(@"SEL$2" "LGS"@"SEL$2" "LGD"@"SEL$2")#',
   q'#USE_NL(@"SEL$2" "LGD"@"SEL$2")#',
   q'#NLJ_BATCHING(@"SEL$2" "LGD"@"SEL$2")#',
   q'#FULL(@"SEL$1" "LAE"@"SEL$1")#',
   q'#FULL(@"SEL$1" "FLAP"@"SEL$1")#',
   q'#FULL(@"SEL$1" "PGM"@"SEL$1")#',
   q'#LEADING(@"SEL$1" "LAE"@"SEL$1" "FLAP"@"SEL$1" "PGM"@"SEL$1")#',
   q'#USE_MERGE_CARTESIAN(@"SEL$1" "FLAP"@"SEL$1")#',
   q'#USE_HASH(@"SEL$1" "PGM"@"SEL$1")#',
    q'#END_OUTLINE_DATA#');


DBMS_SQLTUNE.IMPORT_SQL_PROFILE (
  sql_text    => sql_text_string,
  profile     => hints,
  name        => s_profile_name ,
  description => 'SQL profile for 8sjg9xunbjmv0 plan 2668370549 ',
  category    => 'DEFAULT',
  validate    => TRUE,
  replace     => TRUE,
  force_match => TRUE );


/* TRUE:FORCE (match even when different literals in SQL). FALSE:EXACT (similar to CURSOR_SHARING) */ 

END;
/



----------------------------------------------------------------------------------------
--
-- File name:   sql_profile_hints.sql
--
-- Purpose:     Show hints associated with a SQL Profile.
-
-- Author:      Kerry Osborne
--
-- Usage:       This scripts prompts for one value.
--
--              profile_name: the name of the profile to be used
--
-- Description: This script pulls the hints associated with a SQL Profile.
--
-- Mods:        Modified to check for 10g or 11g as the hint structure changed.
--              Modified to join on category as well as signature.
--
--              See kerryosborne.oracle-guy.com for additional information.
---------------------------------------------------------------------------------------
--
set sqlblanklines on
set feedback off
accept profile_name -
       prompt 'Enter value for profile_name: ' -
       default 'X0X0X0X0'

declare
ar_profile_hints sys.sqlprof_attr;
cl_sql_text clob;
version varchar2(3);
l_category varchar2(30);
l_force_matching varchar2(3);
b_force_matching boolean;
begin
 select regexp_replace(version,'\..*') into version from v$instance;

if version = '10' then

-- dbms_output.put_line('version: '||version);
   execute immediate -- to avoid 942 error 
   'select attr_val as outline_hints '||
   'from dba_sql_profiles p, sqlprof$attr h '||
   'where p.signature = h.signature '||
   'and p.category = h.category  '||
   'and name like (''&&profile_name'') '||
   'order by attr#'
   bulk collect 
   into ar_profile_hints;

elsif version = '11' then

-- dbms_output.put_line('version: '||version);
   execute immediate -- to avoid 942 error 
   'select hint as outline_hints '||
   'from (select p.name, p.signature, p.category, row_number() '||
   '      over (partition by sd.signature, sd.category order by sd.signature) row_num, '||
   '      extractValue(value(t), ''/hint'') hint '||
   'from sqlobj$data sd, dba_sql_profiles p, '||
   '     table(xmlsequence(extract(xmltype(sd.comp_data), '||
   '                               ''/outline_data/hint''))) t '||
   'where sd.obj_type = 1 '||
   'and p.signature = sd.signature '||
   'and p.category = sd.category '||
   'and p.name like (''&&profile_name'')) '||
   'order by row_num'
   bulk collect 
   into ar_profile_hints;

end if;

  dbms_output.put_line(' ');
  dbms_output.put_line('HINT');
  dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------------------');
  for i in 1..ar_profile_hints.count loop
    dbms_output.put_line(ar_profile_hints(i));
  end loop;
  dbms_output.put_line(' ');
  dbms_output.put_line(ar_profile_hints.count||' rows selected.');
  dbms_output.put_line(' ');

end;
/
undef profile_name
set feedback on
