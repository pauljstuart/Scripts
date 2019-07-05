




----------------- removing the histograms from SLICE_ID ------------------------------------------------------------


declare
 
    srec            dbms_stats.statrec;
    m_distcnt       number;
    m_density       number;
    m_nullcnt       number;
    m_avgclen       number;
 
    n_array                 dbms_stats.numarray;
    p_tableName VARCHAR2(64) := 'JOURNAL';
    p_tableOwner VARCHAR2(64) := 'ONEBALANCE';
    p_partition_name VARCHAR2(64) := 'JOU_R_20171204';
    p_column_name VARCHAR2(128) := 'SLICE_ID';
begin
 
    dbms_stats.get_column_stats(
        ownname     => p_tableOwner,
        tabname     => p_tableName,
        partname => p_partition_name,
        colname     => p_column_name,
        distcnt     => m_distcnt,
        density     => m_density,
        nullcnt     => m_nullcnt,
        srec        => srec,
        avgclen     => m_avgclen
    ); 
 
    srec.bkvals := null;

   srec.novals :=  dbms_stats.numarray(  0,   9999999999    );
    srec.epc := 2;
    dbms_stats.prepare_column_values(srec, srec.novals);
 
    m_density := 0.5;
 
    dbms_stats.set_column_stats(
        ownname     => p_tableOwner,
        tabname     => p_tableName,
        partname => p_partition_name,
        colname     => p_column_name,
        distcnt     => m_distcnt,
        density     => m_density,
        nullcnt     => m_nullcnt,
        srec        => srec,
        avgclen     => m_avgclen
    ); 
 
exception
    when others then
        raise;      -- should handle div/0
 
end;
/



-------------------------------------------------------------------------------------------------------------------------------------------
-- proc to set histogram min/max values :
-------------------------------------------------------------------------------------------------------------------------------------------

set serveroutput on
DECLARE

     v_srec                   dbms_stats.statrec;                    -- used to hold and adjust partition column stat info
      v_distcnt                number;
      v_density                number;
      v_nullcnt                number;
      v_avgclen                number;

      v_newValue               raw(400);
      v_minValue               raw(400);
      v_maxValue               raw(400);

      v_minDate                date;
      v_maxDate                date;
      p_repDate                date := to_date('02-OCT-2017','DD-MON-YYYY');
      l_date_column            all_part_key_columns.column_name%type := 'VALUE_DATE';
p_tableOwner VARCHAR2(64) := 'ONEBALANCE';
p_tableName  VARCHAR2(64)  := 'CASH_MOVE';
v_sourcePartition  VARCHAR2(64)  := 'CM_R_20171203';
p_targetPartition  VARCHAR2(64)  := 'CM_R_20171203';

   begin


            v_srec.epc := 2;  -- min and max
            dbms_stats.prepare_column_values(v_srec, dbms_stats.datearray(p_repDate, p_repDate));
            v_newValue := v_srec.minval;


            dbms_output.put_line('setting up global stats for ' || p_repDate || '  ' || v_newValue || ' ' || l_date_column);
            -- ---------------
            -- Now deal with the global table level stats
            dbms_stats.get_column_stats(ownname => p_tableOwner,
                                           tabname  => p_tableName,
                                           colname  => l_date_column,
                                           distcnt  => v_distcnt,
                                           density  => v_density,
                                           nullcnt  => v_nullcnt,
                                           srec     => v_srec,
                                           avgclen  => v_avgclen);

            dbms_stats.convert_raw_value(v_srec.minval, v_minDate);
            dbms_stats.convert_raw_value(v_srec.maxval, v_maxDate);
            dbms_output.put_line('Min : ' || v_minDate || ' Max : ' || v_maxDate );

            dbms_output.put_line('>> ' || p_repDate);

                dbms_output.put_line('setting new  high value ' );
               v_srec.maxval    := v_newValue;
               if v_srec.novals.exists(2) then
               v_srec.novals(2) := to_number(to_char(p_repDate,'J'));  -- upper bound of default bucket
               end if;


            dbms_stats.set_column_stats(ownname  => p_tableOwner,
                                           tabname  => p_tableName,
                                           colname  => l_date_column,
                                           distcnt  => v_distcnt,
                                           density  => v_density,
                                           nullcnt  => v_nullcnt,
                                           avgclen  => v_avgclen,
                                           srec     => v_srec,
                                           no_invalidate => false);


            -- ---------------
            -- Now deal with the  partition level stats


            dbms_stats.get_column_stats(ownname => p_tableOwner,
                                           tabname  => p_tableName,
                                           colname  => l_date_column,
                                           partname => v_sourcePartition,
                                           distcnt  => v_distcnt,
                                           density  => v_density,
                                           nullcnt  => v_nullcnt,
                                           srec     => v_srec,
                                           avgclen  => v_avgclen);

            v_srec.minval := v_newValue;   -- RSS 6th Nov - corrected to use value
            v_srec.maxval := v_newValue;
            if v_srec.novals.exists(1) then
              v_srec.novals(1) := to_number(to_char(p_repDate,'J'));
            end if;
            if v_srec.novals.exists(2) then
              v_srec.novals(2) := to_number(to_char(p_repDate,'J'));
            end if;

            dbms_stats.set_column_stats(ownname  => p_tableOwner,
                                           tabname  => p_tableName,
                                           partname => p_targetPartition,
                                           colname  => l_date_column,
                                           distcnt  => v_distcnt,
                                           density  => v_density,
                                           nullcnt  => v_nullcnt,
                                           avgclen  => v_avgclen,
                                            srec     => v_srec);


   end ;
/

--------------------------------------------------------------------------------------------------------------------------------




--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  pl/sql to set column stats : min and max value for a NUMBER column :
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------



set serveroutput on

DECLARE
   srec               DBMS_STATS.STATREC;
   low_value_raw      RAW (32);
   high_value_raw     RAW (32);
   low_value_value    NUMBER;
   high_value_value   NUMBER;
   max_value          NUMBER;
   m_distcnt          NUMBER;
   m_density          NUMBER;
   m_nullcnt          NUMBER;
   m_avgclen          NUMBER;
   novals             DBMS_STATS.NUMARRAY;
BEGIN

-------------------- get the current values from get_column_stats ----------------------------------------

   DBMS_STATS.get_column_stats (ownname      => 'MERIDIAN',
                                tabname      => 'TRADEBALANCE_MARKTOMARKET',
                                partname     => 'WORKFLOW11581',
                                colname      => 'WORKFLOW_ID',
                                distcnt      => m_distcnt,
                                density      => m_density,
                                nullcnt      => m_nullcnt,
                                srec         => srec,
                                avgclen      => m_avgclen
                               );

   DBMS_OUTPUT.put_line ('                                               ');
   DBMS_OUTPUT.put_line ('============== Get Column Stats =================');
   DBMS_OUTPUT.put_line ('Distinct Value Count:' || m_distcnt);
   DBMS_OUTPUT.put_line ('Column Destiny:' || m_density);
   DBMS_OUTPUT.put_line ('Null Value Count:' || m_nullcnt);
   DBMS_OUTPUT.put_line ('Average Column Length:' || m_avgclen);
   DBMS_OUTPUT.put_line (' The Number of the input parameter:' || srec.epc);
   DBMS_OUTPUT.put_line (' Minimum raw:' || srec.minval);
   DBMS_OUTPUT.put_line (' Maximum raw:' || srec.maxval);
 
   FOR i IN 1 .. srec.novals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Novals Number Array Is:'
                            || srec.novals (i)
                           );
   END LOOP;
 
   FOR i IN 1 .. srec.bkvals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Bkvals Number Array is:'
                            || srec.bkvals (i)
                           );
   END LOOP;
 
   FOR i IN 1 .. srec.chvals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Chvals Char Array Is:'
                            || srec.chvals (i)
                           );
   END LOOP;
 
   DBMS_OUTPUT.put_line ('                                               ');
 
 --------------------------- prepare the novals array with the correct values ------------------------------------
 
  select workflow_id INTO low_value_value from meridian.tradebalance_marktomarket partition (WORKFLOW11581)
  where rownum = 1;

  select workflow_id INTO high_value_value from meridian.tradebalance_marktomarket partition (WORKFLOW11581)
  where rownum = 1;


  -- use this to set them to an arbitrary value
  --low_value_value := 88;
  --high_value_value := 88;

  novals := DBMS_STATS.numarray (low_value_value, high_value_value);

  DBMS_OUTPUT.put_line ('Setting the column stats now.');

  DBMS_STATS.prepare_column_values (srec, novals);

----------------------- now set the column stats with new values --------------------------------------------------------------


  DBMS_OUTPUT.put_line ('                                               ');
  DBMS_STATS.set_column_stats (ownname      => 'MERIDIAN',
                                tabname      => 'TRADEBALANCE_MARKTOMARKET',
                                partname     => 'WORKFLOW11581',
                                colname      => 'WORKFLOW_ID',
                                distcnt      => m_distcnt,
                                density      => m_density,
                                nullcnt      => m_nullcnt,
                                srec         => srec,
                                avgclen      => m_avgclen
                               );


----  Check the values by after executing the dbms_stats.set_column_values  ----------------------


DBMS_STATS.get_column_stats (ownname      => 'MERIDIAN',
                                tabname      => 'TRADEBALANCE_MARKTOMARKET',
                                partname     => 'WORKFLOW11581',
                                colname      => 'WORKFLOW_ID',
                                distcnt      => m_distcnt,
                                density      => m_density,
                                nullcnt      => m_nullcnt,
                                srec         => srec,
                                avgclen      => m_avgclen
                               );

   DBMS_OUTPUT.put_line ('============== After Set Column Stats ===========');
   DBMS_OUTPUT.put_line ('Distinct Value Count:' || m_distcnt);
   DBMS_OUTPUT.put_line ('Column Destiny:' || m_density);
   DBMS_OUTPUT.put_line ('Null Value Count:' || m_nullcnt);
   DBMS_OUTPUT.put_line ('Average Column Length:' || m_avgclen);
   DBMS_OUTPUT.put_line (' The Number of the input parameter:' || srec.epc);
   DBMS_OUTPUT.put_line (' Minimum raw:' || srec.minval);
   DBMS_OUTPUT.put_line (' Maximum raw:' || srec.maxval);
 
   FOR i IN 1 .. srec.novals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Novals Number Array Is:'
                            || srec.novals (i)
                           );
   END LOOP;
 
   FOR i IN 1 .. srec.bkvals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Bkvals Number Array is:'
                            || srec.bkvals (i)
                           );
   END LOOP;
 
   FOR i IN 1 .. srec.chvals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Chvals Char Array Is:'
                            || srec.chvals (i)
                           );
   END LOOP;
 
   COMMIT;


END;
/




--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  pl/sql to set column stats : min and max value for a VARCHAR2 column :
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------




set serveroutput on
DECLARE
   srec               DBMS_STATS.STATREC;
   low_value_raw      RAW (32);
   high_value_raw     RAW (32);
   low_value_value    VARCHAR2(1024);
   high_value_value   VARCHAR2(1024);
   sPARTITION_NAME   VARCHAR2(1024) :=  'WORKFLOW967P7';
   sENDPOINT_VALUE   VARCHAR2(1024);
   sQUERY_STRING     VARCHAR2(4000);
   max_value          NUMBER;
   m_distcnt          NUMBER;
   m_density          NUMBER;
   m_nullcnt          NUMBER;
   m_avgclen          NUMBER;
   novals             DBMS_STATS.chararray;
   sHISTOGRAM_ENDPOINT_QUERY VARCHAR2(4000) ;

BEGIN


sHISTOGRAM_ENDPOINT_QUERY := q'#
SELECT 
  chr(to_number(SUBSTR(hex_val, 2,2),'XX'))
  || chr(to_number(SUBSTR(hex_val, 4,2),'XX'))
  || chr(to_number(SUBSTR(hex_val, 6,2),'XX'))
  || chr(to_number(SUBSTR(hex_val, 8,2),'XX'))
  || chr(to_number(SUBSTR(hex_val,10,2),'XX'))
  || chr(to_number(SUBSTR(hex_val,12,2),'XX')) endpoint_decoded
from
  (SELECT table_name, partition_name, column_name, BUCKET_NUMBER,
    lag(BUCKET_number,1) over( order by BUCKET_NUMBER ) prev_endpoint,
    TO_CHAR(endpoint_value,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')hex_val,
    endpoint_actual_value
  FROM dba_PART_histograms
  WHERE owner     = 'MVDS'
  AND table_name  = 'POSTING'
  AND column_name = 'PARTITION_ID'
AND PARTITION_NAME =  '#' 
|| sPARTITION_NAME || q'#'  AND BUCKET_NUMBER = 1 ) #';


-------------------- get the current values from get_column_stats ----------------------------------------

   DBMS_STATS.get_column_stats (ownname      => 'MVDS',
                                tabname      => 'POSTING',
                                partname     => sPARTITION_NAME,
                                colname      => 'PARTITION_ID',
                                distcnt      => m_distcnt,
                                density      => m_density,
                                nullcnt      => m_nullcnt,
                                srec         => srec,
                                avgclen      => m_avgclen
                               );

   DBMS_OUTPUT.put_line ('                                               ');
   DBMS_OUTPUT.put_line ('============== Get Column Stats =================');
   DBMS_OUTPUT.put_line ('Distinct Value Count:' || m_distcnt);
   DBMS_OUTPUT.put_line ('Column Destiny:' || m_density);
   DBMS_OUTPUT.put_line ('Null Value Count:' || m_nullcnt);
   DBMS_OUTPUT.put_line ('Average Column Length:' || m_avgclen);
   DBMS_OUTPUT.put_line (' The Number of the input parameter:' || srec.epc);
   DBMS_OUTPUT.put_line (' Minimum raw:' || srec.minval);
   DBMS_OUTPUT.put_line (' Maximum raw:' || srec.maxval);
 
   FOR i IN 1 .. srec.novals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Novals Number Array Is:'
                            || srec.novals (i)
                           );
   END LOOP;
 
   FOR i IN 1 .. srec.bkvals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Bkvals Number Array is:'
                            || srec.bkvals (i)
                           );
   END LOOP;
 
   FOR i IN 1 .. srec.chvals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Chvals Char Array Is:'
                            || srec.chvals (i)
                           );
   END LOOP;
 
   DBMS_OUTPUT.put_line ('                                               ');
 
 --------------------------- prepare the novals array with the correct values ------------------------------------
 
  sQUERY_STRING := 'select partition_id  from MVDS.POSTING partition (' || sPARTITION_NAME || ') where rownum = 1';

  execute immediate sQUERY_STRING into low_value_value;
  execute immediate sQUERY_STRING into high_value_value;

  execute immediate sHISTOGRAM_ENDPOINT_QUERY into sENDPOINT_VALUE;

  dbms_output.put_line('PARTITION_ID for ' || sPARTITION_NAME || ' is ' || low_value_value || '/' || high_value_value );
  dbms_output.put_line('Endpoint value is : ' || sENDPOINT_VALUE );

  -- use this to set them to an arbitrary value
  --low_value_value := 88;
  --high_value_value := 88;

  novals := DBMS_STATS.chararray (low_value_value, high_value_value);

  DBMS_OUTPUT.put_line ('Setting the column stats now.');

  DBMS_STATS.prepare_column_values (srec, novals);

----------------------- now set the column stats with new values --------------------------------------------------------------


  DBMS_OUTPUT.put_line ('                                               ');
  DBMS_STATS.set_column_stats (ownname      => 'MVDS',
                                tabname      => 'POSTING',
                                partname     => sPARTITION_NAME,
                                colname      => 'PARTITION_ID',
                                distcnt      => m_distcnt,
                                density      => m_density,
                                nullcnt      => m_nullcnt,
                                srec         => srec,
                                avgclen      => m_avgclen
                               );


----  Check the values by after executing the dbms_stats.set_column_values  ----------------------


DBMS_STATS.get_column_stats (ownname      => 'MVDS',
                                tabname      => 'POSTING',
                                partname     => sPARTITION_NAME,
                                colname      => 'PARTITION_ID',
                                distcnt      => m_distcnt,
                                density      => m_density,
                                nullcnt      => m_nullcnt,
                                srec         => srec,
                                avgclen      => m_avgclen
                               );

   DBMS_OUTPUT.put_line ('============== After Set Column Stats ===========');
   DBMS_OUTPUT.put_line ('Distinct Value Count:' || m_distcnt);
   DBMS_OUTPUT.put_line ('Column Destiny:' || m_density);
   DBMS_OUTPUT.put_line ('Null Value Count:' || m_nullcnt);
   DBMS_OUTPUT.put_line ('Average Column Length:' || m_avgclen);
   DBMS_OUTPUT.put_line (' The Number of the input parameter:' || srec.epc);
   DBMS_OUTPUT.put_line (' Minimum raw:' || srec.minval);
   DBMS_OUTPUT.put_line (' Maximum raw:' || srec.maxval);


  -- check the endpoint value again :
  execute immediate sHISTOGRAM_ENDPOINT_QUERY into sENDPOINT_VALUE;
 
   dbms_output.put_line('Endpoint value is now : ' || sENDPOINT_VALUE );

   FOR i IN 1 .. srec.novals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Novals Number Array Is:'
                            || srec.novals (i)
                           );
   END LOOP;
 
   FOR i IN 1 .. srec.bkvals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Bkvals Number Array is:'
                            || srec.bkvals (i)
                           );
   END LOOP;
 
   FOR i IN 1 .. srec.chvals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Chvals Char Array Is:'
                            || srec.chvals (i)
                           );
   END LOOP;
 
   COMMIT;


END;
/





--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- another example of setting column stats on a NUMBER column :
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------





set serveroutput on

DECLARE
   srec               DBMS_STATS.STATREC;
   low_value_raw      RAW (32);
   high_value_raw     RAW (32);
   low_value_value    NUMBER;
   high_value_value   NUMBER;
   max_value          NUMBER;
   m_distcnt          NUMBER;
   m_density          NUMBER;
   m_nullcnt          NUMBER;
   m_avgclen          NUMBER;
   novals             DBMS_STATS.NUMARRAY;
BEGIN

-------------------- get the current values from get_column_stats ----------------------------------------

   DBMS_STATS.get_column_stats (ownname      => 'ONEVIEW_DATA',
                                tabname      => 'OV_CALC_FACT',
                                partname     => 'P_20160226_MURX',
                                colname      => 'OV_DAY_KEY',
                                distcnt      => m_distcnt,
                                density      => m_density,
                                nullcnt      => m_nullcnt,
                                srec         => srec,
                                avgclen      => m_avgclen
                               );

   DBMS_OUTPUT.put_line ('                                               ');
   DBMS_OUTPUT.put_line ('============== Get Column Stats =================');
   DBMS_OUTPUT.put_line ('Distinct Value Count:' || m_distcnt);
   DBMS_OUTPUT.put_line ('Column Density:' || m_density);
   DBMS_OUTPUT.put_line ('Null Value Count:' || m_nullcnt);
   DBMS_OUTPUT.put_line ('Average Column Length:' || m_avgclen);
   DBMS_OUTPUT.put_line (' The Number of the input parameter:' || srec.epc);
   DBMS_OUTPUT.put_line (' Minimum raw:' || srec.minval);
   DBMS_OUTPUT.put_line (' Maximum raw:' || srec.maxval);
 
   FOR i IN 1 .. srec.novals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Novals Number Array Is:'
                            || srec.novals (i)
                           );
   END LOOP;
 

 
   DBMS_OUTPUT.put_line ('                                               ');
 
 --------------------------- prepare the novals array with the correct values ------------------------------------
 
  -- use this to set them to an arbitrary value
  low_value_value := 20160226;
  high_value_value := 20160226;

 novals := DBMS_STATS.numarray (low_value_value,high_value_value);
  srec.bkvals := NULL;
  srec.epc := 2;

  DBMS_OUTPUT.put_line ('Setting the column stats now.');

  DBMS_STATS.prepare_column_values (srec, novals);

----------------------- now set the column stats with new values --------------------------------------------------------------


  DBMS_OUTPUT.put_line ('                                               ');
   DBMS_STATS.set_column_stats (ownname      => 'ONEVIEW_DATA',
                                tabname      => 'OV_CALC_FACT',
                                partname     => 'P_20160226_MURX',
                                colname      => 'OV_DAY_KEY',
                                distcnt      => m_distcnt,
                                density      => m_density,
                                nullcnt      => m_nullcnt,
                                srec         => srec,
                                avgclen      => m_avgclen
                               );


----  Check the values by after executing the dbms_stats.set_column_values  ----------------------


   DBMS_STATS.get_column_stats (ownname      => 'ONEVIEW_DATA',
                                tabname      => 'OV_CALC_FACT',
                                partname     => 'P_20160226_MURX',
                                colname      => 'OV_DAY_KEY',
                                distcnt      => m_distcnt,
                                density      => m_density,
                                nullcnt      => m_nullcnt,
                                srec         => srec,
                                avgclen      => m_avgclen
                               );

   DBMS_OUTPUT.put_line ('============== After Set Column Stats ===========');
   DBMS_OUTPUT.put_line ('Distinct Value Count:' || m_distcnt);
   DBMS_OUTPUT.put_line ('Column Density:' || m_density);
   DBMS_OUTPUT.put_line ('Null Value Count:' || m_nullcnt);
   DBMS_OUTPUT.put_line ('Average Column Length:' || m_avgclen);
   DBMS_OUTPUT.put_line (' The Number of the input parameter:' || srec.epc);
   DBMS_OUTPUT.put_line (' Minimum raw:' || srec.minval);
   DBMS_OUTPUT.put_line (' Maximum raw:' || srec.maxval);
 
   FOR i IN 1 .. srec.novals.COUNT
   LOOP
      DBMS_OUTPUT.put_line (   ' The Input Value '
                            || i
                            || ' For Novals Number Array Is:'
                            || srec.novals (i)
                           );
   END LOOP;
 

 
   COMMIT;



END;
/
