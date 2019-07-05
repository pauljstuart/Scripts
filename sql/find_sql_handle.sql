
define SQL_ID=&1;

set serveroutput on

DECLARE
    l_sql   VARCHAR2 (32000);
    TargetSQL   VARCHAR2(32000);
    ClippedTargetSQL VARCHAR2(2000);
    TargetSQL_ID VARCHAR2(32);
BEGIN
    TargetSQL_ID := '&SQL_ID' ;
    dbms_output.put_line('SQL_ID : ' || TargetSQL_ID );
    select sql_text INTO TargetSQL from dba_hist_sqltext where sql_id = TargetSQL_ID;
    
    ClippedTargetSQL := substr( TargetSQL, 1, 1000);
    
    FOR clrec_data IN (SELECT * FROM dba_sql_plan_baselines  where created > SYSDATE - 30)
    LOOP
        l_sql := substr( clrec_data.sql_text, 1, 1000);
        IF ( l_sql = ClippedTargetSQL )
        THEN
            DBMS_OUTPUT.put_line ('sql handle : ' || clrec_data.sql_handle);
            EXIT;
        END IF;
    END LOOP;
END;
