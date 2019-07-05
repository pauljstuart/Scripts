
-- using tables :

set serveroutput on
declare
  type myarray is table of varchar2(255) index by binary_integer;
  v_array myarray;
begin

v_array(v_array.count + 1) := 'APP_GCRS_MERIVAL_RECON';
v_array(v_array.count + 1) := 'APP_MER_AGGREGATES';
v_array(v_array.count + 1) := 'APP_MERIVAL_GCRS_VALIDATION';
v_array(v_array.count + 1) := 'APP_BO_ONSHORE';
v_array(v_array.count + 1) := 'APP_BO';
v_array(v_array.count + 1) := 'APP_FDD_MERIVAL_RECON';
v_array(v_array.count + 1) := 'RFA_AUDIT';
v_array(v_array.count + 1) := 'APP_AXIOM';
v_array(v_array.count + 1) :=  'APP_CDM';
v_array(v_array.count + 1) :=  'APP_ICS';
v_array(v_array.count + 1) :=  'APP_RFA_BO';
v_array(v_array.count + 1) :=  'CRESCENT_STATE' ;
v_array(v_array.count + 1) := 'CRESCENT_CALC_DETAIL';
v_array(v_array.count + 1) :=  'CRESCENT_CONFIG';
v_array(v_array.count + 1) :=  'CRESCENT_INPUT';
v_array(v_array.count + 1) :=  'CRESCENT_RPTG';


  for i in 1..v_array.count loop
    dbms_output.put_line(v_array(i));
  end loop; 
end;
/

-- using VARRAYs :


set serveroutput on
declare
  type indexRecords is VARRAY(49) of varchar2(255) ;
  v_targetIndexes indexRecords := indexRecords('BOOK_SYSTEM_REGION_MAP_IDX2',
                                          'BOOK_SYSTEM_REGION_MAP_IDX4',
                                          'BOOK_SYSTEM_REGION_MAP_IDX5',
                                          'BOOK_SYSTEM_REGION_MAP_IDX6',
                                          'BOOK_SYSTEM_REGION_MAP_IDX7',
                                          'BOOK_SYSTEM_REGION_MAP_IDX8',
                                          'BOOK_SYSTEM_REGION_MAP_IDX9');
begin


  for i in 1..v_targetIndexes.count loop
    dbms_output.put_line(v_targetIndexes(i));
  end loop; 
end;
/


-- associative arrays :


declare

  TYPE VarAssoc IS TABLE OF INTEGER  INDEX BY VARCHAR2(256);
  StatArray      VarAssoc;
  l_index        VARCHAR2(256);
  --after  INTEGER;
begin

  FOR r IN (select SN.name, SS.value FROM v$mystat SS, v$statname SN WHERE SS.statistic# = SN.statistic#) 
  LOOP
     --dbms_output.put_line('loading ' || r.name );
    StatArray(r.name) := r.value;
  END LOOP;


execute immediate 'select count(*) from dba_users';


  FOR r IN (select SN.name, SS.value FROM v$mystat SS, v$statname SN WHERE SS.statistic# = SN.statistic#) 
  LOOP
    --after := StatArray(r.name) - r.value ;
    -- dbms_output.put_line('modifying ' || r.name || ' before ' || StatArray(r.name) || ' after ' || after );
    StatArray(r.name) :=  r.value - StatArray(r.name) ;
  END LOOP;

  -- now print out the array :
 l_index := StatArray.first;
 while (l_index is not null)
 loop
    if ( StatArray(l_index) != 0  )
    then
      dbms_output.put_line( RPAD( l_index ,50,' ' )  || ' ' || StatArray(l_index) );
    end if;
    l_index := StatArray.next(l_index);
 end loop;


end;

-- from Steve Feurstein


CREATE OR REPLACE PACKAGE BODY meme_tracker
IS
   SUBTYPE meme_target_t IS VARCHAR2(100);
   SUBTYPE meme_t IS VARCHAR2(1000);
   c_was_processed CONSTANT BOOLEAN := TRUE;

   TYPE memes_for_target_t IS TABLE OF BOOLEAN
      INDEX BY meme_t;
   TYPE processed_memes_t IS TABLE OF memes_for_target_t
      INDEX BY meme_target_t;
   g_processed_memes processed_memes_t;

   PROCEDURE reset_memes
   IS
   BEGIN
      g_processed_memes.DELETE;
   END;

   FUNCTION already_saw_meme (
         meme_target_in VARCHAR2, meme_in IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN g_processed_memes 
               (meme_target_in)
                   (meme_in) = c_was_processed;
   EXCEPTION 
      /* PL/SQL raises NDF if you try to "read" a collection
         element that does not exist */
      WHEN NO_DATA_FOUND THEN RETURN FALSE;
   END;

   PROCEDURE add_meme (
      meme_target_in VARCHAR2, meme_in IN VARCHAR2)
   IS
   BEGIN
      g_processed_memes (meme_target_in)(meme_in) 
         := c_was_processed;   
   END;
END;
/
