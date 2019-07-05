set serveroutput on

-- compressing subpartitions in a table :

declare
  sTableName VARCHAR2(256) := 'BALANCE';
  iInitialSize NUMBER;
  iElapsed_Time NUMBER;
  iFinalSize  NUMBER;
  timestart NUMBER;
begin

for table_cursor in (select subpartition_name from ALL_tab_subpartitions where TABLE_owner = 'FBI_FDR_BALANCE' AND table_name = sTableName )
  LOOP
  iInitialSize := 0;
  iFinalSize := 0;
 
  -- get the initial size
  select BLOCKS into iInitialSize from dba_segments where owner = 'FBI_FDR_BALANCE' and segment_name = sTableName and segment_type = 'TABLE SUBPARTITION' and partition_name = table_cursor.subpartition_name;
  
  -- now execute the move
  timestart := dbms_utility.get_time();
  DBMS_OUTPUT.PUT_LINE(' >>> : ALTER TABLE FBI_FDR_BALANCE.BALANCE MOVE SUBPARTITION ' || table_cursor.subpartition_name );
  --execute immediate  ALTER TABLE FBI_FDR_BALANCE.BALANCE MOVE SUBPARTITION ' || table_cursor.subpartition_name;
  iElapsed_Time := (dbms_utility.get_time() - timestart)/100;

  -- get the final size
  select blocks into  iFinalSize from dba_segments where owner = 'FBI_FDR_BALANCE' and segment_name = sTableName and segment_type = 'TABLE SUBPARTITION' and partition_name = table_cursor.subpartition_name;

  DBMS_OUTPUT.PUT_LINE('Completed : ' || table_cursor.subpartition_name || ' Initial size : ' || iInitialSize || ' Final Size : ' || iFinalSize || ' Elapsed Time : ' ||  iElapsed_Time  );

  END LOOP;

end;
/
