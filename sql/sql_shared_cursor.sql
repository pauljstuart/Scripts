


COLUMN child_number FORMAT 99 HEADING "CHILD#"
COLUMN address FORMAT A16 HEADING "Address"


define SQL_ID=&1;

clear screen

SELECT  *
FROM gv$sql_shared_cursor
WHERE sql_id= '&SQL_ID'
ORDER BY sql_id;
