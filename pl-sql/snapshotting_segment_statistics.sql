

-- from Oracle Wait Interface, Shee et al

column statistic_name format A30

select owner,
	object_name,
	subobject_name,
	object_type,
	tablespace_name,
	value,
	statistic_name
from v$segment_statistics
where statistic_name = 'ITL waits'
and  value > 0
order by value;


-- getting two snapshots from v$segment_statistics and getting the delta, over 60 seconds


DECLARE

	TYPE             ASSOC_ARRAY_T IS TABLE OF INTEGER  INDEX BY VARCHAR2(256);
	StatArray        ASSOC_ARRAY_T;
	l_index          VARCHAR2(256);

BEGIN


  DBMS_OUTPUT.ENABLE ( NULL );
                                     
----------------- load the stats  ------------------------------------------------

 FOR r IN (select OBJECT_NAME, OBJECT_TYPE, STATISTIC_NAME, SUM(VALUE) VALUE from v$segment_statistics where owner = 'FDD' AND STATISTIC_NAME = 'physical write requests' GROUP BY OBJECT_NAME, OBJECT_TYPE, STATISTIC_NAME) 
    LOOP
       --dbms_output.put_line('loading ' || r.name );
      StatArray(r.OBJECT_NAME) := r.value;
    END LOOP;


  DBMS_LOCK.SLEEP(60);

----------------- now output the stats ------------------------------------------------

  DBMS_OUTPUT.PUT_LINE(chr(10) || 'Stats : ' || chr(10) );

 FOR r IN (select OBJECT_NAME, OBJECT_TYPE, STATISTIC_NAME, SUM(VALUE) VALUE from v$segment_statistics where owner = 'FDD' AND STATISTIC_NAME = 'physical write requests' GROUP BY OBJECT_NAME, OBJECT_TYPE, STATISTIC_NAME) 
    LOOP
    -- dbms_output.put_line('modifying ' || r.name || ' before ' || StatArray(r.name) || ' after ' || after );
    StatArray(r.OBJECT_NAME) :=  r.value - StatArray(r.OBJECT_NAME) ;
    END LOOP;

  -- now print out the array :
  l_index := StatArray.FIRST;
   WHILE (l_index is not null)
   LOOP
      IF ( StatArray(l_index) != 0  )
      THEN
        dbms_output.put_line( RPAD( l_index ,50,' ' )  || ' ' || StatArray(l_index) );
      END IF;
      l_index := StatArray.NEXT(l_index);
  END LOOP;
----------------------------------------------------------------------------------------


END;
/

