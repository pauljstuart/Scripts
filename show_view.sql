

define VIEW_NAME=&2;
define OWNER=&1;



prompt
prompt VIEW_NAME : &2
prompt OWNER : &1
prompt




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
    DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
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
