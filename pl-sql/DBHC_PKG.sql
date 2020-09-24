create or replace PACKAGE BODY DBHC_PKG
  AS

  ----------------------------------------------------------------------------
  --  NAME:      DBHC_PKG
  --  PURPOSE:   This package contains the code for the Database Health Check
  --  AUTHOR :   Paul Stuart
  --
  --
  --    CHANGE HISTORY :
  --
  --    Date        By             Version     Description
  --   ----------- --------------  ----------- --------------------------------------
  --   30-Apr-2020 Paul Stuart      1.0         Q2 2020 - First Release 
  --   05-Jun-2020 Paul Stuart      1.1         Fixes and enhancements 
  --   03-Sep-2020 Paul Stuart      1.2         Sept2020 - Fixes and enhancements 
  --   15-Sep-2020 Paul Stuart      1.3         xxxxxxxx
  --
  --
  ----------------------------------------------------------------------------


  
  
  ----------------------------------------------------------------------------
  -- OUTPUT_LOG
  --
  -- This procedure logs all output to a table
  --
  --  LOGGING LEVELS
  --
  -- There are only 3 levels.  the higher the level, the more logging you will see.
  --
  --  Level 3 - DEBUG
  --  Level 2 - INFO
  --  Level 1 - ERROR
  --
  --  This proc uses the global_log_level parameter to determine what to do with any given
  --  output statement.  Essentially, if the i_log_level you give to this proc is LESS THAN OR EQUAL to the
  --  global_log_level, then it will be output.
  -- 
  -- Which statements you see is determined by the global_log_level parameter.
  --
  -- global_log_level     Statements Logged
  -- ----------------     ----------------
  --     3                DEBUG, INFO & ERROR
  --     2                INFO, ERROR
  --     1                ERROR only
  --     0                (no output at all)
  --  
  -- So, normal operation would be global_log_level = 2
  --
  ----------------------------------------------------------------------------
  
  procedure OUTPUT_LOG(   p_process_name in VARCHAR2,  i_log_level INTEGER, p_text in CLOB ,   p_field1 IN VARCHAR2 DEFAULT NULL,  p_field2 IN VARCHAR2 DEFAULT NULL, p_error_code in INTEGER DEFAULT NULL )
  IS

    c_sqltext CLOB;
    s_open_mode VARCHAR2(1024);
  begin

    DBMS_OUTPUT.ENABLE( buffer_size => NULL);

    -- 11g situation
    SELECT OPEN_MODE INTO global_open_mode FROM V$DATABASE ;
    SELECT NAME INTO global_this_database FROM V$DATABASE ;

    -- 12c and pluggable situation :
    BEGIN
      c_sqltext := 'SELECT NAME, OPEN_MODE FROM  V$PDBS     WHERE CON_ID > 2';
      EXECUTE IMMEDIATE  c_sqltext into global_this_database, global_open_mode ;
    EXCEPTION
      WHEN OTHERS THEN
          null;
    END;

    IF ( global_log_level is null)  
       THEN
       global_log_level := INFO;
    END IF;

    IF ( (i_log_level <= global_log_level) AND (global_open_mode LIKE '%WRITE%' ) )
      THEN
         INSERT INTO  DBHC_LOG(process_name, database_name, log_category, log_time ,  log_text, INFO1, INFO2, error_code  ) 
                             values ( p_process_name ,  global_this_database,  decode(i_log_level, 3, 'DEBUG',2,'INFO',1,'ERROR'), SYSTIMESTAMP at time zone 'UTC',  p_text ,  p_field1, p_field2  ,  p_error_code  ) ;
        -- this odd situation here is due to the Active Dataguard, that does not like seeing COMMIT in the code anywhere.
        c_sqltext := 'COMMIT';
        EXECUTE IMMEDIATE c_sqltext;
    END IF;

  END OUTPUT_LOG;



    --------------------------------------------------------------------------------------
  -- INITIALISE
  --
  -- This proc sets some global variables.
  -- The idea is that all literals are kept together in this proc.  
  --------------------------------------------------------------------------------------

  PROCEDURE INITIALISE
  AS
    s_proc_name VARCHAR2(1024) := 'initialise';
   -- i_db_log_level INTEGER;
    s_sql_text CLOB;


      DOES_NOT_EXIST exception; 
      pragma exception_init( DOES_NOT_EXIST, -942 );

  BEGIN


    -- The first query is against V$DATABASE, which is correct for 11gR2. 
    SELECT NAME INTO global_this_database FROM V$DATABASE ;
    SELECT OPEN_MODE INTO global_open_mode FROM V$DATABASE ;
    SELECT USER INTO global_schema_name FROM DUAL;
    SELECT   regexp_substr( VERSION  , q'#([0-9]+)\..*#', 1,1,'i', 1) INTO global_db_version from product_component_version WHERE PRODUCT LIKE 'Oracle Database%';

    -- this block which checks for the database name from V$PDBS is for oracle versions 12 and over
    BEGIN
      s_sql_text := 'SELECT NAME, OPEN_MODE FROM  V$PDBS     WHERE CON_ID > 2';
      EXECUTE IMMEDIATE  s_sql_text into global_this_database, global_open_mode ;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          OUTPUT_LOG(s_proc_name, DEBUG,  'V$PDBS exists but is empty');
      WHEN DOES_NOT_EXIST THEN
          OUTPUT_LOG(s_proc_name, DEBUG,  'V$PDBS does not exist');
      WHEN OTHERS THEN
          OUTPUT_LOG(s_proc_name, DEBUG,  'Other error querying V$PDBS - ' || SQLERRM);
    END;


    BEGIN
      SELECT  DATABASE_ENVIRONMENT INTO global_this_environment from DBHC_DATABASES where DATABASE_NAME = global_this_database;
      SELECT  DATABASE_ROLE INTO global_database_role from DBHC_DATABASES where DATABASE_NAME = global_this_database;  
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      OUTPUT_LOG(s_proc_name, ERROR,  'An error occurred - ' || SQLERRM || ' - something is missing from the DBHC_DATABASES table');
    END;


    BEGIN
    -- This query establishes the order of precedence in the DBHC_VARIABLES TABLE : ALL, then ENVIRONMENT, then DATABASE_NAME  
    s_sql_text := q'#
    SELECT VARIABLE_VALUE  FROM (
                             SELECT ENVIRONMENT, (CASE ENVIRONMENT WHEN 'ALL' THEN 0  
                                                     WHEN :ENV                THEN 1
                                                     WHEN :DATABASE_NAME      THEN 2  
                                                     END ) AS VARIABLE_RANK, 
                                                        VARIABLE_VALUE
                                                        FROM DBHC_VARIABLES
                                WHERE    ENVIRONMENT IN ('ALL', :ENV, :DATABASE_NAME  ) 
                                AND       VARIABLE_NAME = :VARIABLE_NAME 
                             order by  2 desc
                            )
       where rownum = 1  #';


      EXECUTE IMMEDIATE s_sql_text into global_DBHC_version USING global_this_environment, global_this_database, global_this_environment, global_this_database ,  'DBHC_VERSION';
      EXECUTE IMMEDIATE s_sql_text into global_smtp_host USING global_this_environment, global_this_database, global_this_environment, global_this_database , 'SMTP_HOST';
      EXECUTE IMMEDIATE s_sql_text into global_smtp_port USING global_this_environment, global_this_database, global_this_environment, global_this_database ,  'SMTP_PORT';
      EXECUTE IMMEDIATE s_sql_text into global_smtp_from USING global_this_environment, global_this_database, global_this_environment, global_this_database , 'SMTP_FROM';
      EXECUTE IMMEDIATE s_sql_text into global_smtp_ACL USING  global_this_environment, global_this_database, global_this_environment, global_this_database ,'SMTP_ACL';
      EXECUTE IMMEDIATE s_sql_text into global_smtp_maxsize_bytes USING  global_this_environment, global_this_database, global_this_environment, global_this_database ,'SMTP_MAXSIZE_BYTES';
      EXECUTE IMMEDIATE s_sql_text into global_max_partition_days_mast USING  global_this_environment, global_this_database, global_this_environment, global_this_database ,'MAX_PARTITION_DAYS_MASTER';
      EXECUTE IMMEDIATE s_sql_text into global_max_partition_days_host USING global_this_environment, global_this_database, global_this_environment, global_this_database , 'MAX_PARTITION_DAYS_HOST';
      EXECUTE IMMEDIATE s_sql_text into global_default_admin USING  global_this_environment, global_this_database, global_this_environment, global_this_database ,'DEFAULT_ADMIN';
      EXECUTE IMMEDIATE s_sql_text into global_log_level USING global_this_environment, global_this_database, global_this_environment, global_this_database , 'LOG_LEVEL';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      OUTPUT_LOG(s_proc_name,  ERROR,  'An error occurred - ' || SQLERRM || ' - something is missing from the DBHC_VARIABLES table');
    END;

    --OUTPUT_LOG(s_proc_name, DEBUG, 'global_log_level : ' || global_log_level );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      OUTPUT_LOG(s_proc_name,  ERROR, 'An error occurred - ' || SQLERRM );

  END INITIALISE;


  ----------------------------------------------------------------------------
  -- GET_DATABASE_NAME
  --
  -- This function returns the database name
  ---------------------------------------------------------------------------- 

  FUNCTION GET_DATABASE_NAME
  RETURN VARCHAR2
  AS
    s_database_name VARCHAR2(512);
    s_proc_name VARCHAR2(512) := 'GET_DATABASE_NAME';
    s_sql_text clob;

      DOES_NOT_EXIST exception; 
      pragma exception_init( DOES_NOT_EXIST, -942 );
  BEGIN
    SELECT NAME INTO s_database_name FROM V$DATABASE ;
    OUTPUT_LOG(s_proc_name, DEBUG,  'V$PDBS exists but is empty');

    -- this block which checks for the database name from V$PDBS is for oracle versions 12 and over
    BEGIN
      s_sql_text := 'SELECT NAME, OPEN_MODE FROM  V$PDBS     WHERE CON_ID > 2';
      EXECUTE IMMEDIATE  s_sql_text into s_database_name;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          OUTPUT_LOG(s_proc_name, DEBUG,  'V$PDBS exists but is empty');
      WHEN DOES_NOT_EXIST THEN
          OUTPUT_LOG(s_proc_name, DEBUG,  'V$PDBS does not exist');
      WHEN OTHERS THEN
          OUTPUT_LOG(s_proc_name, DEBUG,  'Other error querying V$PDBS - ' || SQLERRM);
    END;

    RETURN( s_database_name );

  END GET_DATABASE_NAME;


  ----------------------------------------------------------------------------
  -- PRINT_GLOBAL_VARIABLES
  --
  -- This procedure prints all the global variables for this database
  --
  ----------------------------------------------------------------------------  

  PROCEDURE PRINT_GLOBAL_VARIABLES
  AS
    s_proc_name VARCHAR2(1024) := 'PRINT_GLOBAL_VARIABLES';
  BEGIN
    INITIALISE;

      DBMS_OUTPUT.PUT_LINE('global_this_database : ' || global_this_database);
      DBMS_OUTPUT.PUT_LINE('global_open_mode : ' || global_open_mode);
      DBMS_OUTPUT.PUT_LINE('global_schema_name : ' || global_schema_name);
      DBMS_OUTPUT.PUT_LINE('global_this_environment : ' || global_this_environment);
      DBMS_OUTPUT.PUT_LINE('global_database_role : ' || global_database_role);
      DBMS_OUTPUT.PUT_LINE('global_DBHC_version : ' || global_DBHC_version);
      DBMS_OUTPUT.PUT_LINE('global_smtp_host : ' || global_smtp_host  );
      DBMS_OUTPUT.PUT_LINE('global_smtp_port : ' || global_smtp_port );
      DBMS_OUTPUT.PUT_LINE('global_smtp_from ' || global_smtp_from  );
      DBMS_OUTPUT.PUT_LINE('global_smtp_ACL : ' || global_smtp_ACL );
      DBMS_OUTPUT.PUT_LINE('global_smtp_maxsize_bytes : ' || global_smtp_maxsize_bytes ); 
      DBMS_OUTPUT.PUT_LINE('global_max_partition_days_mast :  ' || global_max_partition_days_mast );
      DBMS_OUTPUT.PUT_LINE('global_max_partition_days_host : ' || global_max_partition_days_host );
      DBMS_OUTPUT.PUT_LINE('global_default_admin :' || global_default_admin );
      DBMS_OUTPUT.PUT_LINE('global_log_level : ' || global_log_level );

  END PRINT_GLOBAL_VARIABLES;



  ----------------------------------------------------------------------------
  -- ENABLE_CHECKS
  --
  -- This procedure enables all the SCHEDULER jobs
  --
  ----------------------------------------------------------------------------  
  PROCEDURE ENABLE_CHECKS
     AS 
    s_proc_name VARCHAR2(128) := 'ENABLE_CHECKS';
    i_count INTEGER;
  BEGIN


    OUTPUT_LOG(s_proc_name, INFO, 'Starting');

    FOR C1 IN ( SELECT JOB_NAME FROM USER_SCHEDULER_JOBS WHERE JOB_NAME LIKE 'CHECK_%')
    LOOP
        OUTPUT_LOG(s_proc_name, DEBUG, 'Enabling ' || C1.JOB_NAME);
        DBMS_SCHEDULER.ENABLE( name => C1.JOB_NAME );
    END LOOP;


    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM );
  END ENABLE_CHECKS;

  ----------------------------------------------------------------------------
  -- DISABLE_CHECKS
  --
  -- This procedure disables a particular check, or by default ALL checks
  --
  ----------------------------------------------------------------------------


  PROCEDURE DISABLE_CHECKS( i_check IN INTEGER DEFAULT NULL) 
  AS

    JOB_IS_RUNNING EXCEPTION;
    PRAGMA EXCEPTION_INIT(JOB_IS_RUNNING, -27478);

    s_check_string VARCHAR2(128);
    s_proc_name VARCHAR2(128) := 'DISABLE_CHECKS';
  BEGIN

    -- If no check number is passed in, disable all checks
    IF ( i_check IS NULL) 
      THEN
        s_check_string := 'CHECK_%';
    ELSE
        s_check_string := 'CHECK_' || i_check ;
    END IF;

    OUTPUT_LOG(s_proc_name, INFO, 'Starting with check string : ' ||  s_check_string);
    FOR C1 IN ( SELECT JOB_NAME FROM USER_SCHEDULER_JOBS WHERE JOB_NAME LIKE s_check_string )
    LOOP
        BEGIN
          OUTPUT_LOG(s_proc_name, DEBUG, 'Disabling  ' || C1.JOB_NAME);
          DBMS_SCHEDULER.DISABLE( name => C1.JOB_NAME, force => TRUE );
        EXCEPTION
          WHEN JOB_IS_RUNNING
             THEN
             STOP_JOB( C1.JOB_NAME);
             DBMS_SCHEDULER.DISABLE( name => C1.JOB_NAME, force => TRUE );
          WHEN OTHERS
             THEN
             OUTPUT_LOG(s_proc_name, ERROR,'Error when disabling job ' || C1.JOB_NAME || ' - ' || SQLERRM );
        END; 
    END LOOP;


    OUTPUT_LOG(s_proc_name, INFO, 'Finished disabling checks' );
  EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM );
  END DISABLE_CHECKS;

  ----------------------------------------------------------------------------
  -- STOP_JOB
  --
  -- This procedure stops a particular Scheduler job
  --
  ----------------------------------------------------------------------------

  PROCEDURE STOP_JOB( s_job_name IN VARCHAR2 ) 
  AS

   JOB_FAILED_TO_STOP EXCEPTION;
   PRAGMA EXCEPTION_INIT(JOB_FAILED_TO_STOP, -27365);

   BLOCK_INVALID EXCEPTION;
   PRAGMA EXCEPTION_INIT(BLOCK_INVALID, -06550);

  i_serial_num INTEGER;
  i_SID INTEGER;
  i_INST_ID INTEGER;
  s_justification VARCHAR2(2048);

  c_kill_session_text CLOB := 'BEGIN
                     SYS.KILL_SESSION( :sid, :serial, :username, :instance, :justification );
                     END;';
  s_proc_name VARCHAR2(128) := 'STOP_JOB';
  BEGIN

    OUTPUT_LOG(s_proc_name, INFO, 'Stopping ' || s_job_name  );
    BEGIN
       DBMS_SCHEDULER.STOP_JOB( job_name => s_job_name );
    EXCEPTION
       WHEN JOB_FAILED_TO_STOP
          THEN
          OUTPUT_LOG(s_proc_name, INFO, 'Couldnt stop  ' || s_job_name || ' nicely.  Trying to invoke KILL_SESSION'  );
          BEGIN
             SELECT   JOB_NAME,   SESSION_ID,   RUNNING_INSTANCE INTO i_SID, i_INST_ID, i_INST_ID
             FROM USER_SCHEDULER_RUNNING_JOBS 
             WHERE JOB_NAME = s_job_name;
             SELECT SERIAL# INTO i_serial_num FROM GV$SESSION WHERE SID = i_SID AND INST_ID = i_INST_ID;
             s_justification := 'DBHC procedure ' || s_proc_name || ' killing JOB_NAME :  ' || s_job_name ;
             EXECUTE IMMEDIATE c_kill_session_text using    i_SID ,  i_serial_num  , global_schema_name , i_INST_ID ,  s_justification ;
          EXCEPTION
             WHEN BLOCK_INVALID
               THEN
                OUTPUT_LOG(s_proc_name, ERROR, 'This user does not have access to the KILL_SESSION procedure.' ); 
             WHEN NO_DATA_FOUND
               THEN
               OUTPUT_LOG(s_proc_name, ERROR, 'I tried to find the session details to kill ' || s_job_name || ' but could not identify the session' ); 
          END;
       WHEN OTHERS 
          THEN
          OUTPUT_LOG(s_proc_name, ERROR, 'Other error when trying to stop the job : ' || s_job_name );
    END;

    OUTPUT_LOG(s_proc_name, DEBUG, 'Stopped ' || s_job_name  );

  EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM );  

  END STOP_JOB;

  ----------------------------------------------------------------------------
  -- STOP_CHECKS
  --
  -- This procedure stops a running check, or by default ALL running checks
  --
  ----------------------------------------------------------------------------

  PROCEDURE STOP_CHECKS( i_check INTEGER DEFAULT NULL) 
  AS

   s_check_string VARCHAR2(128);
   s_proc_name VARCHAR2(128) := 'STOP_CHECKS';

  BEGIN

    -- If no check number is passed in, disable all checks
    IF ( i_check IS NULL) 
      THEN
        s_check_string := 'CHECK_%';
    ELSE
        s_check_string := 'CHECK_' || i_check ;
    END IF;

   OUTPUT_LOG(s_proc_name, INFO, 'Stopping all running checks : ' ||  s_check_string);
  FOR C1 IN (
              SELECT   JOB_NAME,   JOB_STYLE,    DETACHED,  SESSION_ID,   RUNNING_INSTANCE
              FROM USER_SCHEDULER_RUNNING_JOBS 
               WHERE JOB_NAME LIKE s_check_string )
        LOOP
            OUTPUT_LOG(s_proc_name, INFO, 'About to stop check '  || C1.JOB_NAME );
            STOP_JOB( C1.JOB_NAME );
        END LOOP;

  OUTPUT_LOG(s_proc_name, INFO, 'Finishing');
  EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM ); 
  END STOP_CHECKS;

  ----------------------------------------------------------------------------
  -- DROP_CHECKS
  --
  -- This procedure drops all the SCHEDULER jobs
  --
  ----------------------------------------------------------------------------
    PROCEDURE DROP_CHECKS
     AS 
    s_proc_name VARCHAR2(128) := 'DROP_CHECKS';
    i_count INTEGER;
    BEGIN

    OUTPUT_LOG(s_proc_name, INFO, 'Starting');
    FOR C1 IN ( SELECT JOB_NAME FROM USER_SCHEDULER_JOBS WHERE JOB_NAME LIKE 'CHECK_%')
    LOOP
        OUTPUT_LOG(s_proc_name, DEBUG, 'Dropping ' || C1.JOB_NAME);
        DBMS_SCHEDULER.DROP_JOB( job_name => C1.JOB_NAME, force => TRUE );
    END LOOP;


    SELECT COUNT(*) INTO i_count FROM  USER_SCHEDULER_JOBS WHERE JOB_NAME LIKE 'CHECK_%';

    IF ( i_count > 0 )
      THEN
          OUTPUT_LOG(s_proc_name, INFO, 'There are ' || i_count || ' checks still in existence');
    END IF;

    OUTPUT_LOG(s_proc_name, DEBUG, 'Finishing');

    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM );
    END DROP_CHECKS;


  ----------------------------------------------------------------------------
  -- CREATE CHECKS
  --
  -- This procedure creates all the SCHEDULER jobs, if they don't exist already
  --
  ----------------------------------------------------------------------------
     PROCEDURE CREATE_CHECKS
     AS 

       s_proc_name VARCHAR2(128) := 'CREATE_CHECKS';
       i_offset_mins INTEGER := 5;
       s_remote_database VARCHAR2(128);
     BEGIN

    initialise;
    OUTPUT_LOG(s_proc_name, INFO, 'Starting');

    IF ( global_this_environment is NULL )
      THEN
      OUTPUT_LOG(s_proc_name, ERROR,'This database ' || global_this_database || ' does not appear in DBHC_DATABASES');
      REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name , p_notification_list => 'ADMIN',    p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => -1  ,	c_check_output => 'This database ' || global_this_database || ' does not appear in DBHC_DATABASES.  This can occur if the database name in the shadow.env file does not align with the database name in DBHC_DATABASES.' ) ;
      RETURN;
    ELSE
      OUTPUT_LOG(s_proc_name, INFO, 'Database ' || global_this_database || ' is part of ' || global_this_environment );
    END IF;

    SELECT  REMOTE_DATABASE_NAME INTO s_remote_database from DBHC_DATABASES WHERE DATABASE_NAME = global_this_database;
    IF (s_remote_database IS NOT NULL) 
       THEN
        OUTPUT_LOG(s_proc_name, DEBUG, 'There is a remote database too :  ' || s_remote_database);
    END IF;

    -- Iterate through all the checks.  There can be more than one check for a particular check number.  Different bind variables, or remote databases to run on
         
    for C1 IN ( 
        SELECT   DISTINCT
                CHECK_NO ,
                CHECK_FREQUENCY, 
                ACTIVE_FLAG
        FROM DBHC_CHECKS C
        WHERE ACTIVE_FLAG = 'Y' AND (APPLICABLE_DATABASES = global_this_database OR APPLICABLE_DATABASES LIKE '%' || global_this_database || ',%'   OR APPLICABLE_DATABASES LIKE '%,' || global_this_database  or APPLICABLE_DATABASES = 'ALL' )   
             AND ENVIRONMENT = global_this_environment
        UNION 
        SELECT     DISTINCT
                CHECK_NO ,
                CHECK_FREQUENCY, 
                ACTIVE_FLAG
        FROM DBHC_CHECKS C
        WHERE ACTIVE_FLAG = 'Y' AND (APPLICABLE_DATABASES = s_remote_database OR APPLICABLE_DATABASES LIKE '%' || s_remote_database || ',%'   OR APPLICABLE_DATABASES LIKE '%,' || s_remote_database  or APPLICABLE_DATABASES = 'ALL' )    
             AND ENVIRONMENT = global_this_environment
         AND s_remote_database is not null
         ORDER BY CHECK_NO
        )
        LOOP

       FOR C2 IN ( SELECT 1 FROM DUAL WHERE NOT EXISTS (SELECT JOB_NAME FROM USER_SCHEDULER_JOBS WHERE JOB_NAME = 'Check' || C1.CHECK_NO ))
          LOOP
          OUTPUT_LOG(s_proc_name, DEBUG, 'Creating check : ' || C1.check_no );

            BEGIN
               i_offset_mins := i_offset_mins + 1 ;
               DBMS_SCHEDULER.CREATE_JOB (
                  job_name => 'CHECK_' || C1.CHECK_NO, 
                  job_type => 'PLSQL_BLOCK',
                  job_action => '
                  BEGIN
                  DBHC_PKG.RUN_CHECK( i_check_no => ' || C1.CHECK_NO || ');
                  END; ',
                  repeat_interval => C1.CHECK_FREQUENCY,
                  enabled => true,
                   start_date => SYSTIMESTAMP + NUMTODSINTERVAL( i_offset_mins, 'MINUTE') ,
                  comments => 'CREATED ' || to_char(sysdate,'YYYY-MM-DD HH24:MI') || ' VERSION ' || global_DBHC_version );  
              EXCEPTION
                  WHEN OTHERS THEN
                  OUTPUT_LOG(s_proc_name, ERROR, 'Error when creating check : ' || C1.CHECK_NO   || ' - ' || SQLERRM );
            END;

            END LOOP;

        END LOOP; 


     COMMIT;

    OUTPUT_LOG(s_proc_name, DEBUG, 'Finishing');

    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name,ERROR, 'Other error : '  || SQLERRM );
    END CREATE_CHECKS;


  ----------------------------------------------------------------------------
  -- CHECK_SUPPRESS
  --
  -- This function checks the DBHC_SUPPRESS table, to find out if a record matches..
  --
  -- global variables :  global_this_environment
  --
  ----------------------------------------------------------------------------
  FUNCTION CHECK_SUPPRESS( p_database_name IN VARCHAR2, p_check_no IN INTEGER )
      RETURN INTEGER
   AS
      i_return_value INTEGER := 0;

    s_proc_name VARCHAR2(128) := 'CHECK_SUPPRESS' ; 
  BEGIN
  
      SELECT 1 INTO i_return_value 
                 FROM DBHC_SUPPRESS
                  WHERE SYSDATE > START_DATE AND SYSDATE < END_DATE
                  AND ENVIRONMENT = global_this_environment
                  AND (DATABASE_NAME = p_database_name OR DATABASE_NAME = 'ALL')
                  AND (CHECK_NO = p_check_no or CHECK_NO IS NULL);

    RETURN( i_return_value);

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN(0);
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM );
         RETURN( 0);
  END  CHECK_SUPPRESS;



  --------------------------------------------------------------------------------------
  -- RUN_CHECK
  --
  -- This is the proc that is executed by each Scheduler job, when it is time to run their check.
  --------------------------------------------------------------------------------------

  PROCEDURE RUN_CHECK( i_check_no INTEGER )
  AS

  s_proc_name VARCHAR2(128) := 'RUN_CHECK ' || i_check_no; 
  s_remote_database  VARCHAR2(1024);

    c_output CLOB := '' ;
    total_fetches INTEGER := 0;
    stopwatch        NUMBER := dbms_utility.get_time();
    start_time TIMESTAMP   := SYSTIMESTAMP;
    i_elapsed_time    NUMBER;
    i_boolean INTEGER;
  s_bind varchar2(128);

  BEGIN  


    INITIALISE;

    OUTPUT_LOG(s_proc_name, DEBUG, 'Starting check_no = ' || i_check_no);

    DBMS_APPLICATION_INFO.SET_MODULE(s_proc_name, s_proc_name );

    SELECT  REMOTE_DATABASE_NAME INTO s_remote_database from DBHC_DATABASES WHERE DATABASE_NAME = global_this_database;
    IF (s_remote_database IS NOT NULL) 
       THEN
        OUTPUT_LOG(s_proc_name, DEBUG, 'There is a remote database too :  ' || s_remote_database);
    END IF;

    -- Iterate through all the checks.  There can be more than one check for a particular check number.  Different bind variables, or remote databases to run on

    FOR C1 IN ( SELECT  global_this_database AS DATABASE_NAME,
        C.CHECK_NO ,
        S.CHECK_DESCRIPTION, 
        S.SQL_EXECUTION_METHOD, 
        S.CHECK_SQL_TEXT,
          ACTIVE_FLAG, 
          APPLICABLE_DATABASES, 
          ENVIRONMENT, 
          CHECK_NOTIFICATIONS,
          BIND_VARIABLES
        FROM DBHC_CHECKS C
        INNER JOIN DBHC_SQL S on S.CHECK_NO = C.CHECK_NO
        WHERE ACTIVE_FLAG = 'Y' AND (APPLICABLE_DATABASES = global_this_database OR APPLICABLE_DATABASES LIKE '%' || global_this_database || ',%'   OR APPLICABLE_DATABASES LIKE '%,' || global_this_database  or APPLICABLE_DATABASES = 'ALL' )   
             AND ENVIRONMENT = global_this_environment
          and C.check_no = i_check_no
        UNION ALL
        SELECT  s_remote_database AS DATABASE_NAME,
        C.CHECK_NO ,
        S.CHECK_DESCRIPTION, 
        S.SQL_EXECUTION_METHOD, 
        S.CHECK_SQL_TEXT,
          ACTIVE_FLAG, 
          APPLICABLE_DATABASES, 
          ENVIRONMENT, 
          CHECK_NOTIFICATIONS,
          BIND_VARIABLES
        FROM DBHC_CHECKS C
        INNER JOIN DBHC_SQL S on S.CHECK_NO = C.CHECK_NO
        WHERE ACTIVE_FLAG = 'Y' AND (APPLICABLE_DATABASES = s_remote_database OR APPLICABLE_DATABASES LIKE '%' || s_remote_database || ',%'   OR APPLICABLE_DATABASES LIKE '%,' || s_remote_database  or APPLICABLE_DATABASES = 'ALL' )    
             AND ENVIRONMENT = global_this_environment
          and C.check_no = i_check_no
         and S.check_category != 'Configuration'
         and s_remote_database is not null
        )
      LOOP

            ------------------------- SUPPRESS CHECK ---------------------------------------------
            i_boolean := CHECK_SUPPRESS( p_database_name => C1.DATABASE_NAME, p_check_no => C1.CHECK_NO );
            IF ( i_boolean = 1 ) 
              THEN
              OUTPUT_LOG(s_proc_name, INFO, 'check ' || C1.check_no || ' - description : [' || C1.CHECK_DESCRIPTION || ']  database : [' ||  C1.DATABASE_NAME || '] has been suppressed ');
              CONTINUE;
            END IF;

            OUTPUT_LOG(s_proc_name, INFO, 'Running check ' || C1.check_no || ' - description : [' || C1.CHECK_DESCRIPTION || '] bind variables : [' || C1.BIND_VARIABLES || ']  database : [' ||  C1.DATABASE_NAME || '] notification list : [' || C1.CHECK_NOTIFICATIONS || ']'  );
            IF ( C1.CHECK_SQL_TEXT IS NULL ) 
                   THEN
                   OUTPUT_LOG(s_proc_name, INFO, 'The SQL text for check ' || C1.CHECK_NO || ' is NULL');
                   CONTINUE;
            END IF;
            stopwatch    := dbms_utility.get_time();
            start_time    := SYSTIMESTAMP;


                  IF (C1.DATABASE_NAME = global_this_database)
                    THEN
               ---------------------------- local check ------------------------------------------
                            BEGIN
                               IF (C1.SQL_EXECUTION_METHOD = 'SQL') 
                               THEN
                                   EXECUTE_SQL( c_sql_text => C1.CHECK_SQL_TEXT , p_bind_variables => C1.BIND_VARIABLES, p_identifier => C1.CHECK_NO, c_sql_output => c_output, i_fetches => total_fetches) ;
                               ELSE  
                                  EXECUTE_PLSQL( c_sql_text => C1.CHECK_SQL_TEXT , p_bind_variables => C1.BIND_VARIABLES, p_identifier => C1.CHECK_NO, c_sql_output => c_output, i_fetches => total_fetches) ;
                               END IF;
                            EXCEPTION
                              WHEN OTHERS THEN
                                 OUTPUT_LOG(s_proc_name, ERROR, 'Error while executing check ' || i_check_no || ' : '  || SQLERRM );
                                 REGISTER_ALERT( p_check_no => i_check_no, p_check_description => C1.CHECK_DESCRIPTION , p_notification_list => 'ADMIN',  p_bind_variables =>  C1.BIND_VARIABLES ,   p_check_exec_time => start_time ,   p_check_elapsed_time  => -1  ,	c_check_output => SQLERRM ) ;
                                 DBMS_APPLICATION_INFO.SET_MODULE( NULL, NULL);
                                COMMIT;
                                CONTINUE;
                            END;
              -------------------------- remote check -------------------------------------------------
                    ELSE 
                            BEGIN
                               IF (C1.SQL_EXECUTION_METHOD = 'SQL') 
                               THEN
                                  EXECUTE_SQL_REMOTE( c_sql_text => C1.CHECK_SQL_TEXT , p_bind_variables => C1.BIND_VARIABLES, p_identifier => C1.CHECK_NO, p_remote_db_name => C1.DATABASE_NAME, c_sql_output => c_output, i_fetches => total_fetches) ;
                               ELSE
                                  EXECUTE_PLSQL_REMOTE( c_sql_text => C1.CHECK_SQL_TEXT , p_bind_variables => C1.BIND_VARIABLES, p_identifier => C1.CHECK_NO, p_remote_db_name => C1.DATABASE_NAME, c_sql_output => c_output, i_fetches => total_fetches) ;
                               END IF;        
                            EXCEPTION
                              WHEN OTHERS THEN
                                 OUTPUT_LOG(s_proc_name, ERROR, 'Error while executing remote check ' || i_check_no || ' on ' || C1.DATABASE_NAME || '  : '  || SQLERRM );
                                 REGISTER_ALERT( p_check_no => i_check_no, p_check_description => C1.CHECK_DESCRIPTION , p_notification_list => 'ADMIN', p_remote_database_name => C1.DATABASE_NAME,  p_bind_variables =>  C1.BIND_VARIABLES ,   p_check_exec_time => start_time ,   p_check_elapsed_time  => -1  ,	c_check_output => SQLERRM ) ;
                                 DBMS_APPLICATION_INFO.SET_MODULE( NULL, NULL);
                                COMMIT;
                                CONTINUE;
                           END;
                  END IF;

            -- The Check is now complete   
            i_elapsed_time := (dbms_utility.get_time() - stopwatch)/100; 
            OUTPUT_LOG(s_proc_name, INFO, 'statistics,check, ' || i_check_no || ',database,' || C1.DATABASE_NAME || ',total_fetches,' || total_fetches || ',elapsed_time,' || i_elapsed_time , i_check_no, i_elapsed_time  );
            IF ( total_fetches >=1 ) 
              THEN  
                IF (C1.DATABASE_NAME = global_this_database)
                    THEN
                      REGISTER_ALERT( p_check_no => i_check_no, p_check_description => C1.CHECK_DESCRIPTION , p_notification_list => C1.CHECK_NOTIFICATIONS,  p_bind_variables =>  C1.BIND_VARIABLES ,   p_check_exec_time => start_time ,   p_check_elapsed_time  => i_elapsed_time  ,	c_check_output => c_output ) ;
                    ELSE
                      REGISTER_ALERT( p_check_no => i_check_no, p_check_description => C1.CHECK_DESCRIPTION , p_notification_list => C1.CHECK_NOTIFICATIONS, p_remote_database_name => C1.DATABASE_NAME,  p_bind_variables =>  C1.BIND_VARIABLES ,   p_check_exec_time => start_time ,   p_check_elapsed_time  => i_elapsed_time  ,	c_check_output => c_output ) ;
                    END IF;
            END IF;


      END LOOP;   -- NEXT CHECK

    OUTPUT_LOG(s_proc_name, DEBUG, 'Finishing');
    DBMS_APPLICATION_INFO.SET_MODULE( NULL, NULL);
    COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM );
        COMMIT;
         DBMS_APPLICATION_INFO.SET_MODULE( NULL, NULL);
  END RUN_CHECK;



 
  ----------------------------------------------------------------------------
  -- ARCHIVE_HOST_PARTITIONS
  --
  -- This procedure ARCHIVES old partitions on a HOST database. 
  -- Old partitions are copied to the MASTER database before being dropped.
  --
  -- global variables :  global_max_partition_days_host
  --
  ----------------------------------------------------------------------------

  PROCEDURE ARCHIVE_HOST_PARTITIONS( p_db_link_name IN VARCHAR2 , p_max_age_days  IN INTEGER DEFAULT NULL  )
  AS
  /*
    TYPE DBHC_LOG_RECORDS is TABLE OF DBHC_LOG%ROWTYPE;
    T_OUTPUT_LOG DBHC_LOG_RECORDS;
    TYPE DBHC_ALERTS_RECORDS is TABLE OF DBHC_ALERTS%ROWTYPE;
    T_CHECK_ALERTS DBHC_ALERTS_RECORDS;
  */
    type VARCHAR_TABLE is table of VARCHAR2(256) INDEX BY PLS_INTEGER;
    V_PARTITION_ARRAY  VARCHAR_TABLE;
    i_count INTEGER;
    s_proc_name VARCHAR2(128) := 'ARCHIVE_HOST_PARTITIONS_' || p_db_link_name ; 
    i_max_age_days INTEGER;
    s_sql_text VARCHAR2(4000);

    s_remote_DDL VARCHAR2(1024) := 'BEGIN
                     dbms_utility.EXEC_DDL_STATEMENT@' || p_db_link_name || '( :1 ) ;  
                     END;';


      PLSQL_ERROR exception; 
      pragma exception_init( PLSQL_ERROR, -6550 );

  BEGIN

  INITIALISE;
  -- if no maximum age is passed in, then use the default value, which is stored globally :
  i_max_age_days := NVL(p_max_age_days, global_max_partition_days_host);

  OUTPUT_LOG(s_proc_name, INFO, 'Starting with i_max_age_days =  ' || i_max_age_days );

    IF ( global_database_role = 'HOST') 
      THEN
      OUTPUT_LOG(s_proc_name, ERROR, 'This proc is to be run on the MASTER only, not '  || global_this_database );
      RETURN;
    END IF;


  COMMIT;
  EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';

  FOR i in 1..V_TABLE_LIST.count
      LOOP
          OUTPUT_LOG(s_proc_name, INFO, 'Examining ' || V_TABLE_LIST(i) );
          -- Find the oldest partitions, over i_max_age_days

          s_sql_text :=   '  WITH PIVOT1 AS 
                       (SELECT  MAX(PARTITION_POSITION) AS MAX_POS, MIN(PARTITION_POSITION) AS MIN_POS FROM   USER_TAB_PARTITIONS@' || p_db_link_name || ' where TABLE_NAME =  :tablename )
                   select  PARTITION_NAME 
                    from USER_TAB_PARTITIONS@' || p_db_link_name || ', PIVOT1
                    where TABLE_NAME =  :tablename 
                    and   PARTITION_POSITION BETWEEN MIN_POS AND (MAX_POS - :maxagedays ) 
                        AND (MAX_POS - MIN_POS) > :maxagedays
                        AND PARTITION_POSITION != 1';

          EXECUTE IMMEDIATE s_sql_text BULK COLLECT INTO V_PARTITION_ARRAY USING V_TABLE_LIST(i) , V_TABLE_LIST(i) , i_max_age_days, i_max_age_days;
          FOR j IN 1..V_PARTITION_ARRAY.COUNT
          LOOP

              BEGIN
                OUTPUT_LOG(s_proc_name, DEBUG, 'About to copy  ' ||  V_TABLE_LIST(i) || ' partition '  || V_PARTITION_ARRAY(j)  );
                s_sql_text  := 'CREATE OR REPLACE VIEW TEMP_VIEW AS SELECT * FROM ' || V_TABLE_LIST(i) || ' PARTITION( ' || V_PARTITION_ARRAY(j) || ' )';
                EXECUTE IMMEDIATE s_remote_DDL using s_sql_text ;
/*
 -- getting this LOB error with this code block :

ORA-22992: cannot use LOB locators selected from remote tables

 fixed in 12c?

                IF ( V_TABLE_LIST(i) = 'DBHC_LOG' )        
                   THEN
                   s_sql_text := 'SELECT  * FROM TEMP_VIEW@' || p_db_link_name ;
                   EXECUTE IMMEDIATE s_sql_text BULK COLLECT INTO T_OUTPUT_LOG;
                   OUTPUT_LOG(s_proc_name, 'I got ' || T_OUTPUT_LOG.COUNT  || ' records from ' || V_TABLE_LIST(i) );
                END IF;
               IF ( V_TABLE_LIST(i) = 'DBHC_CHECK_ALERTS' )        
                   THEN
                    OUTPUT_LOG(s_proc_name, 'about to query DBHC_CHECK_ALERTS');
                   s_sql_text := 'SELECT  * FROM TEMP_VIEW@' || p_db_link_name ;
                   EXECUTE IMMEDIATE s_sql_text BULK COLLECT INTO T_CHECK_ALERTS;
                   OUTPUT_LOG(s_proc_name, 'I got ' || T_CHECK_ALERTS.COUNT || ' records from ' || V_TABLE_LIST(i) );
                END IF;
*/
                s_sql_text := 'SELECT COUNT(*)  from TEMP_VIEW@' || p_db_link_name ;
                EXECUTE IMMEDIATE s_sql_text INTO i_count;
                OUTPUT_LOG(s_proc_name, DEBUG, 'About to copy ' || i_count || ' records');
                s_sql_text := 'INSERT /*+ parallel(4)  */ INTO ' || V_TABLE_LIST(i) || '  SELECT /*+ parallel(4) */ * FROM TEMP_VIEW@' || p_db_link_name ;
                OUTPUT_LOG(s_proc_name, DEBUG, 'COPY STATEMENT : ' || s_sql_text );
                execute immediate s_sql_text;
                COMMIT;

                s_sql_text := 'DROP VIEW TEMP_VIEW';
                EXECUTE IMMEDIATE s_remote_DDL using s_sql_text ;
                COMMIT;
              EXCEPTION
                WHEN OTHERS THEN
                OUTPUT_LOG(s_proc_name, ERROR, 'Problems inserting into ' ||  V_TABLE_LIST(i) || ' - ' || SQLERRM  );
              END;
              BEGIN
                OUTPUT_LOG(s_proc_name, INFO,'About to drop the partition   ' ||  V_TABLE_LIST(i) || ' partition '  || V_PARTITION_ARRAY(j) ); 
                s_sql_text := 'ALTER TABLE  ' || V_TABLE_LIST(i) || ' DROP PARTITION ' || V_PARTITION_ARRAY(j) ;
                OUTPUT_LOG(s_proc_name, DEBUG, 'DROP STATEMENT : ' || s_sql_text );
                 EXECUTE IMMEDIATE s_remote_DDL using s_sql_text ;
              EXCEPTION
                WHEN OTHERS THEN
                OUTPUT_LOG(s_proc_name, ERROR, 'Problems dropping ' ||  V_TABLE_LIST(i) || ' partition '  || V_PARTITION_ARRAY(j)  || ' - ' || SQLERRM  );
              END;

           END LOOP;

    END LOOP;

    OUTPUT_LOG(s_proc_name, DEBUG, 'Gathering table statistics' );
    FOR i in 1..V_TABLE_LIST.count
      LOOP
      OUTPUT_LOG(s_proc_name, INFO, 'Gathering table statistics  on  ' || V_TABLE_LIST(i) );
      s_sql_text := 'BEGIN  
                     DBHC_PKG.GATHER_TABLE_STATS@'  || p_db_link_name || '( :table );
                     END;  ';
      OUTPUT_LOG(s_proc_name, DEBUG, 'gather statement :  ' ||  s_sql_text );
      BEGIN
      EXECUTE IMMEDIATE s_sql_text using V_TABLE_LIST(i) ;       
      EXCEPTION
         WHEN PLSQL_ERROR THEN
           OUTPUT_LOG(s_proc_name, DEBUG, 'DBHC_PKG does not appear to exist  '  );
         WHEN OTHERS THEN
           OUTPUT_LOG(s_proc_name, DEBUG, 'Error gathering stats ' || SQLERRM );
      END;

/*
      s_sql_text := ' BEGIN
      DBMS_STATS.GATHER_TABLE_STATS@' || p_db_link_name || q'#( ownname => :user , tabname => :table,   
                    partname => NULL,
                     block_sample => FALSE,
                      no_invalidate => TRUE,
                      DEGREE => 8, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    method_opt => 'FOR ALL COLUMNS SIZE 1',
                    cascade => FALSE,
                    granularity => 'ALL');
                    END;  #';
      OUTPUT_LOG(s_proc_name, DEBUG, 'gather statement :  ' ||  s_sql_text );
      EXECUTE IMMEDIATE s_sql_text using   global_schema_name, V_TABLE_LIST(i);
 */
      END LOOP;



    OUTPUT_LOG(s_proc_name, INFO, 'Finishing');
    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR,  'Other error : '  || SQLERRM );

  END ARCHIVE_HOST_PARTITIONS;

  ----------------------------------------------------------------------------
  -- GATHER_TABLE_STATS
  --
  --
  ----------------------------------------------------------------------------

  PROCEDURE GATHER_TABLE_STATS( p_table_name IN VARCHAR2)
  AS
  BEGIN
      DBMS_STATS.GATHER_TABLE_STATS( ownname => user , tabname => p_table_name,   
                    DEGREE => 8, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    method_opt => 'FOR ALL COLUMNS SIZE 1',
                    granularity => 'ALL');

  END GATHER_TABLE_STATS;

  ----------------------------------------------------------------------------
  -- HOUSEKEEPING_MASTER
  --
  -- This procedure drops old partitions and gathers stats, but only on the MASTER database
  --
  -- global variables :  global_max_partition_days_master
  --
  ----------------------------------------------------------------------------

  PROCEDURE HOUSEKEEPING_MASTER( p_max_age_days  IN INTEGER DEFAULT NULL  )
  AS

    s_proc_name VARCHAR2(128) := 'HOUSEKEEPING_MASTER' ; 
    i_max_age_days INTEGER;
  BEGIN

  INITIALISE;
  -- if no maximum age is passed in, then use the default value, which is stored globally :
  i_max_age_days := NVL(p_max_age_days, global_max_partition_days_mast);

  OUTPUT_LOG(s_proc_name, INFO ,'Starting with i_max_age_days =  ' || i_max_age_days );

    IF ( global_database_role = 'HOST') 
      THEN
      OUTPUT_LOG(s_proc_name, ERROR, 'This proc is to be run on the MASTER only, not '  || global_this_database );
      RETURN;
    END IF;



  FOR i in 1..V_TABLE_LIST.count
      LOOP
          OUTPUT_LOG(s_proc_name, INFO, 'Examining ' || V_TABLE_LIST(i) );
          -- Find the oldest partitions, over i_max_age_days
          FOR C1 IN (
                  WITH PIVOT1 AS 
                       (SELECT  MAX(PARTITION_POSITION) AS MAX_POS, MIN(PARTITION_POSITION) AS MIN_POS FROM   USER_TAB_PARTITIONS
                        where TABLE_NAME =  V_TABLE_LIST(i)
                       )
                   select PARTITION_POSITION, PARTITION_NAME 
                    from USER_TAB_PARTITIONS, PIVOT1
                    where TABLE_NAME =  V_TABLE_LIST(i) 
                    and   PARTITION_POSITION BETWEEN MIN_POS AND (MAX_POS - i_max_age_days) 
                        AND (MAX_POS - MIN_POS) > i_max_age_days
                         AND PARTITION_POSITION != 1
                    )
          LOOP
              OUTPUT_LOG(s_proc_name, INFO, 'About to drop partition ' || C1.partition_name );
              BEGIN
                  execute immediate 'alter table ' || V_TABLE_LIST(i)  || ' drop partition ' || C1.partition_name;
              EXCEPTION
                  WHEN OTHERS THEN
                  OUTPUT_LOG(s_proc_name, ERROR, 'Error dropping partition ' || C1.partition_name || ' from ' || V_TABLE_LIST(i) || ' - ' || SQLERRM );
              END;

               OUTPUT_LOG(s_proc_name, DEBUG,'Dropped partition ' || C1.partition_name );
           END LOOP;

    END LOOP;

    OUTPUT_LOG(s_proc_name, DEBUG, 'Gathering table statistics' );
    FOR i in 1..V_TABLE_LIST.count
      LOOP
      OUTPUT_LOG(s_proc_name, INFO, 'Gathering table statistics on  ' || V_TABLE_LIST(i) );
      DBMS_STATS.GATHER_TABLE_STATS( ownname => global_schema_name, tabname => V_TABLE_LIST(i),   
                   DEGREE => 8, 
                    partname => NULL,
                     block_sample => FALSE,
                      no_invalidate => TRUE,
                   cascade => FALSE,
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    method_opt => 'FOR ALL COLUMNS SIZE 1',
                    granularity => 'ALL');
      END LOOP;


    OUTPUT_LOG(s_proc_name, INFO, 'Finishing');
    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM );

  END HOUSEKEEPING_MASTER;



  ----------------------------------------------------------------------------
  -- EXPORT_CONFIGURATION
  --
  -- This procedure exports the configuration (ie non partitioned) tables for deployment in another environment
  --
  ---------------------------------------------------------------------------- 

  PROCEDURE EXPORT_CONFIGURATION
  AS
    s_disable_block VARCHAR2(4000) := q'#
BEGIN  
DBHC_PKG.DISABLE_CHECKS;     
END;
/ #' ;
    s_enable_block VARCHAR2(4000) := q'#
BEGIN  
DBHC_PKG.ENABLE_CHECKS;     
END;
/ #';
    s_file_name VARCHAR2(2000);
    s_proc_name VARCHAR2(128) := 'EXPORT_CONFIGURATION ' ; 
    c_sql_text CLOB;
    s_INSERT_STATEMENT VARCHAR2(32000);
    s_data_list VARCHAR2(32000);

    colVARCHAR2   VARCHAR2 (512);  
    colNUMBER   NUMBER; 
    colDATE    DATE;  
    colCLOB  CLOB;
    DB INTEGER;
    local_cursor_id INTEGER;
    VDescTab DBMS_SQL.desc_tab2;  
    i_CLOB_chunk_size INTEGER := 2000;
    i_num_chunks INTEGER;
    i_column_count INTEGER;

  BEGIN  
    INITIALISE;

    OUTPUT_LOG(s_proc_name, DEBUG,'Starting ' );

    UPDATE DBHC_DATABASES SET TEMP_CLOB = NULL;
    s_file_name := 'DBHC_EXPORT_VERSION_' || TO_CHAR(global_dbhc_version, 'FM9999999.99') || '_' || to_char(sysdate, 'DDMONYYYY') || '.sql';

    DBMS_OUTPUT.ENABLE( buffer_size => NULL);
    DBMS_OUTPUT.PUT_LINE(CHR(13) || CHR(10) );
    DBMS_OUTPUT.PUT_LINE('-- Instructions : Save this output to a SQL spool file');
    DBMS_OUTPUT.PUT_LINE('--Suggested spool file name : SPOOL ' || s_file_name );
    DBMS_OUTPUT.PUT_LINE(CHR(13) || CHR(10)  );
    DBMS_OUTPUT.PUT_LINE('PAUSE You are about to overwrite the DBHC configuration.  Proceed?' );
    DBMS_OUTPUT.PUT_LINE('SET DEFINE OFF');
    DBMS_OUTPUT.PUT_LINE('SET SERVEROUTPUT ON');
    DBMS_OUTPUT.PUT_LINE('PROMPT  DISABLING THE CHECKS '  );
    DBMS_OUTPUT.PUT_LINE(CHR(13) || CHR(10) );
    DBMS_OUTPUT.PUT_LINE(s_disable_block  );
    DBMS_OUTPUT.PUT_LINE( CHR(13) || CHR(10)  );

/*
    -- make a note of the current highest version, for use later
    DBMS_OUTPUT.PUT_LINE('DECLARE');
    DBMS_OUTPUT.PUT_LINE('  n_global_version NUMBER; ');
    DBMS_OUTPUT.PUT_LINE('BEGIN  ');
    DBMS_OUTPUT.PUT_LINE('  select VARIABLE_VALUE  into n_global_version  FROM DBHC_VARIABLES WHERE VARIABLE_NAME = ''DBHC_VERSION'' and ENVIRONMENT = ''ALL'' ;  ' );
    DBMS_OUTPUT.PUT_LINE('  dbms_application_info.set_client_info( n_global_version);  ' );
    DBMS_OUTPUT.PUT_LINE('EXCEPTION  ' );
    DBMS_OUTPUT.PUT_LINE('  WHEN NO_DATA_FOUND THEN  ' );
    DBMS_OUTPUT.PUT_LINE('  dbms_application_info.set_client_info( 0 );  ' );
    DBMS_OUTPUT.PUT_LINE('END; ');
    DBMS_OUTPUT.PUT_LINE('/');
*/

    FOR i in 1..V_TABLE_LIST.count
      LOOP
          FOR C1 IN ( SELECT * FROM USER_TABLES WHERE TABLE_NAME = V_TABLE_LIST(i) AND PARTITIONED = 'NO'      )
              LOOP
                DBMS_OUTPUT.PUT_LINE('PROMPT  UPDATING TABLE ' || V_TABLE_LIST(i)  );
                DBMS_OUTPUT.PUT_LINE(' TRUNCATE TABLE ' || V_TABLE_LIST(i) || ';' );
                -- now construct the INSERT statements to re-create the data in the table
                c_sql_text := 'SELECT  * FROM ' || V_TABLE_LIST(i) ;
                BEGIN
                      local_cursor_id := DBMS_SQL.OPEN_CURSOR;  
                      DBMS_SQL.PARSE (local_cursor_id, c_sql_text , DBMS_SQL.native);  
                      DBMS_SQL.DESCRIBE_COLUMNS2 (local_cursor_id, i_column_count, VDescTab);
                EXCEPTION
                      WHEN OTHERS THEN
                      OUTPUT_LOG(s_proc_name, ERROR, 'Issue compiling SQL - ' || SQLERRM);
                      RAISE;
                      RETURN;
                END ;
                DBMS_OUTPUT.PUT_LINE('-- ' || V_TABLE_LIST(i) );
                s_INSERT_STATEMENT := 'INSERT INTO ' || V_TABLE_LIST(i) || ' (' ;
                FOR y IN 1 .. i_column_count 
                  LOOP  
                         CASE VDescTab(y).col_type
                              WHEN dbms_types.TYPECODE_DATE  THEN
                                      DBMS_SQL.define_column(local_cursor_id, y, colDATE); 
                              WHEN dbms_types.TYPECODE_NUMBER THEN
                                      DBMS_SQL.define_column(local_cursor_id, y, colNUMBER); 
                              WHEN dbms_types.TYPECODE_VARCHAR2 THEN                    
                                      DBMS_SQL.define_column(local_cursor_id, y, colVARCHAR2, 512); 
                              WHEN dbms_types.TYPECODE_CLOB THEN                    
                                      DBMS_SQL.define_column(local_cursor_id, y, colCLOB );              
                              ELSE 
                                      DBMS_SQL.define_column(local_cursor_id, y, colVARCHAR2, 512); 
                         END CASE ;

                        -- now put the column names into the insert :
                         s_INSERT_STATEMENT := s_INSERT_STATEMENT  || VDescTab(y).col_name || ',';
                  END LOOP;
                -- finish the first part of the INSERT :
                s_INSERT_STATEMENT := substr(s_INSERT_STATEMENT, 1, length(s_INSERT_STATEMENT)-1); 
                s_INSERT_STATEMENT := s_INSERT_STATEMENT || ') VALUES (';

                --------------------------------------
                -- input section.  
                -- EXECUTE the query, and extract the data into the INSERT statement, one line at a time.
                --------------------------------------
                BEGIN
                   DB := DBMS_SQL.execute(local_cursor_id); 
                -- If the query returns no data, there's nothing more to do
                EXCEPTION
                  WHEN OTHERS THEN
                      OUTPUT_LOG(s_proc_name, ERROR, 'Error when executing  : ' || SQLERRM) ;
                      RAISE;
                      RETURN;
                END;
                -- iterate through every row and create an individual INSERT statement
                WHILE (DBMS_SQL.fetch_rows(local_cursor_id) > 0) 
                    LOOP     
                        -- construct the data string for this row
                        s_data_list := '';
                        FOR y iN 1..i_column_count 
                            LOOP
                               -- get the value from the column
                               CASE VDescTab(y).col_type
                                   when dbms_types.TYPECODE_DATE  THEN
                                             DBMS_SQL.COLUMN_VALUE(local_cursor_id, y, colDATE); 
                                             IF ( colDATE is NULL) THEN
                                               s_data_list := s_data_list || ' NULL,';
                                             ELSE
                                                s_data_list := s_data_list || ' TO_DATE(''' || TO_CHAR(ColDate,'YYYYMMDD HH24:MI.SS' )  || ''',''YYYYMMDD HH24:MI.SS'')  ,' ;
                                             END IF;
                                   WHEN dbms_types.TYPECODE_NUMBER THEN
                                            DBMS_SQL.COLUMN_VALUE(local_cursor_id, y, colNUMBER); 
                                            IF ( colNUMBER IS NULL) THEN 
                                               s_data_list := s_data_list || ' NULL,';
                                            ELSE
                                               s_data_list := s_data_list   || TO_CHAR(colNUMBER)  || ',';
                                            END IF;
                                   WHEN dbms_types.TYPECODE_VARCHAR2 THEN                    
                                            DBMS_SQL.COLUMN_VALUE(local_cursor_id, y, colVARCHAR2);
                                            IF ( colVARCHAR2 IS NULL) THEN 
                                               s_data_list := s_data_list || ' NULL,';
                                            ELSE
                                               s_data_list := s_data_list  || '''' ||  colVARCHAR2 || ''',';        
                                            END IF; 
                                   WHEN dbms_types.TYPECODE_CLOB THEN                    
                                           DBMS_SQL.COLUMN_VALUE(local_cursor_id, y, colCLOB);
                                           IF ( colCLOB IS NULL) THEN 
                                               s_data_list := s_data_list || ' NULL,';
                                           ELSE
                                               -- iterate through the CLOB i_CLOB_chunk_size at a time
                                               i_num_chunks := CEIL( DBMS_LOB.getLENGTH( colCLOB)/i_CLOB_chunk_size  ) ;                                              
                                               FOR I IN 1..i_num_chunks
                                                    LOOP
                                                    s_data_list := s_data_list  ||  'TO_CLOB( q''[' ||   DBMS_LOB.SUBSTR( colCLOB, i_CLOB_chunk_size, 1 + (i-1)*i_CLOB_chunk_size )  ||  ']'') ||'  ;
                                                    END LOOP;   
                                               -- remove the last two ||
                                               s_data_list := substr(s_data_list, 1, length(s_data_list)-2); 
                                               s_data_list := s_data_list  || ',';
                                           END IF; 
                                  ELSE 
                                             DBMS_SQL.COLUMN_VALUE(local_cursor_id, y, colVARCHAR2);  
                                             IF ( colVARCHAR2 IS NULL) THEN 
                                               s_data_list := s_data_list || ' NULL,';
                                            ELSE
                                               s_data_list := s_data_list || '''' || colVARCHAR2 || ''',';        
                                            END IF; 

                               END CASE ;    

                            END LOOP; 
                        -- this row is complete, now print the INSERT statement
                        s_data_list := substr(s_data_list, 1, length(s_data_list)-1);  
                        DBMS_OUTPUT.PUT_LINE(s_INSERT_STATEMENT || s_data_list  || ' );'  );

                    END LOOP;
                -- this table is complete.  print the commit, and on to the next
                DBMS_OUTPUT.PUT_LINE('COMMIT;' );
                DBMS_OUTPUT.PUT_LINE(  CHR(10) || CHR(10)  );
              END LOOP;
    END LOOP;


/*
 DBMS_OUTPUT.PUT_LINE('PROMPT  Updating the version '  );

    DBMS_OUTPUT.PUT_LINE('DECLARE ');
    DBMS_OUTPUT.PUT_LINE('   n_global_version NUMBER; ');
    DBMS_OUTPUT.PUT_LINE('BEGIN ');
    DBMS_OUTPUT.PUT_LINE('  dbms_application_info.read_client_info( n_global_version); ');
    DBMS_OUTPUT.PUT_LINE('  IF ( n_global_version IS NOT NULL)                                                                   ');
    DBMS_OUTPUT.PUT_LINE('    THEN                                                                                               ');
    DBMS_OUTPUT.PUT_LINE('       DBMS_OUTPUT.PUT_LINE(''Setting version to '' ||  to_number(n_global_version + 0.1)    );                           ');
    DBMS_OUTPUT.PUT_LINE('       UPDATE DBHC_VARIABLES SET VARIABLE_VALUE =  to_number(n_global_version + 0.1) WHERE VARIABLE_NAME = ''DBHC_VERSION''  AND ENVIRONMENT = ''ALL'' ;  ');
    DBMS_OUTPUT.PUT_LINE('END IF;                                                                          ');
    DBMS_OUTPUT.PUT_LINE('COMMIT; ');
    DBMS_OUTPUT.PUT_LINE('END;    ');
    DBMS_OUTPUT.PUT_LINE('/');
*/
    DBMS_OUTPUT.PUT_LINE('PROMPT  REENABLING CHECKS '  );
    DBMS_OUTPUT.PUT_LINE(CHR(13) || CHR(10) );
    DBMS_OUTPUT.PUT_LINE( s_enable_block );
    DBMS_OUTPUT.PUT_LINE( CHR(13) || CHR(10)  );

    DBMS_OUTPUT.PUT_LINE(CHR(13) || CHR(10) );

    DBMS_OUTPUT.PUT_LINE('PROMPT IMPORT DONE' );

  END EXPORT_CONFIGURATION;


  ----------------------------------------------------------------------------
  -- LOAD_CONFIGURATION
  --
  -- This procedure will load the DBHc configuration from another table in the MASTER database.
  --
  ----------------------------------------------------------------------------

  PROCEDURE LOAD_CONFIGURATION( p_user_id IN VARCHAR2 DEFAULT NULL )
  AS

  s_proc_name VARCHAR2(128) := 'LOAD_CONFIGURATION ' ; 
  s_user_id  VARCHAR2(256)  ;
  s_sql_text CLOB;
  i_count INTEGER;
  n_max_version NUMBER;
  s_change_flag VARCHAR2(1) := 'N';
  BEGIN

    INITIALISE;

    s_user_id   :=  NVL(p_user_id, global_default_admin );
    OUTPUT_LOG(s_proc_name, INFO, 'Starting with account  =  ' || s_user_id );

    -- you can only run this proc against MASTER databases, never the HOSTS
    IF ( global_database_role = 'HOST') 
      THEN
      OUTPUT_LOG(s_proc_name, ERROR, 'You can only do a LOAD_CONFIGURATION on the MASTER, not ' || global_this_database );
      RETURN;
    END IF;

    -- make a note of the max version
    SELECT MAX(VARIABLE_VALUE) INTO n_max_version FROM DBHC_VARIABLES WHERE VARIABLE_NAME = 'DBHC_VERSION' AND ENVIRONMENT = 'ALL';
    OUTPUT_LOG(s_proc_name, INFO, 'The max version here is ' || n_max_version );
    FOR i in 1..V_TABLE_LIST.count
      LOOP
          OUTPUT_LOG(s_proc_name, INFO, 'Examining ' || V_TABLE_LIST(i) );
          -- only select the non-partitioned tables
          FOR C1 IN ( SELECT * FROM USER_TABLES WHERE TABLE_NAME = V_TABLE_LIST(i) AND PARTITIONED = 'NO'      )
              LOOP
                  -- find out if the loading schema has a matching table name
                  SELECT count(*) INTO i_count FROM ALL_TABLES WHERE TABLE_NAME = V_TABLE_LIST(i) AND OWNER = s_user_id ;
                  IF (i_count = 1 )
                    THEN
                    OUTPUT_LOG(s_proc_name, INFO,'Loading config from  ' || s_user_id || '.' || V_TABLE_LIST(i) );
                    s_sql_text := 'DELETE FROM ' ||  V_TABLE_LIST(i);
                    EXECUTE IMMEDIATE s_sql_text;
                    s_sql_text := 'INSERT INTO ' ||  V_TABLE_LIST(i) || ' SELECT * FROM ' || s_user_id || '.' || V_TABLE_LIST(i)  ;
                    EXECUTE IMMEDIATE s_sql_text;
                    s_change_flag := 'Y';
                    COMMIT;
                    DBMS_OUTPUT.PUT_LINE('Loaded ' || V_TABLE_LIST(i) );
                  END IF;
              END LOOP;

    END LOOP;
/*
    IF ( s_change_flag = 'Y' )
      THEN
      OUTPUT_LOG(s_proc_name, INFO, 'Setting the version to ' || to_char(n_max_version + 0.1) );
      UPDATE DBHC_VARIABLES SET VARIABLE_VALUE =  (n_max_version + 0.1) WHERE VARIABLE_NAME = 'DBHC_VERSION' AND ENVIRONMENT = 'ALL' ;
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Set version to ' || n_max_version + 0.1);
      END IF;
*/
    OUTPUT_LOG(s_proc_name, INFO, 'Finishing');

  EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM );
         ROLLBACK;

  END LOAD_CONFIGURATION;

  ----------------------------------------------------------------------------
  -- DROP_EVERYTHING
  --
  -- This procedure drops all DBHC objects in the schema that it runs on.
  --
  -- This is intended to be run on a DBHC HOST, and as it's about to drop everything, it does not write to the normal log table
  --
  ----------------------------------------------------------------------------

  PROCEDURE DROP_EVERYTHING
  AS

  s_proc_name VARCHAR2(128) := 'DROP_EVERYTHING ' ; 
  s_sql_text CLOB ;

  BEGIN


    INITIALISE;

    -- you can only run this proc against HOST databases, never the MASTER
    IF ( global_database_role = 'MASTER') 
      THEN
      OUTPUT_LOG(s_proc_name, ERROR, 'Something tried to run DROP_EVERYTHING against the MASTER database ' || global_this_database );
      RETURN;
    END IF;
    --------------------------------------
    -- start by dropping any database links
    ----------------------------------------
    for C1 in (select db_link from user_db_links where db_link LIKE 'DBHC_%' )
      LOOP
      OUTPUT_LOG(s_proc_name, DEBUG,  ' Dropping database link ' || C1.db_link);
      s_sql_text := 'DROP database link ' || C1.db_link ;
      execute immediate s_sql_text;
      END LOOP;

    --------------------------------------
    -- Now dropping any existing checks
    ----------------------------------------

     DBHC_PKG.DISABLE_CHECKS;  
     DBHC_PKG.DROP_CHECKS;

    --------------------------------------
    --  Now drop the DBHC tables 
    ----------------------------------------

    for i in 1..V_TABLE_LIST.count
      LOOP
       DBMS_OUTPUT.PUT_LINE(s_proc_name ||  ' Dropping ' || V_TABLE_LIST(i)  );

      s_sql_text  :=  'drop table ' || V_TABLE_LIST(i) ;
      BEGIN
        EXECUTE IMMEDIATE   s_sql_text ;
      EXCEPTION
         WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE(s_proc_name || ' The table ' ||V_TABLE_LIST(i) || '  does not appear to be in ' || global_this_database );
      END;

      END LOOP;
      --------------------------------------
    --  Now drop the DBHC views 
    ----------------------------------------

    for i in 1..V_VIEW_LIST.count
      LOOP
       DBMS_OUTPUT.PUT_LINE(s_proc_name ||  ' Dropping view ' || V_VIEW_LIST(i)  );

      s_sql_text  :=  'DROP VIEW ' || V_VIEW_LIST(i) ;
      BEGIN
        EXECUTE IMMEDIATE   s_sql_text ;
      EXCEPTION
         WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE(s_proc_name || ' The view ' || V_VIEW_LIST(i) || '  does not appear to be in ' || global_this_database );
      END;

      END LOOP;

    DBMS_OUTPUT.PUT_LINE(s_proc_name || ' Finishing  '   );

    EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE(s_proc_name || ' Other error : '  || SQLERRM );

  END DROP_EVERYTHING;


  --------------------------------------------------------------------------------------
  -- REGISTER_ALERT
  --
  -- This proc sends a DBHC alert.  It sends the alert via email, and logs it to a table
  --
  --------------------------------------------------------------------------------------


  PROCEDURE REGISTER_ALERT( p_check_no INTEGER , p_check_description VARCHAR2 ,  p_notification_list VARCHAR2 DEFAULT NULL, p_remote_database_name VARCHAR2 DEFAULT NULL, p_bind_variables  VARCHAR2 DEFAULT NULL ,   p_check_exec_time TIMESTAMP ,   p_check_elapsed_time  NUMBER ,	c_check_output  CLOB )
  AS

    s_proc_name VARCHAR2(4000) := 'REGISTER_ALERT - CHECK ' || p_check_no;
     s_target_email_address VARCHAR2(4000);
    s_sql_text CLOB;
    s_mail_body  CLOB;
    s_mail_subject  VARCHAR2(4000);

    V_BIND_LIST tableRecords;
    V_NOTIFICATION_LIST tableRecords;
    s_check_description_with_binds VARCHAR2(1024);
    s_email_DL_list VARCHAR2(30000);
  BEGIN
    OUTPUT_LOG(s_proc_name, DEBUG,'Starting.  Notify list is : ' || p_notification_list );
    INITIALISE;

    IF (p_check_no IS NULL)
      THEN
      OUTPUT_LOG(s_proc_name,ERROR, 'p_check_no parameter cannot be NULL');
      RETURN;
    END IF;
    IF (p_notification_list IS NULL)
      THEN
      OUTPUT_LOG(s_proc_name,DEBUG, 'p_notification_list is NULL');
    END IF;


    -- convert the bind variable string to nested table 
    POPULATE_CSV_ARRAY(s_csv_string => p_bind_variables , t_csv_table => V_BIND_LIST );
    s_check_description_with_binds := p_check_description;
    -- replace any bind variables in the description 
    FOR i IN 1..V_BIND_LIST.COUNT
      LOOP
      s_check_description_with_binds := REPLACE(s_check_description_with_binds, ':' || i , V_BIND_LIST(i) );
      END LOOP;

    -- convert the notification list string to a nested table  
    POPULATE_CSV_ARRAY(s_csv_string => p_notification_list , t_csv_table => V_NOTIFICATION_LIST );

    -- iterate through all notifications list, and identify the releveant DLs
    FOR i IN 1..V_NOTIFICATION_LIST.COUNT
      LOOP
        OUTPUT_LOG(s_proc_name, DEBUG, 'examining notification alias ' || V_NOTIFICATION_LIST(i) ); 
        --s_sql_text := q'#SELECT VARIABLE_VALUE FROM DBHC_VARIABLES WHERE  ENVIRONMENT IN ('ALL', :env )  AND  VARIABLE_NAME = :item_value AND VARIABLE_TYPE = 'EMAIL_ALIAS' ORDER BY ENVIRONMENT #'; 
        s_sql_text := q'#
                        SELECT VARIABLE_VALUE  FROM (
                                                 SELECT ENVIRONMENT, (CASE ENVIRONMENT WHEN 'ALL' THEN 0  
                                                                         WHEN :ENV                THEN 1
                                                                         WHEN :DATABASE_NAME      THEN 2  
                                                                         END ) AS VARIABLE_RANK, 
                                                                            VARIABLE_VALUE
                                                                            FROM DBHC_VARIABLES
                                                    WHERE    ENVIRONMENT IN ('ALL', :ENV, :DATABASE_NAME  ) 
                                                    AND       VARIABLE_NAME = :item_value 
                                                    AND       VARIABLE_TYPE = 'EMAIL_ALIAS'
                                                 order by  2 desc
                                                )
                           where rownum = 1  #';

        BEGIN
           EXECUTE IMMEDIATE s_sql_text INTO   s_target_email_address USING global_this_environment, global_this_database, global_this_environment, global_this_database, V_NOTIFICATION_LIST(i) ;        
           s_email_DL_list := s_email_DL_list  || s_target_email_address || ',';
           OUTPUT_LOG(s_proc_name, DEBUG, 'Identified email alias ' || p_notification_list || ' -> ' || V_NOTIFICATION_LIST(i) || ' - ' || s_target_email_address  );
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          OUTPUT_LOG(s_proc_name, INFO, 'Check ' || p_check_no || ' notification includes ' || V_NOTIFICATION_LIST(i) || ' but there is no value in DBHC_VARIABLES for that' );
        END;

      END LOOP;
    -- now remove the final comma, if any
    IF (  INSTR(s_email_DL_list, ',',   Length(s_email_DL_list)  )  >= 1 )
        THEN
        s_email_DL_list := substr(s_email_DL_list, 1, length(s_email_DL_list)-1); 
    END IF;

    -- create the email subject and body 
    s_mail_subject  := '[DBHC ' || global_this_environment || '] ' || NVL(p_remote_database_name, global_this_database)  || ' - ' || s_check_description_with_binds  ;


    s_mail_body := '-------------------------------------------------' || CHR(13) || CHR(10);
    s_mail_body := s_mail_body || 'Check Number         : ' || p_check_no || CHR(13) || CHR(10);
    s_mail_body := s_mail_body || 'Check Description    : ' || s_check_description_with_binds || CHR(13) || CHR(10);
    s_mail_body := s_mail_body || 'Bind Variables       : ' || p_bind_variables || CHR(13) || CHR(10);
    s_mail_body := s_mail_body || 'Database             : ' ||  NVL(p_remote_database_name, global_this_database) || CHR(13) || CHR(10);
    s_mail_body := s_mail_body || 'Time Taken (seconds) : ' || p_check_elapsed_time || CHR(13) || CHR(10);
    s_mail_body := s_mail_body || 'Notification List    : ' || p_notification_list || CHR(13) || CHR(10);
    s_mail_body := s_mail_body || 'Email List           : ' || replace(s_email_DL_list, ',' , ';')  || CHR(13) || CHR(10);
    IF ( p_remote_database_name IS NOT NULL) 
      THEN
        s_mail_body := s_mail_body || 'Check run from       : ' || global_this_database || CHR(13) || CHR(10);
      END IF;
    s_mail_body := s_mail_body ||  '-------------------------------------------------' || CHR(13) || CHR(10)  || CHR(13) || CHR(10);

    -- finally tack on the output
    s_mail_body := s_mail_body || c_check_output ;

    -- now send the emails 
    IF ( V_NOTIFICATION_LIST.COUNT > 0 )
      THEN
        OUTPUT_LOG(s_proc_name, DEBUG, 'sending alert to <<' || s_email_DL_list  || '>>  length : ' || length(s_mail_body) );
        send_mail (      p_to       => s_email_DL_list,    p_subject =>    s_mail_subject,              p_clob_message   => s_mail_body);
    END IF;

    OUTPUT_LOG(s_proc_name, DEBUG, 'Writing to DBHC_ALERTS'  );
    -- email alerts are all sent, now put in the DBHC_CHECK_ALERTS table :
    INSERT INTO DBHC_ALERTS(	CHECK_NO ,	CHECK_DESCRIPTION , ENVIRONMENT , DATABASE_NAME,    BIND_VARIABLES  ,    CHECK_EXECUTION_TIME ,   CHECK_ELAPSED_TIME ,	CHECK_OUTPUT, EMAIL_SENT )
                  VALUES ( p_check_no, s_check_description_with_binds , global_this_environment, NVL(p_remote_database_name, global_this_database),  p_bind_variables , cast(p_check_exec_time as timestamp) at time zone 'UTC', p_check_elapsed_time, c_check_output ,       s_email_DL_list ) ;

    COMMIT;

    EXCEPTION 
      WHEN OTHERS THEN
         COMMIT;
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error : '  || SQLERRM );


  END REGISTER_ALERT;

  --------------------------------------------------------------------------------------
  -- PRINT_CLOB
  --
  -- This proc prints any CLOB to DBMS_OUTPUT.
  --
  -- Very useful when run inside a PLSQL type check
  --------------------------------------------------------------------------------------


  PROCEDURE PRINT_CLOB (      c_target_clob   IN CLOB)
  AS
    s_proc_name VARCHAR2(1024) := 'PRINT_CLOB';
           i_linecount INTEGER;
           i_thisline integer;
           i_endofline INTEGER;
           i_lengthofline INTEGER;
           s_oneline varchar2(32767);
           offset INTEGER := 1;
           i_length INTEGER;

  BEGIN

    IF ( c_target_clob is NULL) 
      THEN
       OUTPUT_LOG(s_proc_name, INFO, 'NULL clob passed in' );
       RETURN;
    END IF;

    i_length := NVL(dbms_lob.getlength( c_target_clob), 0) ;
    OUTPUT_LOG(s_proc_name, DEBUG, 'This clob is of length : ' || i_length || ' bytes' );

    IF ( i_length = 0) 
      THEN
       RETURN;
    END IF;

    SELECT regexp_count(c_target_clob, chr (10)) into i_linecount from dual;
    OUTPUT_LOG(s_proc_name, DEBUG, 'This clob has  ' || i_linecount || ' lines' );    
    DBMS_OUTPUT.ENABLE( buffer_size => NULL);

    FOR i_thisline IN 1..i_linecount+1
      LOOP

          if (i_thisline = i_linecount+1) -- last line situation
          then
            i_endofline :=  dbms_lob.getlength(c_target_clob);
          else
            i_endofline := DBMS_LOB.INSTR( c_target_clob, chr(10), 1 , i_thisline  );
          end if;

          i_lengthofline := greatest(i_endofline - offset, 1);

          dbms_lob.read(c_target_clob, i_lengthofline, offset, s_oneline);
          dbms_output.put_line( s_oneline);
          offset := i_endofline+1;
      END LOOP;

  END PRINT_CLOB;



  --------------------------------------------------------------------------------------
  -- SEND_MAIL
  --
  -- This proc sends email using UTL_SMTP.
  --
  -- uses these global variables :  global_smtp_host, global_smtp_port
  --------------------------------------------------------------------------------------


  PROCEDURE SEND_MAIL (                  p_to        IN VARCHAR2,
                                         p_subject   IN VARCHAR2,
                                         p_clob_message   IN CLOB)
  AS
    l_mail_conn   UTL_SMTP.connection;
    s_proc_name VARCHAR2(1024) := 'SEND_EMAIL';
    i_length INTEGER;
    i_CLOB_chunk_size INTEGER := 2000;
    s_buffer     varchar2(32000);
    i_num_chunks INTEGER;
    V_EMAIL_LIST tableRecords;

  BEGIN

    INITIALISE;

    IF ( INSTR(p_to, ',') > 0 )
      THEN 
      -- this deals with the situation where p_to is a comma separated list of email addresses.  In this case, split them out and call SEND_MAIL for each one
      POPULATE_CSV_ARRAY(s_csv_string => p_to , t_csv_table => V_EMAIL_LIST );
      FOR i IN 1..V_EMAIL_LIST.COUNT
        LOOP
           OUTPUT_LOG(s_proc_name, DEBUG, 'Identified email address  :' ||  i ||' - ' || V_EMAIL_LIST(i) );
          SEND_MAIL(    p_to    => V_EMAIL_LIST(i),    p_subject   => p_subject,   p_clob_message => p_clob_message ) ;
        END LOOP;
      RETURN;
    END IF;

    i_length := dbms_lob.getlength( p_clob_message);
    OUTPUT_LOG(s_proc_name, DEBUG, 'This message is of length : ' || i_length || ' bytes' );
    OUTPUT_LOG(s_proc_name, DEBUG, 'The max length defined in global_smtp_maxsize_bytes is : ' || global_smtp_maxsize_bytes );
    OUTPUT_LOG(s_proc_name, DEBUG,  'p_to : [' || p_to || ']    p_subject : [' || p_subject || ']' );

    l_mail_conn := UTL_SMTP.open_connection(global_smtp_host, global_smtp_port );
    UTL_SMTP.helo(l_mail_conn, global_smtp_host);
    UTL_SMTP.mail(l_mail_conn, global_smtp_from);
    UTL_SMTP.rcpt(l_mail_conn, p_to);

    UTL_SMTP.open_data(l_mail_conn);

    UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'From: ' || global_smtp_from || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || global_smtp_from || UTL_TCP.crlf || UTL_TCP.crlf);

    -- check this doesn't exceed the max message size
    i_length := LEAST(global_smtp_maxsize_bytes, i_length);

    -- iterate through the CLOB, i_CLOB_chunk_size bytes at a time
    i_num_chunks := CEIL( i_length/i_CLOB_chunk_size  ) ;
    FOR I IN 1..i_num_chunks
          LOOP
          s_buffer := DBMS_LOB.SUBSTR( p_clob_message, i_CLOB_chunk_size, 1 + (i-1)*i_CLOB_chunk_size ) ;
          UTL_SMTP.write_data(l_mail_conn, s_buffer );                                                                                     
          END LOOP; 

    IF (dbms_lob.getlength( p_clob_message) > global_smtp_maxsize_bytes )
          THEN    
            UTL_SMTP.write_data(l_mail_conn,  UTL_TCP.crlf || UTL_TCP.crlf);
            UTL_SMTP.write_data(l_mail_conn, 'The maximum smtp message size of ' || global_smtp_maxsize_bytes || ' was reached');
            OUTPUT_LOG(s_proc_name, DEBUG, 'The maximum smtp message size of ' || global_smtp_maxsize_bytes || ' was reached');
          END IF;

    UTL_SMTP.write_data(l_mail_conn,  UTL_TCP.crlf || UTL_TCP.crlf);
    UTL_SMTP.close_data(l_mail_conn);  
    UTL_SMTP.quit(l_mail_conn);


  EXCEPTION 
    WHEN OTHERS THEN
          OUTPUT_LOG(s_proc_name, ERROR, 'An error occurred  - ' || SQLERRM );
          OUTPUT_LOG(s_proc_name, DEBUG,  'p_clob_message >> ' || p_clob_message );
          UTL_SMTP.close_data(l_mail_conn);  
          UTL_SMTP.quit(l_mail_conn);

  END SEND_MAIL;




  ----------------------------------------------------------------------------
  -- CHECK_PRIVS
  --
  -- This proc checks that the account at the end of a particular database link has all the required privileges
  --
  -- The required roles and privileges are kept in the global VARRAYs V_PRIVILEGES_LIST and V_ROLES_LIST
  --
  -- this function return 1 for SUCCESS (ie all roles and privileges found), or 0 for FAILURE.
  --
  ----------------------------------------------------------------------------

  FUNCTION CHECK_PRIVS(  p_db_link_name VARCHAR2 ) 
      RETURN INTEGER
  AS
    s_sql_text CLOB;
    s_proc_name VARCHAR2(1024) := 'CHECK_PRIVS ' || p_db_link_name ;
    i_count INTEGER;
  BEGIN

     -- check the privileges
     FOR i in 1..V_PRIVILEGE_LIST.count
      LOOP
            s_sql_text := 'SELECT COUNT(*)  FROM USER_SYS_PRIVS@' || p_db_link_name || ' WHERE PRIVILEGE = :1';
            execute immediate s_sql_text   INTO i_count  USING V_PRIVILEGE_LIST(i);
            IF ( i_count = 0 )
            THEN
              OUTPUT_LOG(s_proc_name, INFO, p_db_link_name || ' lacks ' || V_PRIVILEGE_LIST(i)  );
              REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,  p_notification_list => 'ADMIN', p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  =>  p_db_link_name || ' lacks privilege ' || V_PRIVILEGE_LIST(i) );
              RETURN 0;
            ELSE
               OUTPUT_LOG(s_proc_name, DEBUG, p_db_link_name || ' has ' || V_PRIVILEGE_LIST(i)   );
            END IF;
      END LOOP;  

     -- check the database roles
     FOR i in 1..V_ROLE_LIST.count
      LOOP
            s_sql_text := 'SELECT COUNT(*)  FROM USER_ROLE_PRIVS@' || p_db_link_name || ' WHERE GRANTED_ROLE = :1';
            EXECUTE IMMEDIATE s_sql_text   INTO i_count USING V_ROLE_LIST(i);
            IF ( i_count = 0 )
            THEN
              OUTPUT_LOG(s_proc_name, INFO,  p_db_link_name || ' lacks ' || V_ROLE_LIST(i)   );
             REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,  p_notification_list => 'ADMIN', p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  =>  p_db_link_name || ' lacks role ' || V_ROLE_LIST(i)   );

              RETURN 0;
            ELSE
               OUTPUT_LOG(s_proc_name, DEBUG, p_db_link_name || ' has ' || V_ROLE_LIST(i)   );
            END IF;
      END LOOP;  

    -- check the network ACLS

     FOR i in 1..V_ACL_LIST.count
      LOOP
            s_sql_text := 'SELECT count(*) FROM DBA_NETWORK_ACL_PRIVILEGES@' || p_db_link_name || ' WHERE  ACL = :1 and principal = :2 and PRIVILEGE = :3 ';
            OUTPUT_LOG(s_proc_name, DEBUG, 'checking network ACLs : ' || s_sql_text );
           -- OUTPUT_LOG(s_proc_name, DEBUG, 'global_smtp_acl : ' || global_smtp_ACL );
          --  OUTPUT_LOG(s_proc_name, DEBUG, 'global_schema_name : ' || global_schema_name );
           -- OUTPUT_LOG(s_proc_name, DEBUG, 'V_ACL_LIST() : ' || V_ACL_LIST(i) );
            EXECUTE IMMEDIATE s_sql_text   INTO i_count USING global_smtp_ACL, global_schema_name, V_ACL_LIST(i);
            IF ( i_count = 0 )
            THEN
              OUTPUT_LOG(s_proc_name, INFO,  p_db_link_name || ' lacks ' || V_ACL_LIST(i) || ' on ACL ' || global_smtp_ACL );
              REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,  p_notification_list => 'ADMIN', p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  => p_db_link_name || ' lacks ' || V_ACL_LIST(i) || ' on ACL ' || global_smtp_ACL );
              RETURN 0;
            ELSE
               OUTPUT_LOG(s_proc_name, DEBUG, p_db_link_name || ' has ' || V_ACL_LIST(i)   || ' on ACL ' || global_smtp_ACL );
            END IF;
      END LOOP;  

    -- ie success
    RETURN 1;

  EXCEPTION
           WHEN OTHERS THEN
           OUTPUT_LOG(s_proc_name, ERROR, 'Other error when checking privileges ' || p_db_link_name || ' - '  || SQLERRM );
           RETURN 0;
  END CHECK_PRIVS;


  ----------------------------------------------------------------------------
  -- POPULATE_CSV_ARRAY
  --
  -- This proc accepts a Comma separated string, and returns an array of the same values
  --
  --
  ----------------------------------------------------------------------------

  PROCEDURE POPULATE_CSV_ARRAY( s_csv_string in VARCHAR2, t_csv_table OUT tableRecords)
  AS
    s_proc_name VARCHAR2(256) := 'POPULATE_CSV_ARRAY ' ;
  BEGIN
    t_csv_table := tableRecords();


                  FOR FOO IN (    SELECT REGEXP_SUBSTR (s_csv_string,  '[^,]+',  1,   LEVEL)   TXT, LEVEL    FROM DUAL
                               CONNECT BY REGEXP_SUBSTR (s_csv_string,   '[^,]+',  1,   LEVEL)      IS NOT NULL)
                   LOOP
                       IF ( FOO.TXT IS NOT NULL ) THEN
                         OUTPUT_LOG(s_proc_name, DEBUG, 'Identified csv item : ' ||  FOO.LEVEL ||' - ' || FOO.TXT );
                         t_csv_table.EXTEND;
                         t_csv_table(FOO.LEVEL) :=  FOO.TXT;
                       END IF;
                  END LOOP;

    -- OUTPUT_LOG(s_proc_name, DEBUG, 'Loaded : ' || t_csv_table.COUNT || ' csv items');

  END  POPULATE_CSV_ARRAY;

  ----------------------------------------------------------------------------
  -- DEPLOY_DBHC_MASTER
  --
  -- This proc deploys the checks to the MASTER DBHC database.
  --
  -- There is a smaller set of things that need to be done on the MASTER database, as it obviously
  -- has all the code and tables already.
  --
  ----------------------------------------------------------------------------

    PROCEDURE DEPLOY_DBHC_MASTER ( p_USERID VARCHAR2, p_PASSWORD VARCHAR2, p_DATABASE_NAME VARCHAR2)
    AS
      s_db_link_name VARCHAR2(1024) := 'DBHC_TO_' ;
      s_proc_name VARCHAR2(256) := 'DEPLOY_DBHC_MASTER ' || p_DATABASE_NAME ; 
      s_remote_connect_string VARCHAR2(4000);
      s_sql_text CLOB;
      i_master_DBHC_version NUMBER;
    BEGIN
        OUTPUT_LOG(s_proc_name, INFO, 'Deploying to Master database ' || p_DATABASE_NAME );
        INITIALISE;
        COMMIT;
    -----------------------
    -- Run the housekeeping check - this happens every time this proc is run, which is every 4 hours
    ----------------------
    HOUSEKEEPING_MASTER;

    -----------------------
    -- find the DBHC version for the MASTER.
    -- obviously the code or tables in the master never change, but without a version like all the other databases, the 
    -- checks would be re-created every time this is run, and we don't want that.
    ----------------------

    s_sql_text := 'select DBHC_VERSION FROM DBHC_DATABASES  WHERE DATABASE_NAME = :1 ';
    BEGIN
         execute immediate s_sql_text into i_master_DBHC_version using p_DATABASE_NAME ;
    EXCEPTION
                   WHEN  OTHERS THEN
                      OUTPUT_LOG(s_proc_name, ERROR, 'No DBHC_DATABASE table in ' || s_db_link_name || ' - ' || SQLCODE || ' - ' || SQLERRM );
    END;
    OUTPUT_LOG(s_proc_name, INFO, 'Local version for ' || p_DATABASE_NAME || ' is  ' || i_master_DBHC_version);
    OUTPUT_LOG(s_proc_name, INFO, 'Central version for ' || global_this_environment || ' is  ' || global_DBHC_version);

    if ( i_master_DBHC_version = global_DBHC_version ) 
      THEN
      OUTPUT_LOG(s_proc_name, INFO, 'Local version is fine.  Ending.');
      RETURN;
    END IF;

    -- If the versions are different, we re-create all the Checks, and also all the database links

    BEGIN
        OUTPUT_LOG(s_proc_name, INFO, 'Dropping checks'  );
        DBHC_PKG.DROP_CHECKS;
        OUTPUT_LOG(s_proc_name, INFO, 'Creating checks'  );
        DBHC_PKG.CREATE_CHECKS;
    EXCEPTION
           WHEN OTHERS THEN
           OUTPUT_LOG(s_proc_name, ERROR,  'Other error when creating the checks on  ' || p_DATABASE_NAME || ' - '  || SQLERRM );
           REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name , p_notification_list => 'ADMIN',  p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  =>  'Other error when creating the checks on  ' || p_DATABASE_NAME || ' - ' || SQLERRM );
    END;

    --------------------------------------
    --  Now create any database links which are needed for remote checks
    ----------------------------------------
    -- NOTE : there is an obvious limitation here.  The password on the remote database must be the same as this one.
    --        That is not a big limitation, as this facility is intended for Active Dataguard instances, where that will obviously always be the case.
    FOR C1 IN ( SELECT  REMOTE_DATABASE_NAME 
               FROM DBHC_DATABASES
               WHERE DATABASE_NAME = p_DATABASE_NAME
               AND REMOTE_DATABASE_NAME IS NOT NULL)
      LOOP
        OUTPUT_LOG(s_proc_name, INFO, 'Creating database link on ' || p_DATABASE_NAME || ' for target database ' || C1.REMOTE_DATABASE_NAME );
        s_db_link_name := 'DBHC_TO_' || C1.REMOTE_DATABASE_NAME;
        SELECT DATABASE_CONNECT_STRING INTO s_remote_connect_string FROM DBHC_DATABASES WHERE DATABASE_NAME = C1.REMOTE_DATABASE_NAME;  
        BEGIN
                OUTPUT_LOG(s_proc_name, INFO, 'Start by dropping any existing link with name ' || s_db_link_name );
                s_sql_text := 'DROP DATABASE LINK ' || s_db_link_name ;
                EXECUTE IMMEDIATE  s_sql_text;
        EXCEPTION
                   WHEN OTHERS THEN
                   OUTPUT_LOG(s_proc_name, ERROR, 'Error when dropping ' || s_db_link_name || ' possibly it did not exist ');
        END;
        BEGIN 
              OUTPUT_LOG(s_proc_name, INFO,  'About to create local db link  ' || s_db_link_name );
              OUTPUT_LOG(s_proc_name, DEBUG,  'About to create local db link with sql text : create database link ' || s_db_link_name || '  connect to ' || p_USERID || ' identified by  xxxxx  using ''' || s_remote_connect_string || '''' );
              s_sql_text := 'create database link ' || s_db_link_name || '  connect to ' || p_USERID || ' identified by  "' || p_PASSWORD || '" using ''' || s_remote_connect_string || '''';
              EXECUTE IMMEDIATE  s_sql_text;
        EXCEPTION
                   WHEN OTHERS THEN
                   OUTPUT_LOG(s_proc_name, ERROR,'Creating local database link ' || s_db_link_name || ' on database  ' || p_DATABASE_NAME || ' - ' || SQLERRM );
                   OUTPUT_LOG(s_proc_name, ERROR,  'The statement that failed was : create database link ' || s_db_link_name || '  connect to ' || p_USERID || ' identified by  xxxxx  using ''' || s_remote_connect_string || '''' );
                   REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,   p_notification_list => 'ADMIN',  p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  => 'Creating local database link ' || s_db_link_name || ' - '  || SQLERRM  );
        END;
        -- finally update the DBHC version for the remote
        s_sql_text := 'UPDATE DBHC_DATABASES  SET DBHC_VERSION = :1 WHERE DATABASE_NAME = :2 and DATABASE_ENVIRONMENT = :3';
        OUTPUT_LOG(s_proc_name, DEBUG,  'about to update remote version to ' || global_DBHC_version );
        execute immediate s_sql_text using global_DBHC_version, C1.REMOTE_DATABASE_NAME , global_this_environment ;
        COMMIT;
      END LOOP;


    -- finally update the DBHC version for the MASTER
    s_sql_text := 'UPDATE DBHC_DATABASES  SET DBHC_VERSION = :1 WHERE DATABASE_NAME = :2 and DATABASE_ENVIRONMENT = :3';
    OUTPUT_LOG(s_proc_name, DEBUG,  'about to update master version to ' || global_DBHC_version );
    execute immediate s_sql_text using global_DBHC_version, p_DATABASE_NAME, global_this_environment ;
    COMMIT;
    OUTPUT_LOG(s_proc_name, INFO,  'Finished updating the master ' || p_DATABASE_NAME );
    EXCEPTION
           WHEN OTHERS THEN
           OUTPUT_LOG(s_proc_name, ERROR, 'Other error when deploying to ' || p_DATABASE_NAME || ' - '  || SQLERRM );

    END DEPLOY_DBHC_MASTER;

  ----------------------------------------------------------------------------
  -- DEPLOY_DBHC_HOST
  --
  -- This proc deploys the DBHC to a HOST database. 
  -- It is this proc that is executed by the dbhc_push.pl script.
  -- The reason this proc is execute from unix is because that is where the passwords are kept.
  -- So, when the perl script runs this proc, it has access to all the necessary passwords.
  -- And that is why the passwords are passed into this proc.  The passwords are necessary to create the database
  -- link to the target database.
  -- Note that the database links are temporary, they are removed at the end.
  --
  --

  --  It does a number of things :
  --   * creates the database link and checks it
  --   * checks the account has required privileges
  --   * checks the version of the DBHC at the HOST database
  --   * if the version is lower, then it removes the current configuration
  --   * it then creates the packages and creates and copies the DBHC tables.
  --   * The procedure names and table names are stored in a global variables - V_TABLE_LIST and V_PACKAGE_LIST
  --   
  -- This proc has no dependencies - as long as you pass it the correct credentials, it will deploy the health check to the target 
  -- database.
  ----------------------------------------------------------------------------

    PROCEDURE DEPLOY_DBHC_HOST ( p_USERID VARCHAR2, p_PASSWORD VARCHAR2, p_DATABASE_NAME VARCHAR2)
    AS
      s_db_link_name VARCHAR2(256) := 'DBHC_TO_' || p_DATABASE_NAME;
      s_remote_db_link_name VARCHAR2(1024);
      s_remote_connect_string VARCHAR2(4000);
      s_proc_name VARCHAR2(128) := 'DEPLOY_DBHC_HOST ' || p_DATABASE_NAME ; 
      s_sql_text CLOB;
      s_sql_text2 CLOB;
      s_ddl_text CLOB;
      s_remote_DDL CLOB;
      i_linecount INTEGER;
      i_remote_DBHC_version NUMBER;
      s_connect_string VARCHAR2(4000);
      i_job_queue_processes INTEGER;

      already_exists exception; 
      pragma exception_init( already_exists, -955 );
      does_not_exist exception; 
      pragma exception_init( does_not_exist, -942 );

    BEGIN
    OUTPUT_LOG(s_proc_name, INFO, 'Deploying to ' || p_DATABASE_NAME );
    INITIALISE;
    COMMIT;

    BEGIN
        SELECT DATABASE_CONNECT_STRING into s_connect_string FROM DBHC_DATABASES where DATABASE_NAME = p_DATABASE_NAME AND DATABASE_ENVIRONMENT = global_this_environment;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN                 
               OUTPUT_LOG(s_proc_name, ERROR, 'Unable to locate ' || p_DATABASE_NAME || ' in DBHC_DATABASES');
               REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,  p_notification_list => 'ADMIN',   p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  =>  'Unable to locate ' || p_DATABASE_NAME || ' in DBHC_DATABASES');
               RETURN;
    END;


    -----------------------
    -- First drop  database link, if it exists
    ----------------------
    for C1 in (select db_link from user_db_links where db_link LIKE s_db_link_name || '%' )
      LOOP
      OUTPUT_LOG(s_proc_name, DEBUG, 'Dropping database link ' || C1.db_link);
      s_sql_text := 'DROP database link ' || C1.db_link ;
      execute immediate s_sql_text;
      END LOOP;
    -----------------------
    -- creating database link
    ----------------------
    BEGIN
        OUTPUT_LOG(s_proc_name,DEBUG, 'Creating database link ' || s_db_link_name);
        s_sql_text := 'create database link ' || s_db_link_name || '  connect to ' || p_USERID || ' identified by  "' || p_PASSWORD || '" using ''' || s_connect_string || '''';
        OUTPUT_LOG(s_proc_name, DEBUG,'db link  sql text : create database link ' || s_db_link_name || '  connect to ' || p_USERID || ' identified by  xxxxx  using ''' || s_connect_string || '''' );
        execute immediate s_sql_text;
    EXCEPTION
                   WHEN OTHERS THEN
                   OUTPUT_LOG(s_proc_name, ERROR, 'Creating database link ' || s_db_link_name || ' - ' || SQLCODE || ' - ' || SQLERRM );
                   REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,   p_notification_list => 'ADMIN',  p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  => 'Creating database link ' || s_db_link_name ||  ' - ' || SQLERRM  );
                   RETURN;
    END;

    -- determine the actual database link name
    SELECT DB_LINK into s_db_link_name FROM USER_DB_LINKS WHERE DB_LINK LIKE s_db_link_name || '%';
    OUTPUT_LOG(s_proc_name,INFO, 'The created database link name is : ' || s_db_link_name);


    s_remote_DDL  := 'BEGIN
                     dbms_utility.EXEC_DDL_STATEMENT@' || s_db_link_name || '( :1 ) ;  
                     END;';


    -----------------------
    -- Check that the database link works
    ----------------------
    BEGIN
        OUTPUT_LOG(s_proc_name, DEBUG, 'Testing database link ' || s_db_link_name);
        s_sql_text := 'SELECT COUNT(*) FROM USER_TABLES@' || s_db_link_name  ;
        execute immediate s_sql_text;
    EXCEPTION
                   WHEN OTHERS THEN
                   OUTPUT_LOG(s_proc_name, ERROR, 'Error with database link ' || s_db_link_name || ' - ' || SQLERRM );
                  OUTPUT_LOG(s_proc_name, ERROR, 'Dropping database link ' || s_db_link_name);
                  s_sql_text := 'DROP database link ' || s_db_link_name ;
                  execute immediate s_sql_text;
                   REGISTER_ALERT( p_check_no => -1, p_check_description => 'DEPLOY_DBHC ' || p_DATABASE_NAME ,  p_notification_list => 'ADMIN', p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  =>  'Error with database link ' || s_db_link_name ||  ' - ' || SQLERRM );
                   RETURN;
    END;
    -----------------------
    -- First check the privs
    ----------------------

    IF ( CHECK_PRIVS( s_db_link_name ) = 0 )
      THEN
      OUTPUT_LOG(s_proc_name, ERROR, p_DATABASE_NAME || ' lacks the correct privileges');
      REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,   p_notification_list => 'ADMIN', p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  => p_DATABASE_NAME || ' lacks the correct privileges');
      OUTPUT_LOG(s_proc_name,DEBUG , 'Dropping database link ' || s_db_link_name);
      s_sql_text := 'DROP database link ' || s_db_link_name ;
      execute immediate s_sql_text;
      RETURN;
      END IF;

    -----------------------
    -- also check that job_queue_processes is not set to 0
    ----------------------
    s_sql_text := 'SELECT value FROM v$parameter@' || s_db_link_name  || '     WHERE NAME =  ''job_queue_processes''   ';
    execute immediate s_sql_text INTO i_job_queue_processes;
    IF ( i_job_queue_processes = 0)
      THEN
      REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,  p_notification_list => 'ADMIN', p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  => p_DATABASE_NAME || ' job_queue_processes is 0');
    END IF;


    -----------------------
    -- first archive any old partition data on the remote HOST database
    -- This copies any old partitions to the MASTER, before dropping them.
    ----------------------
    ARCHIVE_HOST_PARTITIONS(  s_db_link_name );


    -----------------------
    -- find the DBHC version at the other end
    ----------------------
    i_remote_DBHC_version := 0;
    s_sql_text := 'select DBHC_VERSION FROM DBHC_DATABASES  WHERE DATABASE_NAME = :1 ' ;
    BEGIN
         execute immediate s_sql_text into i_remote_DBHC_version using p_DATABASE_NAME ;
    EXCEPTION
                   WHEN  OTHERS THEN
                      OUTPUT_LOG(s_proc_name, ERROR, 'Problem in DBHC_DATABASES where database name is : ' || p_DATABASE_NAME || ' - ' || SQLERRM );
    END;
    OUTPUT_LOG(s_proc_name, DEBUG,'Remote version for ' || p_DATABASE_NAME || ' is  ' || i_remote_DBHC_version);
    OUTPUT_LOG(s_proc_name, DEBUG, 'Central version for ' || p_DATABASE_NAME || ' is  ' || global_DBHC_version);

    if ( i_remote_DBHC_version >= global_DBHC_version ) 
      THEN
      OUTPUT_LOG(s_proc_name, INFO,'Remote version is fine.  Ending.');
      OUTPUT_LOG(s_proc_name, DEBUG, 'Dropping database link ' || s_db_link_name);
      s_sql_text := 'Drop database link ' || s_db_link_name ;
      execute immediate s_sql_text;
      RETURN;
    END IF;

    --  if ( i_remote_DBHC_version is null OR i_remote_DBHC_version < global_DBHC_version ) 

    -- The remote version is out of date, tear it down and start again
    OUTPUT_LOG(s_proc_name,  INFO,'Remote version for ' || p_DATABASE_NAME || '   ' || i_remote_DBHC_version || ' is less than the latest : ' || global_DBHC_version );
    OUTPUT_LOG(s_proc_name, INFO,'Reinstalling DBHC install on ' || p_DATABASE_NAME );

     --------------------------------------
    -- start by dropping any existing checks
    ----------------------------------------
    OUTPUT_LOG(s_proc_name, INFO,'Dropping checks on ' || p_DATABASE_NAME );
    BEGIN
       s_sql_text  :=  'BEGIN
                       DBHC_PKG.DISABLE_CHECKS@' || s_db_link_name || ';
                       DBHC_PKG.DROP_CHECKS@' || s_db_link_name || ';
                       END;';
      EXECUTE IMMEDIATE s_sql_text;
    EXCEPTION
       WHEN OTHERS THEN
          OUTPUT_LOG(s_proc_name, DEBUG, 'The DBHC_PKG does not appear to be in ' || p_DATABASE_NAME );
    END;
    --------------------------------------
    --  Backup the ALERT and OUTPUT_LOG tables to the MASTER
    -- By running this with p_max_age_days => 0, you effectively backup and remote ALL partitions on the HOST
    -- this needs to be done, cause we are about to drop those tables
    ----------------------------------------
    OUTPUT_LOG(s_proc_name, INFO,'Backing up alert and log tables on ' || p_DATABASE_NAME );
    ARCHIVE_HOST_PARTITIONS( p_db_link_name => s_db_link_name,  p_max_age_days => 0);


    --------------------------------------
    --  Now drop everything - this invokes a proc on the target that drops any existing tables and checks
    ----------------------------------------
   OUTPUT_LOG(s_proc_name,INFO, 'Dropping everything on ' || p_DATABASE_NAME );
    BEGIN
       s_sql_text  :=  'BEGIN
                       DBHC_PKG.DROP_EVERYTHING@' || s_db_link_name || ';
                       END;';
      EXECUTE IMMEDIATE s_sql_text;
    EXCEPTION
       WHEN OTHERS THEN
          OUTPUT_LOG(s_proc_name, ERROR,'Error running DROP_EVERYTHING. Possibly the DBHC_PKG does not exist on  ' || p_DATABASE_NAME );
    END;


    --------------------------------------
    --  Now DROP the target tables 
    ----------------------------------------
    for i in 1..V_TABLE_LIST.count
      LOOP
      OUTPUT_LOG(s_proc_name,INFO, 'Dropping ' || V_TABLE_LIST(i)  );

      s_sql_text  :=  'drop table ' || V_TABLE_LIST(i) ;
      BEGIN
        EXECUTE IMMEDIATE  s_remote_DDL using s_sql_text ;
      EXCEPTION
         WHEN OTHERS THEN
            OUTPUT_LOG(s_proc_name,DEBUG, 'The table ' ||V_TABLE_LIST(i) || '  does not appear to be in ' || p_DATABASE_NAME );
      END;

      END LOOP;


    --------------------------------------
    --  Now DROP the target procedures
    ----------------------------------------
    for i in 1..V_PACKAGE_LIST.count
      LOOP
      OUTPUT_LOG(s_proc_name, INFO, 'Dropping package ' || V_PACKAGE_LIST(i) );
      s_sql_text  := 'DROP PACKAGE ' || V_PACKAGE_LIST(i) ;
      BEGIN
        EXECUTE IMMEDIATE  s_remote_DDL using s_sql_text ;
      EXCEPTION
         WHEN OTHERS THEN
            OUTPUT_LOG(s_proc_name,DEBUG,'The package ' ||V_PACKAGE_LIST(i) || '  does not appear to be in ' || p_DATABASE_NAME );
      END;
      END LOOP;

    BEGIN
        s_sql_text  := 'DROP PROCEDURE TEMP_PROC ' ;
        EXECUTE IMMEDIATE  s_remote_DDL using s_sql_text ;
      EXCEPTION
         WHEN OTHERS THEN
            OUTPUT_LOG(s_proc_name,DEBUG,'The TEMP_PROC does not exist either');
      END;



    dbms_metadata.set_transform_param (dbms_metadata.session_transform,'STORAGE',false);
    dbms_metadata.set_transform_param (dbms_metadata.session_transform,'TABLESPACE',false);
    dbms_metadata.set_transform_param (dbms_metadata.session_transform,'SEGMENT_ATTRIBUTES', false);
    dbms_metadata.set_transform_param (dbms_metadata.session_transform,'REF_CONSTRAINTS', false);
    dbms_metadata.set_transform_param (dbms_metadata.session_transform,'CONSTRAINTS', false);
    dbms_metadata.set_transform_param (dbms_metadata.session_transform,'PARTITIONING', TRUE);


    --------------------------------------
    --  Now create the target tables 
    ----------------------------------------

    for i in 1..V_TABLE_LIST.count
      LOOP
      OUTPUT_LOG(s_proc_name, INFO,'Deploying ' || V_TABLE_LIST(i) || ' to ' || p_DATABASE_NAME );

      s_sql_text  := dbms_metadata.get_ddl(  object_type => 'TABLE', name => V_TABLE_LIST(i) ,schema => global_schema_name );
      s_sql_text := replace(s_sql_text, '"' , NULL ); 
      s_sql_text := replace(s_sql_text, ';' , NULL ); 
      s_sql_text := replace(s_sql_text, 'CREATE TABLE ' || global_schema_name, 'CREATE TABLE ' || p_USERID); 
      select regexp_count(s_sql_text, chr (10)) into i_linecount from dual;
      OUTPUT_LOG(s_proc_name,DEBUG, 'The number of lines is ' || i_linecount);
      OUTPUT_LOG(s_proc_name, DEBUG, '>> ' || s_sql_text);

      s_ddl_text := q'#
                      DECLARE
                          remote_cursor_id INTEGER;
                          i_fetches INTEGER;
                      BEGIN
                        remote_cursor_id := DBMS_SQL.OPEN_CURSOR@DBLINK;
                        DBMS_SQL.PARSE@DBLINK(remote_cursor_id, 'alter session set db_securefile=PERMITTED', DBMS_SQL.native); 
                        i_fetches := DBMS_SQL.EXECUTE@DBLINK(remote_cursor_id);
                        DBMS_SQL.CLOSE_CURSOR@DBLINK(remote_cursor_id);
                        dbms_utility.EXEC_DDL_STATEMENT@DBLINK( :1 ) ;  
                     END;      #';

      s_ddl_text := replace(s_ddl_text, 'DBLINK' , s_db_link_name ); 
      OUTPUT_LOG(s_proc_name, DEBUG, '>> ' || s_ddl_text);
      EXECUTE IMMEDIATE s_ddl_text using s_sql_text ;


      -- INSERT into non partitioned table
      FOR C1 IN  ( SELECT 1 FROM USER_TABLES WHERE TABLE_NAME = V_TABLE_LIST(i) AND PARTITIONED = 'NO' )
          LOOP
          s_ddl_text := 'INSERT INTO  '|| V_TABLE_LIST(i) || '@' || s_db_link_name || '  SELECT * FROM ' ||  V_TABLE_LIST(i) ;
          EXECUTE IMMEDIATE s_ddl_text;
          END LOOP;

      END LOOP;

    --------------------------------------
    --  Now create the target views 
    ----------------------------------------
    for i in 1..V_VIEW_LIST.count
      LOOP
      OUTPUT_LOG(s_proc_name, INFO,'Creating view ' || V_TABLE_LIST(i) || ' on ' || p_DATABASE_NAME );

      s_sql_text  := dbms_metadata.get_ddl(  object_type => 'VIEW', name => V_VIEW_LIST(i) ,schema => global_schema_name );
      s_sql_text := replace(s_sql_text, '"' , NULL ); 
      s_sql_text := replace(s_sql_text, ';' , NULL ); 
      s_sql_text := replace(s_sql_text, ' CREATE OR REPLACE FORCE VIEW ' || global_schema_name, ' CREATE OR REPLACE FORCE VIEW ' || p_USERID); 
      select regexp_count(s_sql_text, chr (10)) into i_linecount from dual;
      OUTPUT_LOG(s_proc_name,DEBUG, 'The number of lines is ' || i_linecount);
      OUTPUT_LOG(s_proc_name, DEBUG, '>> ' || s_sql_text);
      s_ddl_text := 'BEGIN
                     dbms_utility.EXEC_DDL_STATEMENT@' || s_db_link_name || '( :1 ) ;  
                     END;';
      EXECUTE IMMEDIATE s_ddl_text using s_sql_text ;
      END LOOP;
    --------------------------------------
    --  Now create the target packages
    ----------------------------------------
    for i in 1..V_PACKAGE_LIST.count
      LOOP


        BEGIN
          OUTPUT_LOG(s_proc_name, INFO, 'Deploying the package spec ' || V_PACKAGE_LIST(i) || ' to ' || p_DATABASE_NAME );
          s_sql_text  := dbms_metadata.get_ddl(  object_type => 'PACKAGE_SPEC', name => V_PACKAGE_LIST(i) , schema => global_schema_name );
          IF ( substr(s_sql_text, length(s_sql_text ) ) = '/' ) 
              THEN
               -- removes the slash at the end
                s_sql_text := substr(s_sql_text, 1, length(s_sql_text)-1);  
          END IF;
          select regexp_count(s_sql_text, chr (10)) into i_linecount from dual;
          OUTPUT_LOG(s_proc_name, DEBUG, 'The number of lines is ' || i_linecount);
          OUTPUT_LOG(s_proc_name, DEBUG, '>> ' || s_sql_text );
          EXECUTE IMMEDIATE s_remote_DDL using s_sql_text ;
          OUTPUT_LOG(s_proc_name,INFO, 'Deploying the package body ' || V_PACKAGE_LIST(i) || ' to ' || p_DATABASE_NAME );
          s_sql_text  := dbms_metadata.get_ddl(  object_type => 'PACKAGE_BODY', name => V_PACKAGE_LIST(i) , schema => global_schema_name );
          IF ( substr(s_sql_text, length(s_sql_text ) ) = '/' ) 
              THEN
               -- removes the slash at the end
                s_sql_text := substr(s_sql_text, 1, length(s_sql_text)-1);  
          END IF;
          select length(s_sql_text) into i_linecount from dual;
          OUTPUT_LOG(s_proc_name, DEBUG, 'The number of characters is ' || i_linecount);
          OUTPUT_LOG(s_proc_name, DEBUG, s_sql_text );
          EXECUTE_REMOTE_CLOB( s_sql_text, s_db_link_name, V_PACKAGE_LIST(i)  ) ;
        EXCEPTION
              when OTHERS THEN
                   OUTPUT_LOG(s_proc_name, ERROR, 'Error when compiling packages to  ' || s_db_link_name || ' : ORA' || SQLCODE || ' - '|| SQLERRM );
                   REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,  p_notification_list => 'ADMIN', p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  =>   'Error when compiling packages to  ' || s_db_link_name || ' : ORA' || SQLCODE || ' - ' || SQLERRM );
                   OUTPUT_LOG(s_proc_name, DEBUG, 'Dropping database link ' || s_db_link_name);
                   s_sql_text := 'Drop database link ' || s_db_link_name ;
                   execute immediate s_sql_text;
                   RETURN;
        END;

      END LOOP;

    --------------------------------------
    --  Now create the target checks
    ----------------------------------------
    OUTPUT_LOG(s_proc_name, INFO, 'Creating the checks');

    BEGIN
       s_sql_text  :=  'BEGIN
                       DBHC_PKG.DROP_CHECKS@' || s_db_link_name || ';
                       END;';
      EXECUTE IMMEDIATE s_sql_text;
      s_sql_text  :=  'BEGIN
                       DBHC_PKG.CREATE_CHECKS@' || s_db_link_name  || ';
                        END;';
      EXECUTE IMMEDIATE s_sql_text;
    EXCEPTION
       WHEN OTHERS THEN
           OUTPUT_LOG(s_proc_name,ERROR,  'Other error when creating the checks on  ' || p_DATABASE_NAME || ' : ORA-'|| SQLCODE || ' - ' || SQLERRM );
           REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,  p_notification_list => 'ADMIN', p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  =>  'Other error when creating the checks on  ' || p_DATABASE_NAME || ' : ORA-'|| SQLCODE || ' - ' || SQLERRM );
    END;

    --------------------------------------
    --  Now create any database links which are needed for remote checks
    ----------------------------------------
    FOR C1 IN ( SELECT  REMOTE_DATABASE_NAME 
               FROM DBHC_DATABASES
               WHERE DATABASE_NAME = p_DATABASE_NAME
               AND REMOTE_DATABASE_NAME IS NOT NULL)
      LOOP
        OUTPUT_LOG(s_proc_name, INFO, 'Creating database link on ' || p_DATABASE_NAME || ' for target database ' || C1.REMOTE_DATABASE_NAME );
        s_remote_db_link_name := 'DBHC_TO_' || C1.REMOTE_DATABASE_NAME;
        BEGIN
                OUTPUT_LOG(s_proc_name, DEBUG, 'Start by dropping any existing link with name ' || s_remote_db_link_name );
                s_sql_text := 'DROP DATABASE LINK ' || s_remote_db_link_name ;
                EXECUTE IMMEDIATE s_remote_DDL USING s_sql_text;
        EXCEPTION
                   WHEN OTHERS THEN
                   OUTPUT_LOG(s_proc_name, ERROR, 'Error when dropping ' || s_remote_db_link_name || ' possibly it did not exist ');
        END;
        BEGIN 
              SELECT DATABASE_CONNECT_STRING INTO s_remote_connect_string FROM DBHC_DATABASES WHERE DATABASE_NAME = C1.REMOTE_DATABASE_NAME  ;
              OUTPUT_LOG(s_proc_name, DEBUG, 'About to create remote db link with sql text : create database link ' || s_remote_db_link_name || '  connect to ' || p_USERID || ' identified by  xxxxx  using ''' || s_remote_connect_string || '''' );
              s_sql_text := 'create database link ' || s_remote_db_link_name || '  connect to ' || p_USERID || ' identified by  "' || p_PASSWORD || '" using ''' || s_remote_connect_string || '''';
              EXECUTE IMMEDIATE s_remote_DDL USING s_sql_text;
        EXCEPTION
                   WHEN OTHERS THEN
                   OUTPUT_LOG(s_proc_name,ERROR,  'Creating remote database link ' || s_remote_db_link_name || ' on target database  ' || p_DATABASE_NAME || ' - ' || SQLERRM );
                   REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,   p_notification_list => 'ADMIN',  p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  => 'Creating remote database link ' || s_remote_db_link_name || ' - '  || SQLERRM  );
        END;
      END LOOP;


    ---      finally update the dbhc version, on the remote target database :
    OUTPUT_LOG(s_proc_name, INFO, 'Updating the DBHC_VERSION');
    s_sql_text := 'UPDATE DBHC_DATABASES@' || s_db_link_name || '  SET DBHC_VERSION = :1 WHERE DATABASE_NAME = :2 and DATABASE_ENVIRONMENT = :3';
    execute immediate s_sql_text using global_DBHC_version, p_DATABASE_NAME, global_this_environment ;
    -- and also locally :
    s_sql_text := 'UPDATE DBHC_DATABASES  SET DBHC_VERSION = :1 WHERE DATABASE_NAME = :2 and DATABASE_ENVIRONMENT = :3';
    execute immediate s_sql_text using global_DBHC_version, p_DATABASE_NAME, global_this_environment ;
    COMMIT;

    OUTPUT_LOG(s_proc_name, INFO, 'Finishing deploy to ' || p_DATABASE_NAME );
    OUTPUT_LOG(s_proc_name, DEBUG, 'Dropping database link ' || s_db_link_name);
    s_sql_text := 'Drop database link ' || s_db_link_name ;
    execute immediate s_sql_text;
    OUTPUT_LOG(s_proc_name, DEBUG, 'Exiting' );



    EXCEPTION 
                   WHEN  OTHERS THEN
                   OUTPUT_LOG(s_proc_name, ERROR, 'Other error from DEPLOY_DBHC to  ' || p_DATABASE_NAME || ' : ORA-'|| SQLCODE || ' - ' || SQLERRM );
                   REGISTER_ALERT( p_check_no => -1, p_check_description => s_proc_name ,  p_notification_list => 'ADMIN',  p_check_exec_time => SYSTIMESTAMP ,   p_check_elapsed_time  => 1 ,	c_check_output  => 'Other error from DEPLOY_DBHC to  ' || p_DATABASE_NAME || ' : ORA-'|| SQLCODE || ' - ' || SQLERRM );
                   OUTPUT_LOG(s_proc_name, DEBUG, 'Dropping database link ' || s_db_link_name);
                   s_sql_text := 'Drop database link ' || s_db_link_name ;
                   execute immediate s_sql_text;
    END DEPLOY_DBHC_HOST;

  /*
  --------------------------------------------------------------------------------------
  -- EXECUTE_PLSQL - WITH REMOTE OPTION OLD VERSION
  --------------------------------------------------------------------------------------

  PROCEDURE EXECUTE_PLSQL( s_sql_text IN VARCHAR2, s_bind_variables IN VARCHAR2, s_remote_db_name IN VARCHAR2, c_sql_output OUT CLOB, i_fetches OUT INTEGER )
  AS
    s_proc_name VARCHAR2(128) := 'EXECUTE_PLSQL (remote)' ;  
    local_cursor_id INTEGER;
     lines DBMS_OUTPUT.CHARARR;
     numlines INTEGER := 2000;
    s_db_link_name VARCHAR2(1024) := 'DBHC_'|| s_remote_db_name || '.WORLD';
    i_Count INTEGER := 0;
    s_local_text VARCHAR2(4000);
    s_remote_text VARCHAR2(4000);
  BEGIN

    -- first check that the db link is there :
    SELECT COUNT(*) into i_Count FROM USER_DB_LINKS WHERE db_link = s_db_link_name;
    IF (i_Count = 0 and s_remote_db_name is not null)  
      THEN 
      OUTPUT_LOG(s_proc_name, 'Remote database is ' || s_remote_db_name || ' but there is no database link with name  ' || s_db_link_name );
      RETURN;
      END IF;

    s_remote_text := q'#DECLARE
                       remote_cursor_id INTEGER;
                       i_fetches INTEGER;
                       x varchar2(2000);
                       status intEGER;
                     BEGIN
                       dbms_output.enable@DBLINK;
                       remote_cursor_id := DBMS_SQL.OPEN_CURSOR@DBLINK;  
                       DBMS_SQL.PARSE@DBLINK(remote_cursor_id, :1, DBMS_SQL.native); 
                       FOR FOO IN (    SELECT REGEXP_SUBSTR (:2,  '[^,]+',  1,   LEVEL)   TXT, LEVEL    FROM DUAL
                                     CONNECT BY REGEXP_SUBSTR (:2,   '[^,]+',  1,   LEVEL)      IS NOT NULL)
                         LOOP
                             IF ( FOO.TXT IS NOT NULL ) THEN
                           -- dbms_output.put_line( 'Identified bind variable : ' ||  FOO.LEVEL ||' - ' || FOO.TXT );
                             DBMS_SQL.BIND_VARIABLE@DBLINK( remote_cursor_id,   ':' || FOO.LEVEL, FOO.TXT);
                             END IF;
                         END LOOP;
                        i_fetches := DBMS_SQL.EXECUTE@DBLINK(remote_cursor_id);
                        DBMS_SQL.CLOSE_CURSOR@DBLINK(remote_cursor_id);
                        LOOP
                              dbms_output.get_line@DBLINK( x,status);
                              exit when status != 0;
                             dbms_output.put_line(x);
                        END LOOP;
                       END;
                       #';
      IF ( s_remote_db_name is not NULL)
        THEN
        SELECT REPLACE ( s_remote_text, 'DBLINK',  s_db_link_name ) INTO s_remote_text FROM DUAL;
      ELSE 
        SELECT REPLACE( s_remote_text, '@DBLINK',  NULL)  INTO s_remote_text FROM DUAL;
      END IF;
      OUTPUT_LOG(s_proc_name, s_remote_text  );
      --OUTPUT_LOG(s_proc_name, s_sql_text  );

    BEGIN
      execute immediate s_remote_text using s_sql_text , s_bind_variables;
    EXCEPTION 
                   WHEN OTHERS THEN
                   OUTPUT_LOG(s_proc_name, 'Running anonymous block failed '  || SQLERRM );
                   RETURN;
    END;

    -- Now extract the DBMS_OUTPUT output
    DBMS_OUTPUT.GET_LINES( lines, numlines );
    --dbms_output.put_line('lines is ' || numlines);
    FOR i IN 1..numlines 
      LOOP
      c_sql_output := c_sql_output || lines(i) || chr(13);
      END LOOP; 


    i_fetches := numlines;

    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, 'Other error ' || SQLERRM ); 

  END EXECUTE_PLSQL;
  */

  --------------------------------------------------------------------------------------
  -- EXECUTE_PLSQL_REMOTE 
  --
  -- This proc runs a piece of PL/SQL, on a remote database
  --
  -- The results are passed back via the OUT parameters - c_sql_output and i_fetches
  --------------------------------------------------------------------------------------

  PROCEDURE EXECUTE_PLSQL_REMOTE( c_sql_text IN CLOB, p_bind_variables IN VARCHAR2, p_identifier IN VARCHAR2 DEFAULT NULL, p_remote_db_name IN VARCHAR2, c_sql_output OUT CLOB, i_fetches OUT INTEGER )
  AS
  -- PRAGMA AUTONOMOUS_TRANSACTION;
    s_proc_name VARCHAR2(128) := 'EXECUTE_PLSQL_REMOTE ' || p_identifier ;  
                       x varchar2(2000);
                       status intEGER;
    s_db_link_name VARCHAR2(1024) := 'DBHC_TO_'|| p_remote_db_name || '.WORLD';
    i_Count INTEGER := 0;
     lines DBMS_OUTPUT.CHARARR;
     numlines INTEGER := 2000;
    s_remote_text VARCHAR2(4000)  ;
  BEGIN

     OUTPUT_LOG(s_proc_name, DEBUG, 'Starting' );

    -- first check that the db link is there :
    SELECT COUNT(*) into i_Count FROM USER_DB_LINKS WHERE db_link = s_db_link_name;
    IF (i_Count = 0 and p_remote_db_name is not null)  
      THEN 
      OUTPUT_LOG(s_proc_name,ERROR, 'Remote database is ' || p_remote_db_name || ' but there is no database link with name  ' || s_db_link_name );
      RAISE_APPLICATION_ERROR( exc_EXECUTE_PLSQL_REMOTE, 'Remote database is ' || p_remote_db_name || ' but there is no database link with name  ' || s_db_link_name );
      ROLLBACK;
      RETURN;
      END IF;

      -- CHECK SIZE OF c_sql_text 
    IF ( DBMS_LOB.GETLENGTH( c_sql_text ) > 32767) 
      THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'This SQL text is too long for the remote wrapper proc to handle : ' || c_sql_text  );  
           RAISE_APPLICATION_ERROR( exc_EXECUTE_PLSQL_REMOTE, 'This SQL text is too long for the remote wrapper proc to handle ');
        -- ROLLBACK;
         RETURN;
      END IF;

    s_remote_text := 'BEGIN    
                      DBMS_OUTPUT.ENABLE@' || s_db_link_name || '  ;  
                      END;  ';
    EXECUTE IMMEDIATE s_remote_text;

    s_remote_text    := 'BEGIN    
                         DBHC_PKG.EXECUTE_PLSQL_REMOTE_WRAPPER@' || s_db_link_name || q'#( s_sql_text => :1, s_bind_variables => :2, s_sql_output => :3 , i_fetches => :4 )  ;  
                         EXCEPTION
                             WHEN OTHERS THEN
                             DBHC_PKG.OUTPUT_LOG('#' || s_proc_name || q'#' , DBHC_PKG.DEBUG,  SQLERRM );
                         END;  #';
   -- commit;
    EXECUTE IMMEDIATE s_remote_text using IN c_sql_text, IN p_bind_variables,  OUT c_sql_output, OUT i_fetches ;

    /*
    -- Now extract the DBMS_OUTPUT output
    DBMS_OUTPUT.GET_LINES( lines, numlines );
    --dbms_output.put_line('lines is ' || numlines);
    FOR i IN 1..numlines 
      LOOP
      c_sql_output := c_sql_output || lines(i) || chr(13);
      END LOOP;

    i_fetches := numlines;
   */
      OUTPUT_LOG(s_proc_name, DEBUG, 'The final PLSQL output is : ' || c_sql_output );
  EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error ' || SQLERRM ); 
         OUTPUT_LOG(s_proc_name, DEBUG, 'Error stack  : ' || DBMS_UTILITY.FORMAT_ERROR_STACK  ); 
         OUTPUT_LOG(s_proc_name, DEBUG, 'This SQL text that failed is : ' || c_sql_text  ); 
       --  ROLLBACK; 
         RAISE;


  END EXECUTE_PLSQL_REMOTE;


    --------------------------------------------------------------------------------------
  -- EXECUTE_PLSQL_REMOTE_WAPPER
  --
  -- This is the proc that is executed remotely. 
  -- It is usually execute on an Active Dataguard Standby, but it does not have to be
  --  This proc returns the variable c_sql_output
  -- as a VARCHAR2, as you cannot execute a remote proc with a CLOB.  So this wrapper works around that limitation
  --
  --------------------------------------------------------------------------------------

  PROCEDURE EXECUTE_PLSQL_REMOTE_WRAPPER( s_sql_text IN VARCHAR2, s_bind_variables IN VARCHAR2, s_sql_output OUT VARCHAR2, i_fetches OUT INTEGER )
  AS
  --  PRAGMA AUTONOMOUS_TRANSACTION;
    s_proc_name VARCHAR2(128) := 'EXECUTE_PLSQL_REMOTE_WRAPPER' ;   
    s_local_text VARCHAR2(4000)  := 'BEGIN    
                                     DBHC_PKG.EXECUTE_PLSQL( :1 , :2, :3, :4, :5 )  ;  
                                     END;  ';
    c_return_clob CLOB;
    i_Count INTEGER := 0;
     lines DBMS_OUTPUT.CHARARR;
     numlines INTEGER := 2000;

  BEGIN

     OUTPUT_LOG(s_proc_name, DEBUG, 'Starting' );

   -- DBMS_OUTPUT.ENABLE( buffer_size => NULL);
    EXECUTE IMMEDIATE s_local_text using IN s_sql_text, IN s_bind_variables, IN s_proc_name,   OUT c_return_clob, OUT i_fetches ;

        -- prepare the return sql text, by truncating the clob
    s_sql_output := DBMS_LOB.SUBSTR( c_return_clob, 32700, 1);

    IF (DBMS_LOB.GETLENGTH(c_return_clob ) > 32700 )
      THEN
        OUTPUT_LOG(s_proc_name,INFO,  'The SQL output is over 32700 ' );
        s_sql_output :=  s_sql_output || chr(13) || chr(10) || 'Rows Truncated';
    END IF; 

   /*
    -- Now extract the DBMS_OUTPUT output
    DBMS_OUTPUT.GET_LINES( lines, numlines );
    --dbms_output.put_line('lines is ' || numlines);
    FOR i IN 1..numlines 
      LOOP
      s_sql_output := s_sql_output || lines(i) || chr(13) || chr(10);
      END LOOP;

    i_fetches := numlines;
   */
      OUTPUT_LOG(s_proc_name, DEBUG, 'The PLSQL output is : ' || c_return_clob );
      OUTPUT_LOG(s_proc_name, DEBUG,'returned i_fetches is : ' || i_fetches );
      OUTPUT_LOG(s_proc_name, DEBUG, 'The final PLSQL output is : ' || s_sql_output );
    --  ROLLBACK;
    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error ' || SQLERRM ); 
       --  ROLLBACK;
         RAISE;


  END EXECUTE_PLSQL_REMOTE_WRAPPER;


  --------------------------------------------------------------------------------------
  -- EXECUTE_PLSQL - EXECUTE LOCALLY
  --
  -- Executes a PL/SQL block on this database (ie locally)
  --
  -- The results are passed back via the OUT parameters - c_sql_output and i_fetches
  --------------------------------------------------------------------------------------

  PROCEDURE EXECUTE_PLSQL( c_sql_text IN CLOB, p_bind_variables IN VARCHAR2, p_identifier IN VARCHAR2 DEFAULT NULL,  c_sql_output OUT CLOB, i_fetches OUT INTEGER )
  AS
    s_proc_name VARCHAR2(128) := 'EXECUTE_PLSQL ' || p_identifier ;  
    local_cursor_id INTEGER;
     lines DBMS_OUTPUT.CHARARR;
     numlines INTEGER := 2000;
    V_BIND_LIST tableRecords;
  BEGIN
    OUTPUT_LOG(s_proc_name, DEBUG, 'Starting with PLSQL :' || c_sql_text  ); 
    OUTPUT_LOG(s_proc_name, DEBUG, 'Starting bind variables :' || p_bind_variables  ); 
    DBMS_OUTPUT.ENABLE(buffer_size => NULL);

      BEGIN
                        local_cursor_id := DBMS_SQL.OPEN_CURSOR;  
                        DBMS_SQL.PARSE (local_cursor_id, c_sql_text, DBMS_SQL.native); 
                        -- the BIND_VARIABLE parameter is a comma separated list. 
                        -- convert the bind parameter string to nested table 
                        POPULATE_CSV_ARRAY(s_csv_string => p_bind_variables , t_csv_table => V_BIND_LIST );
                        -- now iterate throught the list and apply each bind variable
                        FOR i IN 1..V_BIND_LIST.COUNT
                          LOOP
                             OUTPUT_LOG(s_proc_name, DEBUG, 'Identified bind variable :' ||  i ||' - ' || V_BIND_LIST(i) );
                             DBMS_SQL.BIND_VARIABLE(local_cursor_id,   ':' || i , V_BIND_LIST(i));
                          END LOOP;
                        -- binds loaded, now execute
                        i_fetches := DBMS_SQL.EXECUTE(local_cursor_id);
      EXCEPTION 
                   WHEN OTHERS THEN
                   OUTPUT_LOG(s_proc_name,ERROR, 'Running anonymous block failed '  || SQLERRM );
                   OUTPUT_LOG(s_proc_name,DEBUG, 'The SQL that failed is :   ' || c_sql_text );
                   DBMS_SQL.CLOSE_CURSOR(local_cursor_id);
                   RAISE;
                   RETURN;
      END;

    -- Now extract the DBMS_OUTPUT output
    DBMS_OUTPUT.GET_LINES( lines, numlines );
    --dbms_output.put_line('lines is ' || numlines);
    FOR i IN 1..numlines 
      LOOP
      c_sql_output := c_sql_output || lines(i) || chr(13) || chr(10);
      END LOOP;
    DBMS_SQL.CLOSE_CURSOR(local_cursor_id); 
    i_fetches := numlines;

    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error ' || SQLERRM ); 
         OUTPUT_LOG(s_proc_name, DEBUG, 'The SQL that failed is :   ' || c_sql_text );
         IF (DBMS_SQL.IS_OPEN( local_cursor_id ) )
            THEN
            DBMS_SQL.CLOSE_CURSOR(local_cursor_id);
            END IF;
         RAISE;

  END EXECUTE_PLSQL;


  --------------------------------------------------------------------------------------
  -- EXECUTE_SQL_REMOTE 
  --
  -- This proc runs a piece of SQL, on a remote database
  --
  -- The results are passed back via the OUT parameters - c_sql_output and i_fetches
  --------------------------------------------------------------------------------------

  PROCEDURE EXECUTE_SQL_REMOTE( c_sql_text IN CLOB, p_bind_variables IN VARCHAR2, p_remote_db_name IN VARCHAR2, p_identifier IN VARCHAR2,  c_sql_output OUT CLOB, i_fetches OUT INTEGER )
  AS
   -- PRAGMA AUTONOMOUS_TRANSACTION;
    s_proc_name VARCHAR2(128) := 'EXECUTE_SQL_REMOTE ' || p_identifier ;  
    local_cursor_id INTEGER;
                       x varchar2(2000);
                       status intEGER;
    s_db_link_name VARCHAR2(1024) := 'DBHC_TO_'|| p_remote_db_name || '.WORLD';
    i_Count INTEGER := 0;
    s_local_text VARCHAR2(4000);
    s_remote_text VARCHAR2(32000);

  BEGIN


    -- first check that the db link is there :
    SELECT COUNT(*) into i_Count FROM USER_DB_LINKS WHERE db_link = s_db_link_name;
    IF (i_Count = 0 and p_remote_db_name is not null)  
      THEN 
      OUTPUT_LOG(s_proc_name,ERROR, 'Remote database is ' || p_remote_db_name || ' but there is no database link with name  ' || s_db_link_name );
      ROLLBACK;
      RAISE_APPLICATION_ERROR(exc_EXECUTE_SQL_REMOTE, 'Remote database is ' || p_remote_db_name || ' but there is no database link with name  ' || s_db_link_name );
      RETURN;
      END IF;

    -- CHECK SIZE OF c_sql_text 
    IF ( DBMS_LOB.GETLENGTH( c_sql_text ) > 32767) 
      THEN
         OUTPUT_LOG(s_proc_name, ERROR,  'This SQL text is too long for the remote wrapper proc to handle : ' || c_sql_text  );  
         ROLLBACK;
         RAISE_APPLICATION_ERROR(exc_EXECUTE_SQL_REMOTE, 'This SQL text is too long for the remote wrapper proc to handle ');
         RETURN;
      END IF;

    s_remote_text := 'BEGIN    
                      DBMS_OUTPUT.ENABLE@' || s_db_link_name || '  ;  
                      END;  ';
    EXECUTE IMMEDIATE s_remote_text;

    s_remote_text := q'#BEGIN    
                        DBHC_PKG.EXECUTE_SQL_REMOTE_WRAPPER@#' || s_db_link_name || q'#( s_sql_text => :1 , s_bind_variables => :2,  s_sql_output => :3, i_fetches => :4 )  ;  
                        EXCEPTION
                          WHEN OTHERS THEN
                             DBHC_PKG.OUTPUT_LOG('#' || s_proc_name || q'#' ,DBHC_PKG.DEBUG,  SQLERRM ); 
                      END;  #';

    OUTPUT_LOG(s_proc_name, DEBUG, 'About to execute remote statement : ' || s_remote_text );
 --  commit;

   EXECUTE IMMEDIATE s_remote_text using IN c_sql_text, IN p_bind_variables,  OUT c_sql_output, OUT i_fetches ;


     OUTPUT_LOG(s_proc_name, DEBUG, 'The SQL output is : ' || c_sql_output );
  --   ROLLBACK;
    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name, ERROR, 'Other error ' || SQLERRM ); 
         OUTPUT_LOG(s_proc_name, DEBUG, 'Error stack  : ' || DBMS_UTILITY.FORMAT_ERROR_STACK  ); 
         OUTPUT_LOG(s_proc_name, DEBUG, 'This SQL text that failed is : ' || c_sql_text  ); 
       --  ROLLBACK;
         RAISE;

  END EXECUTE_SQL_REMOTE;



    --------------------------------------------------------------------------------------
  -- EXECUTE_SQL_REMOTE_WRAPPER
  --
  -- This is the proc that is executed remotely.  This proc returns the variable c_sql_output
  -- as a VARCHAR2, as you cannot execute a remote proc with a CLOB.  So this wrapper works around that limitation
  --
  --------------------------------------------------------------------------------------

  PROCEDURE EXECUTE_SQL_REMOTE_WRAPPER( s_sql_text IN VARCHAR2, s_bind_variables IN VARCHAR2,  s_sql_output OUT VARCHAR2, i_fetches OUT INTEGER )
  AS
    -- PRAGMA AUTONOMOUS_TRANSACTION;
    s_proc_name VARCHAR2(128) := 'EXECUTE_SQL_REMOTE_WRAPPER' ;  
    s_local_text VARCHAR2(4000)  := 'BEGIN    
                                     DBHC_PKG.EXECUTE_SQL( :1 , :2, :3, :4, :5 )  ;  
                                     END;  ';
    c_return_clob CLOB;


  BEGIN

    OUTPUT_LOG(s_proc_name, DEBUG, 'Starting' );

    OUTPUT_LOG(s_proc_name, DEBUG,'About to execute the proc locally ' );
    EXECUTE IMMEDIATE s_local_text using IN s_sql_text, IN s_bind_variables, IN s_proc_name,  OUT c_return_clob, OUT i_fetches ;


    -- prepare the return sql text, by truncating the clob
    s_sql_output := DBMS_LOB.SUBSTR( c_return_clob, 32700, 1);

    IF (DBMS_LOB.GETLENGTH(c_return_clob ) > 32700 )
      THEN
        OUTPUT_LOG(s_proc_name, INFO,'The SQL output is over 32700 ' );
        s_sql_output :=  s_sql_output || chr(13) || chr(10) || 'Rows Truncated';
    END IF;  

    OUTPUT_LOG(s_proc_name, DEBUG, 'The SQL output is : ' || s_sql_output );
   -- ROLLBACK;
    EXCEPTION
      WHEN OTHERS THEN
         --OUTPUT_LOG(s_proc_name, ERROR,  'Other error ' || SQLERRM ); 
         DBMS_OUTPUT.PUT_LINE( 'Error stack  : ' || DBMS_UTILITY.FORMAT_ERROR_STACK  ); 
       --  ROLLBACK;
         RAISE;

  END EXECUTE_SQL_REMOTE_WRAPPER;

   --------------------------------------------------------------------------------------
  -- EXECUTE_SQL 
  --
  -- This proc runs a piece of SQL, using DBMS_SQL.
  --
  -- It contains some logic to format the results.  For instance, it checks the width of each column
  -- and ensures that the results are formatted correctly (ie just wide enough to display all values, without wrapping).
  -- 
  -- Limitations :
  -- The DBHC checks are designed to be sent via email, so they're not intended to be large queries
  -- This proc uses a VARRAY to collect and format the results.  The longest output it can accept is 2048.
  -- You could make this larger, as the maximum VARRAY is I think 2 billion, but you obviously dont want send that via email.
  --
  -- The other limitation is the number of columns.  Each row is stored in a TYPE which has one VARCHAR for each column.
  -- This is because we don't know anything about the SQL that it is running, including the number of columns in the output.
  -- But 16 seems a reasonable figure, again because the intention is to send this via email.  You could increase that if you wish.
  --
  -- There is also a limitation on the total number of characters.  This is in the Max_Size_Characters variable
  --
  -- The results are passed back via the OUT parameters - c_sql_output and i_fetches
  --------------------------------------------------------------------------------------

    PROCEDURE EXECUTE_SQL( c_sql_text IN CLOB, p_bind_variables IN VARCHAR2 DEFAULT NULL, p_identifier IN VARCHAR2 DEFAULT NULL,c_sql_output OUT CLOB, i_fetches OUT INTEGER )
    AS
    s_proc_name VARCHAR2(128) := 'EXECUTE_SQL ' || p_identifier  ;
    local_cursor_id INTEGER;

    colVARCHAR2   VARCHAR2 (512);  
    colNUMBER   NUMBER; 
    colDATE    DATE;  
    colCLOB  CLOB; 
    VDescTab DBMS_SQL.desc_tab2;  
    ColumnCount NUMBER;
    DB INTEGER;
    s_converted_value  VARCHAR2(4096);    
    -- a table to hold any bind variable values
    V_BIND_LIST tableRecords;

    string_buffer_too_small exception;
    pragma exception_init( string_buffer_too_small, -6502 );


    --------------------------------------------------------------------------
    -- here are the limitations :

    -- maximum number of columns 
    MaxColumns INTEGER := 16;

    -- maximum number of rows returned by the proc
    MaxRows INTEGER := 10000;
    -- maximum clob size in bytes that the proc will return
    Max_Size_Characters INTEGER := 5E6;

    -- maximum width of any column in bytes
    MaxColumnWidth  INTEGER := 512;

    -- this nested table will hold the output from the query
     TYPE OneRecord IS RECORD (
       column1      varchar2(512),
       column2      varchar2(512),
       column3      varchar2(512),
       column4      varchar2(512),
       column5      varchar2(512),
       column6      varchar2(512),
       column7      varchar2(512),
       column8      varchar2(512),
       column9      varchar2(512),
       column10      varchar2(512),
       column11      varchar2(512),
       column12      varchar2(512),
       column13      varchar2(512),
       column14      varchar2(512),
       column15      varchar2(512),
       column16      varchar2(512)
       ) ;
    TYPE t_cursor_array IS TABLE   OF OneRecord;
    cursor_output_array  t_cursor_array := t_cursor_array();

    -- this array holds the maximum width of each column
    TYPE integer_array IS TABLE OF INTEGER;   
    column_max_width_array integer_array := integer_array(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);

    --------------------------------------------------------------------------

  BEGIN  
    INITIALISE;

    OUTPUT_LOG(s_proc_name, DEBUG,'Starting ' );
     OUTPUT_LOG(s_proc_name,DEBUG, 'SQL :  ' || c_sql_text );

    c_sql_output := '';
    i_fetches := 0;

    IF DBMS_SQL.IS_OPEN(local_cursor_id) 
      THEN
      DBMS_SQL.CLOSE_CURSOR(local_cursor_id);
    END IF;

    BEGIN
          local_cursor_id := DBMS_SQL.OPEN_CURSOR;  
          DBMS_SQL.PARSE (local_cursor_id, c_sql_text , DBMS_SQL.native);  
          DBMS_SQL.DESCRIBE_COLUMNS2 (local_cursor_id, ColumnCount, VDescTab);
    EXCEPTION
          WHEN OTHERS THEN
          OUTPUT_LOG(s_proc_name, ERROR, 'ISSUES compiling SQL - ' || SQLERRM);
          RAISE;
          RETURN;
    END ;



    -- there is a limit to how many columns this proc can deal with
    ColumnCount := least(ColumnCount, MaxColumns);
       -- setup the column headers   
      /*FOR LOOP to define the columns that comes in the Query statement
        The data types that are handled in the Col_type data type parameter are:
        1 - Varchar2
        2 - Number
        12 - Date
      */  
      cursor_output_array.EXTEND;
      FOR y IN 1 .. ColumnCount 
          LOOP  

           CASE VDescTab(y).col_type
               when dbms_types.TYPECODE_DATE  THEN
                        DBMS_SQL.define_column(local_cursor_id, y, colDATE); 
               WHEN dbms_types.TYPECODE_NUMBER THEN
                        DBMS_SQL.define_column(local_cursor_id, y, colNUMBER); 
               WHEN dbms_types.TYPECODE_VARCHAR2 THEN                    
                        DBMS_SQL.define_column(local_cursor_id, y, colVARCHAR2, MaxColumnWidth);           
              ELSE 
                        DBMS_SQL.define_column(local_cursor_id, y, colVARCHAR2, MaxColumnWidth); 
           END CASE ;

          -- now put the column names into the array :

           CASE y
              WHEN 1 THEN cursor_output_array(1).column1 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 2 THEN cursor_output_array(1).column2 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 3 THEN cursor_output_array(1).column3 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 4 THEN cursor_output_array(1).column4 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 5 THEN cursor_output_array(1).column5 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 6 THEN cursor_output_array(1).column6 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 7 THEN cursor_output_array(1).column7 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 8 THEN cursor_output_array(1).column8 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 9 THEN cursor_output_array(1).column9 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 10 THEN cursor_output_array(1).column10 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 11 THEN cursor_output_array(1).column11 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 12 THEN cursor_output_array(1).column12 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 13 THEN cursor_output_array(1).column13 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 14 THEN cursor_output_array(1).column14 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 15 THEN cursor_output_array(1).column15 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
              WHEN 16 THEN cursor_output_array(1).column16 := VDescTab(y).col_name;  column_max_width_array(y) := length(VDescTab(y).col_name ); 
            END CASE;
      END LOOP;
    --------------------------------------------------------------------
    -- now prepare the bind variables, if any
    -- the BIND_VARIABLE parameter is a comma separated list.  Next delimit it and extract the bind variable values
    -- convert the bind parameter string to nested table 
    -----------------------------------------------------------------------
    POPULATE_CSV_ARRAY(s_csv_string => p_bind_variables , t_csv_table => V_BIND_LIST );
    -- now iterate throught the list and apply each bind variable
    FOR i IN 1..V_BIND_LIST.COUNT
      LOOP
         OUTPUT_LOG(s_proc_name, DEBUG, 'Identified bind variable :' ||  i ||' - ' || V_BIND_LIST(i) );
         DBMS_SQL.BIND_VARIABLE(local_cursor_id,   ':' || i , V_BIND_LIST(i));
      END LOOP;
    -- binds loaded, now execute
    --------------------------------------
    -- input section.  
    -- EXECUTE the query, and read the resulting cursor into the TABLE
    --------------------------------------
    OUTPUT_LOG(s_proc_name,DEBUG, 'About to execute '  );

    BEGIN
       DB := DBMS_SQL.execute(local_cursor_id); 
    -- If the query returns no data, there's nothing more to do
    EXCEPTION
      WHEN OTHERS THEN
          OUTPUT_LOG(s_proc_name, ERROR, 'Error when executing  : ' || SQLERRM) ;
          RAISE;
          RETURN;
    END;

    --OUTPUT_LOG(s_proc_name,DEBUG, 'Now fetching '  );
    i_fetches := 0;  
    WHILE (DBMS_SQL.fetch_rows(local_cursor_id) > 0) 
      LOOP     
              IF (i_fetches >= MaxRows) 
                 THEN
                   OUTPUT_LOG(s_proc_name, ERROR, 'MaxRows reached : ' || i_fetches) ;
                   exit;
              END IF;  
              cursor_output_array.EXTEND;
              i_fetches := i_fetches +1;

                FOR y iN 1..ColumnCount 
                  LOOP
                     -- get the valuie from the column
                     CASE VDescTab(y).col_type
                         when dbms_types.TYPECODE_DATE  THEN
                                   DBMS_SQL.COLUMN_VALUE(local_cursor_id, y, colDATE); 
                                   s_converted_value := TO_CHAR(colDATE,'YYYYMMDD HH24:MI.SS' );
                         WHEN dbms_types.TYPECODE_NUMBER THEN
                                  DBMS_SQL.COLUMN_VALUE(local_cursor_id, y, colNUMBER); 
                                  s_converted_value := TO_CHAR(colNUMBER,'FM9999999999999999999999');
                                 -- OUTPUT_LOG(s_proc_name, 'number : ' || ColNum || ' is now ' || s_converted_value ); 
                                  --s_converted_value := '  ' || TRIM( s_converted_value);
                         WHEN dbms_types.TYPECODE_VARCHAR2 THEN                    
                                  DBMS_SQL.COLUMN_VALUE(local_cursor_id, y, colVARCHAR2);
                                 s_converted_value := colVARCHAR2;         
                        ELSE 
                                   DBMS_SQL.COLUMN_VALUE(local_cursor_id, y, colVARCHAR2);  
                                   s_converted_value := TO_CHAR(colVARCHAR2); 
                     END CASE ;    
                   -- store the column value in the nested table
                   CASE y
                      WHEN 1  THEN cursor_output_array(i_fetches+1).column1  := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 2  THEN cursor_output_array(i_fetches+1).column2  := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 3  THEN cursor_output_array(i_fetches+1).column3  := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 4  THEN cursor_output_array(i_fetches+1).column4  := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 5  THEN cursor_output_array(i_fetches+1).column5  := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 6  THEN cursor_output_array(i_fetches+1).column6  := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 7  THEN cursor_output_array(i_fetches+1).column7  := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 8  THEN cursor_output_array(i_fetches+1).column8  := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 9  THEN cursor_output_array(i_fetches+1).column9  := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 10 THEN cursor_output_array(i_fetches+1).column10 := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 11 THEN cursor_output_array(i_fetches+1).column11 := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 12 THEN cursor_output_array(i_fetches+1).column12 := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 13 THEN cursor_output_array(i_fetches+1).column13 := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 14 THEN cursor_output_array(i_fetches+1).column14 := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 15 THEN cursor_output_array(i_fetches+1).column15 := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                      WHEN 16 THEN cursor_output_array(i_fetches+1).column16 := s_converted_value;  column_max_width_array(y) := greatest( NVL(length(s_converted_value),0), column_max_width_array(y) );
                    END CASE;
                  END LOOP; 
      END LOOP;


    IF ( i_fetches = 0 )
      THEN
        OUTPUT_LOG(s_proc_name, DEBUG, 'Ending : i_fetches is : ' || i_fetches );
        DBMS_SQL.CLOSE_CURSOR(local_cursor_id);
        RETURN;
      END IF;
    --------------------------------------
    -- output section.  Write out the nested table into a CLOB
    --------------------------------------

    -- this check ensure that no column value exceeds the maximum column width
    FOR Y IN 1..column_max_width_array.COUNT
      LOOP
          column_max_width_array(Y) := LEAST(column_max_width_array(Y), MaxColumnWidth );
      END LOOP;

    OUTPUT_LOG(s_proc_name,DEBUG, 'Writing out the data into the nested table '  );
    BEGIN
             -- now write out the data in the cursor,iterate through each row, one at a time
              FOR Y IN 1..cursor_output_array.COUNT
                LOOP
                  -- OUTPUT_LOG(s_proc_name,DEBUG, 'Printing line  ' || Y  );
                  -- print out one row, starting with a carriage return
                  c_sql_output := c_sql_output || chr(13) || chr(10) ;
                  IF ( Y = 2 ) 
                       THEN
                            -- PRINT THE COLUMN UNDERLINES
                           c_sql_output := c_sql_output ||  rpad('-',column_max_width_array(1), '-') ;
                           FOR I IN 2..ColumnCount
                               LOOP
                               c_sql_output := c_sql_output || ' ' || rpad('-',column_max_width_array(I), '-') ;
                               END LOOP;
                            c_sql_output := c_sql_output || chr(13) || chr(10) ;
                        END IF;
                  -- Now print out each column data
                  FOR X IN 1..ColumnCount
                    LOOP
                      CASE 
                        WHEN X=1 AND   ( VDescTab(X).col_type  = DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output ||         LPAD( nvl(cursor_output_array(Y).column1, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=1 AND   ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output ||         RPAD( nvl(cursor_output_array(Y).column1, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=2 AND   ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column2, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=2 AND   ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column2, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=3 AND   ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column3, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=3 AND   ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column3, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=4 AND   ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column4, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=4 AND   ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column4, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=5 AND   ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column5, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=5 AND   ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column5, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=6 AND   ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column6, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=6 AND   ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column6, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=7 AND   ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column7, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=7 AND   ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column7, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=8 AND   ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column8, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=8 AND   ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column8, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=9 AND   ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column9, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=9 AND   ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column9, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=10 AND  ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column10, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=10 AND  ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column10, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=11 AND  ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column11, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=11 AND  ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column11, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=12 AND  ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column12, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=12 AND  ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column12, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=13 AND  ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column13, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=13 AND  ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column13, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=14 AND  ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column14, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=14 AND  ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column14, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=15 AND  ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column15, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=15 AND  ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column15, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=16 AND  ( VDescTab(X).col_type =  DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  LPAD( nvl(cursor_output_array(Y).column16, ' ') ,  column_max_width_array(X) ); 
                        WHEN X=16 AND  ( VDescTab(X).col_type != DBMS_TYPES.TYPECODE_NUMBER) THEN c_sql_output := c_sql_output || ' ' ||  RPAD( nvl(cursor_output_array(Y).column16, ' ') ,  column_max_width_array(X) ); 
                      END CASE;

                    END LOOP;
                    if ( length(c_sql_output) >= Max_Size_Characters) 
                      THEN
                      RAISE string_buffer_too_small;
                     END IF;
               END LOOP;

    EXCEPTION
             WHEN string_buffer_too_small THEN
                OUTPUT_LOG(s_proc_name,INFO, 'This SQL exceeded the string buffer size '  );
                c_sql_output := c_sql_output || chr(13) || chr(10) || 'Rows Truncated';
             WHEN OTHERS THEN
                OUTPUT_LOG(s_proc_name, ERROR, 'Other error writing out the SQL text :  '|| SQLERRM  );
                RAISE;
    END; 

    DBMS_SQL.DESCRIBE_COLUMNS2 (local_cursor_id, ColumnCount, VDescTab);
    IF (ColumnCount > MaxColumns) 
      THEN
        OUTPUT_LOG(s_proc_name,DEBUG, 'You have ' || ColumnCount || ' columns, which is more than the maximum in this proc of ' || MaxColumns   );
        c_sql_output := c_sql_output || TO_CLOB( CHR(13) || CHR(10) || 'You have ' || ColumnCount || ' columns, which is more than the maximum in this proc of ' || MaxColumns );
    END IF;

    DBMS_SQL.CLOSE_CURSOR(local_cursor_id);

    OUTPUT_LOG(s_proc_name, DEBUG,'Ending : i_fetches is : ' || i_fetches );
    OUTPUT_LOG(s_proc_name, DEBUG,'Ending : the SQL output is : ' || c_sql_output );
    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name,ERROR, '2Other error ' || SQLERRM ); 
         OUTPUT_LOG(s_proc_name,DEBUG, 'The SQL that failed is :   ' || c_sql_text );
         IF (DBMS_SQL.IS_OPEN( local_cursor_id ) )
            THEN
            DBMS_SQL.CLOSE_CURSOR(local_cursor_id);
            END IF;
       RAISE;
    END EXECUTE_SQL;


  --------------------------------------
  --  EXECUTE_REMOTE_CLOB 
  --
  -- This proc executes a CLOB variable on a remote database, via a database link.
  -- 
  -- This is not easy to do.  This approach stores the CLOB in a special column on the DBHC_DATABASES table. It then
  -- redeployes that table to the target database.  And then it creates a temporary proc that executes the CLOB on the target
  -- database.
  ----------------------------------------

    PROCEDURE EXECUTE_REMOTE_CLOB( c_DDL IN CLOB, s_db_link_name In VARCHAR2, s_package_name VARCHAR2)
    AS 
      s_proc_name VARCHAR2(2048) := 'EXECUTE_REMOTE_CLOB ' || s_db_link_name;
      s_remote_text VARCHAR2(32000);
      s_local_text VARCHAR2(32000);
      s_remote_DDL VARCHAR2(32000) :=  'BEGIN
                                        dbms_utility.EXEC_DDL_STATEMENT@' || s_db_link_name || '( :1 ) ;  
                                        END;';


    TYPE ERROR_TYPE is table of USER_ERRORS%ROWTYPE;
     t_error_table  ERROR_TYPE;

     error_cursor     SYS_REFCURSOR;
     s_sql_text CLOB;

    BEGIN
      OUTPUT_LOG(s_proc_name, INFO, 'Starting ');
      commit;

     EXECUTE IMMEDIATE  'ALTER SESSION SET REMOTE_DEPENDENCIES_MODE=''Signature''  ';

    update dbhc_databases set TEMP_CLOB = c_DDL where DATABASE_ROLE = 'MASTER' and database_environment = global_this_environment ;
     s_remote_text := 'TRUNCATE TABLE DBHC_DATABASES';
     EXECUTE IMMEDIATE s_remote_DDL using s_remote_text ;
     s_local_text := 'INSERT INTO  DBHC_DATABASES@' || s_db_link_name || '  SELECT * FROM  DBHC_DATABASES' ;
     EXECUTE IMMEDIATE s_local_text;
    COMMIT;

    -- first create the temp remote proc :
    s_remote_text := 'CREATE OR REPLACE PROCEDURE TEMP_PROC
                        AS 
                      s_DDL CLOB;
                      BEGIN
                      SELECT TEMP_CLOB INTO s_DDL FROM DBHC_DATABASES WHERE DATABASE_ROLE = ''MASTER'' and  DATABASE_ENVIRONMENT = ''' || global_this_environment || ''';
                      EXECUTE IMMEDIATE s_DDL;
                      END;   ' ;
     COMMIT;   
    OUTPUT_LOG(s_proc_name, DEBUG, s_remote_text);        
    execute immediate s_remote_DDL using s_remote_text;  

    -- now execute the remote proc
    s_remote_text := 'begin TEMP_PROC@' || s_db_link_name || ';    end;'   ;
    OUTPUT_LOG(s_proc_name, DEBUG,  s_remote_text);
    execute immediate s_remote_text;


    -- now drop the remote proc 
    s_remote_text := 'DROP PROCEDURE TEMP_PROC';
    execute immediate s_remote_DDL using s_remote_text;

    update dbhc_databases set TEMP_CLOB = null;
    COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
         OUTPUT_LOG(s_proc_name,ERROR, 'Other error ' || SQLERRM ); 
         -- now check for errors
        ROLLBACK;
        s_sql_text := 'select * from USER_ERRORS@' || s_db_link_name || ' WHERE NAME = :1';
        OPEN error_cursor FOR s_sql_text USING s_package_name;
        fetch error_cursor bulk collect into t_error_table;
        close error_cursor;
        IF ( t_error_table.count > 0 )
          THEN   
            OUTPUT_LOG(s_proc_name,ERROR, 'Errors detected after compiling ' || s_package_name );
            FOR i IN 1 .. t_error_table.count
              LOOP 
              OUTPUT_LOG(s_proc_name,ERROR, 'Error : ' || t_error_table(i).text );
              END LOOP;
          COMMIT;
          RAISE_APPLICATION_ERROR( exc_EXECUTE_CLOB_REMOTE, 'There were ' || t_error_table.count || ' errors when compiling remote package ' || s_package_name  );
          END IF;
         RAISE;

    END EXECUTE_REMOTE_CLOB;


  END DBHC_PKG;

