


REF CURSORS ARE NOT DATA CONTAINERS.  ONCE OPENED, THEY ARE SIMPLY A POINTER TO A QUERY THAT HAS YET TO FETCH DATA.




declare

  stat_name    VARCHAR2(256);
  stat_value    INTEGER;
  TYPE  statistic_record IS RECORD ( name VARCHAR2(512),  value INTEGER );
  TYPE  my_stats_coll IS TABLE OF statistic_record;
  my_stats_cursor     SYS_REFCURSOR;

begin


dbms_output.put_line('test');

OPEN my_stats_cursor FOR 'select SN.name, SS.value FROM v$mystat SS, v$statname SN WHERE SS.statistic# = SN.statistic#';



LOOP                                        
   FETCH my_stats_cursor INTO stat_name, stat_value;

  DBMS_OUTPUT.PUT_LINE( RPAD( stat_name ,50,' ') || ' ' || stat_value );

  EXIT WHEN my_stats_cursor%NOTFOUND;
END LOOP;


CLOSE my_stats_cursor;


end;

