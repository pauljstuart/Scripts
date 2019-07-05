
define USER=&1

prompt
prompt rebuilding all indexes for &USER
prompt


set serveroutput on


DECLARE
  

BEGIN

  dbms_output.enable( buffer_size => NULL);

  ------------------------------------------------------------------------------------------
  -- normal indexes
  ------------------------------------------------------------------------------------------ 
  DBMS_OUTPUT.PUT_LINE(chr(10) || 'Checking indexes : ' );
  DBMS_APPLICATION_INFO.SET_MODULE('Checking indexes', NULL);
  for C1 in (
    select  owner,  index_name, tablespace_name
    from all_indexes 
    where partitioned = 'NO' and status = 'UNUSABLE'
     and owner = '&USER')
    LOOP
      --DBMS_OUTPUT.PUT_LINE('Rebuilding index : ' || C1.index_name);
      dbms_output.put_line( 'alter index ' || c1.owner || '."' || C1.index_name || '" rebuild tablespace ' || C1.tablespace_name || ' parallel 8 ;' )  ;
      dbms_output.put_line( 'alter index ' || c1.owner || '."' || C1.index_name || '"  parallel 1 ;' )  ;
    END LOOP;


  ------------------------------------------------------------------------------------------
  -- partition indexes
  ------------------------------------------------------------------------------------------
  DBMS_OUTPUT.PUT_LINE(chr(10) || 'Checking partition indexes : ' );
  DBMS_APPLICATION_INFO.SET_MODULE('Checking partition indexes', NULL);
  for C2 in (select index_owner, index_name,  partition_name, tablespace_name from all_ind_partitions where  status = 'UNUSABLE' and index_owner = '&USER')
      LOOP
          --DBMS_OUTPUT.PUT_LINE('Rebuilding partition ' ||  C2.index_name || ' - ' || C2.partition_name ); 
          dbms_output.put_line( 'alter index ' || c2.index_owner || '."' || C2.index_name || q'#" rebuild partition #' || C2.partition_name || '  TABLESPACE ' || C2.tablespace_name || ' parallel 8 ; '  ) ;
      END LOOP;

   ------------------------------------------------------------------------------------------
  -- SUB-partition indexes
  ------------------------------------------------------------------------------------------
   DBMS_OUTPUT.PUT_LINE(chr(10) || 'Checking subpartition indexes : ' );
  DBMS_APPLICATION_INFO.SET_MODULE('Checking subpartition indexes', NULL);
   for C3 in (select index_owner, index_name, subpartition_name, tablespace_name from all_ind_subpartitions where  status= 'UNUSABLE' and index_owner = '&USER')
      LOOP
          --DBMS_OUTPUT.PUT_LINE('Rebuilding subpartition ' || C3.index_name || ' - ' || C3.subpartition_name );
          dbms_output.put_line(  'alter index ' || c3.index_owner || '."'  || C3.index_name || q'#" rebuild subpartition #' || C3.subpartition_name || '  TABLESPACE ' || C3.tablespace_name || ' parallel 8 ;' )  ;
      END LOOP;
     

end;
/
