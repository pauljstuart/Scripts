-- GET the partition name :

set serveroutput on
declare

  v_partition_id VARCHAR2(128) := '69825_LDNBR';
  v_partition_name VARCHAR2(128);
  v_table_name VARCHAR2(128) := 'POSTING';
begin

FOR cursor1 in (
      select partition_name, high_value from ALL_tab_partitions
      where table_name = v_table_name and table_owner = 'MVDS')
loop
  if cursor1.high_value like  '%' || v_partition_id || '%' then
    v_partition_name := cursor1.partition_name;
  end if;
  dbms_output.put_line(v_partition_name);
end loop;
END;

-- converting LONG column into something else usable

set serveroutput on
declare

 c_test_clob   CLOB;

begin

FOR cursor1 in (
      SELECT TEXT    FROM DBA_VIEWS WHERE VIEW_NAME ='POSTING_V27' and owner = 'MVDS')
loop
  
     c_test_clob := cursor1.text;

  dbms_output.put_line(c_test_clob);
end loop;
END;



-- printing a LONG :


set serveroutput on
declare
 
  /* Declare local variables. */
  lv_cursor    INTEGER := dbms_sql.open_cursor;
  lv_feedback  INTEGER;         -- Acknowledgement of dynamic execution
  lv_length    INTEGER;          -- Length of string
  lv_stmt      VARCHAR2(2000);  -- Dynamic SQL statement
  lv_string    VARCHAR2(32760); -- Maximum length of LONG data type
  pv_column_length  INTEGER :=1000000;
 
BEGIN
  /* Create dynamic statement. */
  lv_stmt := 'select text from dba_views where view_name = upper(''&VIEW_NAME'') and owner = upper(''&OWNER'') ';
 
  /* Parse and define a long column. */
  dbms_sql.parse(lv_cursor, lv_stmt, dbms_sql.native);
  dbms_sql.define_column_long(lv_cursor,1);
 
  /* Only attempt to process the return value when fetched. */
  IF dbms_sql.execute_and_fetch(lv_cursor) = 1 THEN
    dbms_sql.column_value_long(
        lv_cursor
      , 1
      , pv_column_length
      , 0
      , lv_string
      , lv_length);
  END IF;
 
  /* Check for an open cursor. */
  IF dbms_sql.is_open(lv_cursor) THEN
    dbms_sql.close_cursor(lv_cursor);
  END IF;
 
   dbms_output.put_line('length : ' || lv_length);
   dbms_output.put_line(lv_string);

END;
/


-- extracting a LONG over 32K in length :



set serveroutput on
declare
 
  /* Declare local variables. */
  lv_cursor    INTEGER := dbms_sql.open_cursor;
  lv_feedback  INTEGER;         -- Acknowledgement of dynamic execution
  lv_length    INTEGER;          -- Length of string
  lv_stmt      VARCHAR2(2000);  -- Dynamic SQL statement
  lv_string    VARCHAR2(32760); -- Maximum length of LONG data type
  c_string    CLOB;
  pv_column_length  INTEGER :=32750;
  offset  integer;
 
BEGIN
  /* Create dynamic statement. */
  lv_stmt := 'select text from dba_views where view_name = upper(''SOURCE_INB_CUBE_V'') and owner = upper(''APP_BO_STAGE'') ';
 
  /* Parse and define a long column. */
  dbms_sql.parse(lv_cursor, lv_stmt, dbms_sql.native);
  dbms_sql.define_column_long(lv_cursor,1);
 
  /* Only attempt to process the return value when fetched. */
  offset := 0;
  IF dbms_sql.execute_and_fetch(lv_cursor) = 1 THEN
 
   while ( TRUE  ) 
   LOOP
    dbms_sql.column_value_long(  
        lv_cursor
      , 1
      , pv_column_length
      , offset
      , lv_string
      , lv_length);
    dbms_output.put_line('Got ' || lv_length);
    c_string := c_string || lv_string;
    offset := offset + lv_length;
    if ( lv_length = 0 )
    then
      exit;
    end if;

  END LOOP;

  END IF;
 
  /* Check for an open cursor. */
  IF dbms_sql.is_open(lv_cursor) THEN
    dbms_sql.close_cursor(lv_cursor);
  END IF;
 
   dbms_output.put_line('length : ' || offset);
    --dbms_output.put_line(c_string);

END;
/

