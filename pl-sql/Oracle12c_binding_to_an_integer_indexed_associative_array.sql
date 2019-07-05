


CREATE OR REPLACE PACKAGE my_pkg
  AUTHID DEFINER
AS
  TYPE user_rt IS RECORD
  (
   city varchar2(100),
   fav_color VARCHAR2(100),
  age     NUMBER
  );

   TYPE users_t IS TABLE OF user_rt
   INDEX BY PLS_INTEGER;

END;
/


DECLARE
  dummy     NUMBER;
  cur     NUMBER;
  l_users  my_pkg.users_t;
  str    VARCHAR2(3000) = q'#


DECLARE
  dyn_users my_pkg.users_t;
BEGIN

  dyn_users := :my_users;

  DBMS_OUTPUT.PUT_LINE(  dyn_users (dyn_users.first).city);
  DBMS_OUTPUT.PUT_LINE(  dyn_users (dyn_users.first).fav_color);
  
END; #';

BEGIN

  l_users(100.city := 'Chicago';
  l_users(100.fav_color := 'Green';

  cur := DBMS_SQL.OPEN_CURSOR();
  DBMS_SQL.PARSE( cur, str, DBMS_SQL.NATIVE);
  DBMS_SQL.BIND_VARIABLE_PKG(cur, 'my_users', l_users );
  dummy := DBMS_SQL.EXECUTE( cur );
  DBMS_SQL.CLOSE_CURSOR();

END;
/

output :

Chicago
Green
