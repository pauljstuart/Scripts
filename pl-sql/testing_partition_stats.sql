
--how long do partition stats take?


SET SERVEROUTPUT ON
declare

 tsStartTime TIMESTAMP;    
tsEndTime TIMESTAMP;
sCommand VARCHAR2(1024);
iNumRows INTEGER;

sTableName VARCHAR2(1024) := 'POSTING';

begin

   --dbms_stats.delete_table_stats( ownname => 'MVDS', tabname => sTableName ) ;

  for CursorName  in (select partition_name from dba_tab_partitions where table_owner = 'MVDS' and table_name = sTableName )
    LOOP

        tsStartTime := CURRENT_TIMESTAMP;
     
       dbms_stats.gather_table_stats( ownname => 'MVDS', 
                    tabname => sTableName ,
                    partname =>  '' || CursorName.PARTITION_NAME || '',
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    degree => 16, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                    cascade => TRUE,
                    granularity => 'PARTITION' ) ; 

      tsEndTime := CURRENT_TIMESTAMP;
     
      select num_rows into iNumRows from dba_tab_partitions where table_owner = 'MVDS' and table_name = sTableName and partition_name = CursorName.PARTITION_NAME ;
      DBMS_OUTPUT.PUT_LINE('Partition ' || CursorName.PARTITION_NAME || ' >> Time elapsed: ' || round(extract( second from (tsEndTime - tsStartTime)), 1) || ' seconds for ' || iNumRows || ' rows.');
    END LOOP;

end;
