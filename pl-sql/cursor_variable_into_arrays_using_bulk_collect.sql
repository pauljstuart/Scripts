
-- selecting straight into a collection using bulkcollect

-- example 1 :  using type based on an actual database table :

declare
  type nt is table of all_tab_partitions%rowtype;
  loc_nt  nt;
  
  --alternatively by creating a record, and a fixed VARRAY :
   /*
   TYPE rec_nt IS RECORD (
        term    VARCHAR2(20), 
        meaning VARCHAR2(200)); 
   TYPE nt IS VARRAY(250) OF rec_nt;
  */  

  v_partition_name VARCHAR2(128);
  v_table_name VARCHAR2(128) := 'POSTING';
  v_table_owner VARCHAR2(128) := 'MVDS';

begin

  select * bulk collect into loc_nt from all_tab_partitions where table_name = v_table_name and table_owner = v_table_owner;

end;
/


-- example 2 :  using type based on a cursor variable, into a VARRAY :

declare

  cursor C1 is select partition_name, high_value from all_tab_partitions where table_name = 'POSTING' and table_owner = 'MVDS';
  TYPE nt2 is table of C1%rowtype;
   loc_nt2 nt2;

  v_partition_name VARCHAR2(128);
  v_table_name VARCHAR2(128) := 'POSTING';
  v_table_owner VARCHAR2(128) := 'MVDS';

begin

  open C1;
  fetch C1 bulk collect into loc_nt2;
  close C1;

end;
/


-- another example, this time putting a parameter on the CURSOR variable

set serveroutput on
declare

  cursor HK_cursor(p_table_name VARCHAR2)  is 
               SELECT  ID,   TABLE_NAME,  WORKFLOW_ID ,   PARTITION_VALUE  ,   STATUS     
               FROM HOUSEKEEPING_TO_DROP_CONTROL where table_name = p_table_name;
  TYPE HK_cursor_type is table of HK_cursor%rowtype;
   work_table HK_cursor_type;

begin


  OPEN HK_cursor('POSTING') ;
  fetch HK_cursor bulk collect into work_table;
  close HK_cursor;


    FOR i IN 1 .. work_table.count
     LOOP 
        dbms_output.put_line( work_table(i).table_name);
    END LOOP;


end;
/




-- another example, this time into a VARRAY

DECLARE

    CURSOR   sesstat_cur IS
    select SS.inst_id, SS.sid, SN.name, SS.value FROM gv$sesstat SS, v$statname SN 
    WHERE  SS.statistic# = SN.statistic#   and SN.name =  'data blocks consistent reads - undo records applied';
    TYPE result_t IS TABLE OF sesstat_cur%ROWTYPE INDEX BY PLS_INTEGER;


    x_varray result_t ;

   i   integer;
 
BEGIN

OPEN sesstat_cur;


 fetch sesstat_cur
bulk collect into x_varray ;
close sesstat_cur;

dbms_output.put_line('fetched : ' || x_varray.count);


    FOR i IN 1 .. x_varray.count
     LOOP 
        dbms_output.put_line(x_varray(i).inst_id || ' / '  || x_varray(i).sid || ' :: '  || x_varray(i).value);
    END LOOP;




LOOP 
        dbms_output.put_line(x_varray(i).inst_id || ' / '  || x_varray(i).sid || ' :: '  || x_varray(i).value);
END LOOP;



END;
