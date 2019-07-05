--------------------------------------------
-- This PL/SQL will run a particular SQL_ID straight out
-- of the dba_hist_sqltext
------------------------------------------------

declare
cursor_name INTEGER;
total_fetches INTEGER;

SQL_STRING  VARCHAR2(4024);

CURSOR SQL_ID_CUR IS
  select sql_text from dba_hist_sqltext where sql_id = '7p2s9hhwcbasm' ;
ret INTEGER;

BEGIN

OPEN SQL_ID_CUR;
FETCH  sql_id_cur into SQL_STRING;

cursor_name := DBMS_SQL.OPEN_CURSOR;
DBMS_SQL.PARSE(cursor_name, SQL_STRING, DBMS_SQL.NATIVE);



dbms_output.put_line(':::' || SQL_STRING);


ret := DBMS_SQL.EXECUTE(cursor_name);

total_fetches := 0;

LOOP                                        
  ret := DBMS_SQL.FETCH_ROWS(cursor_name);
  total_fetches := total_fetches + 1;

  EXIT WHEN ret = 0;
END LOOP;

  dbms_output.put_line('fetched ' || total_fetches || ' rows. ' );
  
DBMS_SQL.CLOSE_CURSOR(cursor_name);


END;
