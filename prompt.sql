

set TERMOUT off
column X NEW_VALUE dbname 
select name as X from v$DATABASE;
set SQLPROMPT '[&dbname] SQL> '
set TERMOUT on

