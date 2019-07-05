set echo off
set verify off
set feedback off
set serveroutput on
prompt =================================================================================================================================================================

--CLEAR screen

----------------------- settings and config section --------------------------------------------------------------------------------------

-- Instructions :
--
-- 1. use the sqlplus variables below to control how you want the script to search for SQL text
-- 2.  place the snippet of sql text in the TargetSQL CLOB below.  The text can contain any characters, including quotes and newlines
-- 3.  Execute the script.
-- 
-- I wrote this to work with SQL Developer, but it should work with SQLplus too.
--
-- Paul Stuart

/* 
   CRE TAB      1
   INSERT       2
   SELECT =     3
   UPDATE       6
   DELETE       7
   CRE INDEX    9
   drop table   12
   alter table  15
   PL/SQL EXEC 47
   ANALYZE TAB 62
   ANALYZE IX  63
   TRUNCATE TABLE 85
   upsert         189
   call method   170
*/
define COMMAND_TYPE=3
--define DAYS_AGO=14
define SEARCH_AWR=0
define SEARCH_CURSORCACHE=1


--------------------------- code begins here ------------------------------------------------------------------------------------------------



set heading off
prompt
prompt DAYS_AGO : &DAYS_AGO
prompt SEARCH_CURSORCACHE : &SEARCH_CURSORCACHE
prompt SEARCH_AWR :  &SEARCH_AWR
prompt SQL COMMAND CODE : &COMMAND_TYPE
select 'SQL COMMAND : ' || command_name  from v$sqlcommand where command_type like  '&COMMAND_TYPE';
prompt
set heading on



-- this section does some quick counting to see what is to be searched :

DECLARE
   iCount INTEGER;

BEGIN

  IF ( &SEARCH_AWR = 1 )
  THEN
    SELECT COUNT(sql_id) into iCount 
              FROM dba_hist_sqltext WHERE command_type like '&COMMAND_TYPE'
              AND  dbid = (select dbid from v$database)
              AND sql_id IN (SELECT DISTINCT sql_id FROM  dba_hist_sqlstat
              WHERE snap_id > (  SELECT min(snap_id) FROM dba_hist_snapshot WHERE begin_interval_time  >  trunc(SYSDATE,'DD') - &DAYS_AGO ));

    dbms_output.put_line('There are ' || iCount || ' sql to be searched in the AWR.' );
  end if;

  IF ( &SEARCH_CURSORCACHE = 1)
  THEN
    SELECT count(sql_id) into iCount FROM gv$sqlarea WHERE command_type  like '&COMMAND_TYPE';
    dbms_output.put_line('There are ' || iCount || ' sql to be searched in the cursor cache.' );
  END IF;

END;
/




-- now do the actual searching 

prompt Beginning search now :
set timing on

DECLARE

-- insert SQL text here ::

  TargetSQL CLOB  := q'# 



SELECT /* ordered use_hash (G P ) full (g) full (p) */ MAX(P.ID), MAX(G.GCR_CORE_ID), MAX(G.GCR_INST_ID), GCR_AMORTIZATION_END_DT, GCR_AMORTIZATION_FREQ_CODE, GCR_B2B_TRANSACTION_FLAG, GCR_B3_APP_RATING_AG_CODE, GCR_B3_APP_RATING_CODE, GCR_B



#';

-- nds_oracle_stats_pkg.import_stats
--------------------

  TestSQL CLOB;
  iTest   INTEGER;
  ResultList   VARCHAR2(32500) := '(' ;
  ResultCount INTEGER := 0;

 CURSOR sqltext_cur 
    IS 
    SELECT sql_id, UPPER(REPLACE(REPLACE(REPLACE(REPLACE(sql_text, CHR(10)), CHR(13)), CHR(9)), CHR(32)) ) as sql_text2  
              FROM dba_hist_sqltext 
              WHERE 
                command_type like '&COMMAND_TYPE'
              and  dbid = (select dbid from v$database)
              AND sql_id IN (SELECT DISTINCT sql_id FROM  dba_hist_sqlstat
              WHERE snap_id > (  SELECT min(snap_id) FROM dba_hist_snapshot WHERE begin_interval_time  >  trunc(SYSDATE,'DD') - &DAYS_AGO));

 CURSOR sqltext_cur2
    IS 
       SELECT sql_id, UPPER(REPLACE(REPLACE(REPLACE(REPLACE(sql_fulltext, CHR(10)), CHR(13)), CHR(9)), CHR(32)) ) as sql_text2  FROM gv$sqlarea 
       WHERE command_type like '&COMMAND_TYPE';

    TYPE employees_aat IS TABLE OF sqltext_cur%ROWTYPE
        INDEX BY PLS_INTEGER;

    l_sql_array employees_aat;

begin


   DBMS_OUTPUT.ENABLE ( NULL );
 TargetSQL :=  UPPER(REPLACE(REPLACE(REPLACE(REPLACE(TargetSQL, CHR(10)), CHR(13)), CHR(9)), CHR(32)) );

--TargetSQL := regexp_replace( TargetSQL, '[' || chr(10) || chr(13) || chr(32) ||  ']', '' );

DBMS_OUTPUT.put_line ( chr(10) || chr(10) || 'Looking for >>'  || substr( TargetSQL, 1, 2000) || chr(10) || chr(10));

IF ( &SEARCH_AWR = 1 )
  THEN
  dbms_output.put_line('Checking AWR &DAYS_AGO days back : ' || chr(10)) ;

  
  OPEN sqltext_cur;
    
  FETCH sqltext_cur 
            BULK COLLECT INTO l_sql_array;
         
     FOR indx IN 1 .. l_sql_array.COUNT 
        LOOP
            IF ( dbms_lob.instr( l_sql_array(indx).sql_text2, TargetSQL)   > 0 )
            THEN
                dbms_output.put_line( l_sql_array(indx).sql_id ||  '   :    '   ||  dbms_lob.substr(l_sql_array(indx).sql_text2, 200 ) );
                if ( ResultCount < 1000  and length( ResultList) < 32000 )
		 then
		                   ResultList := ResultList || ',''' ||  l_sql_array(indx).sql_id  || '''';
		                   ResultCount := ResultCount +1;
                end if;
            END if;
        END LOOP;      
         
  DBMS_OUTPUT.put_line ( chr(10) || 'Searched ' ||  l_sql_array.COUNT || ' from AWR' || chr(10)  );        
  CLOSE sqltext_cur;
end if ;


  IF ( &SEARCH_CURSORCACHE = 1 )
  THEN 
     dbms_output.put_line('Checking cursor cache : ' || chr(10)) ;

     OPEN sqltext_cur2;
     FETCH sqltext_cur2 
            BULK COLLECT INTO l_sql_array;

     FOR indx IN 1 .. l_sql_array.COUNT 
        LOOP
            
             IF ( dbms_lob.instr( l_sql_array(indx).sql_text2, TargetSQL)   > 0 )
            THEN
                dbms_output.put_line( l_sql_array(indx).sql_id ||  '   :    '   ||  dbms_lob.substr(l_sql_array(indx).sql_text2, 200 )  );
                if ( ResultCount < 1000  and length( ResultList) < 32000 )
                then
                   ResultList := ResultList || ',''' ||  l_sql_array(indx).sql_id  || '''';
                   ResultCount := ResultCount +1;
                end if;
            END if;
        END LOOP;           

    DBMS_OUTPUT.put_line ( chr(10) || 'Searched ' ||  l_sql_array.COUNT || ' from the cursor cache'  );
    CLOSE sqltext_cur2;
  END IF;

 
  dbms_output.put_line( chr(10) || ResultList || ')' );
  dbms_output.put_line( chr(10) ||  'Found ' || ResultCount || ' matches' );
END;
/

set timing off




/*
-- Purpose:     find sql in DBA_HIST_SQLSTAT
set long 32000
set verify off
set pagesize 999
set lines 132
col username format a13
col prog format a22
col sql_text format a90
col sid format 999
col child_number format 99999 heading CHILD
col ocategory format a10
col avg_etime format 9,999,999.99
col etime format 9,999,999.99

select sql_id, 
dbms_lob.substr(sql_text,3999,1) sql_text
from dba_hist_sqltext
where dbms_lob.substr(sql_text,3999,1) like nvl('&sql_text',dbms_lob.substr(sql_text,3999,1))
and sql_text not like '%from dba_hist_sqltext where sql_text like nvl(%';

*/


prompt =================================================================================================================================================================


