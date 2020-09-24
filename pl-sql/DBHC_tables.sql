

---------------------------------------------------
-- DBHC_DATABASE_PROPERTIES TABLE
--------------------------------------------------

---------------------------------------------------
-- DBHC_DATABASES TABLE
--------------------------------------------------


DROP TABLE DBHC_DATABASES;
CREATE TABLE DBHC_DATABASES (
DATABASE_NAME            VARCHAR2(1024)  not null,
DATABASE_CONNECT_STRING  VARCHAR2(4000)  not null,
DATABASE_ROLE            VARCHAR2(1024) NOT NULL,
DATABASE_ENVIRONMENT     VARCHAR2(256) NOT NULL,
DBHC_VERSION            NUMBER(8,2),
AUTOSYS_ENV_USERID       VARCHAR2(256 ) NOT NULL,            
AUTOSYS_ENV_PASSWORD     VARCHAR2(256 ) NOT NULL ,       
AUTOSYS_ENV_SERVER       VARCHAR2(256 )  NOT NULL ,
REMOTE_DATABASE_NAME	VARCHAR2(1024 ),
TEMP_CLOB       CLOB
); 



---------------------------------------------------
-- DBHC_SQL TABLE
--------------------------------------------------
DROP TABLE DBHC_SQL;
CREATE TABLE DBHC_SQL (
CHECK_NO  INTEGER NOT NULL,
CHECK_DESCRIPTION VARCHAR2(1024) NOT NULL,
	SQL_EXECUTION_METHOD VARCHAR2(5),  
CHECK_CATEGORY  VARCHAR2(256),
CHECK_SQL_TEXT       CLOB NOT NULL
); 


---------------------------------------------------
-- DBHC_VARIABLES TABLE
--------------------------------------------------

DROP TABLE DBHC_VARIABLES;
CREATE TABLE DBHC_VARIABLES (
ENVIRONMENT             VARCHAR2(256) NOT NULL, 
VARIABLE_NAME            VARCHAR2(1024)  not null,
VARIABLE_TYPE            VARCHAR2(1024) ,
VARIABLE_VALUE            VARCHAR2(1024) NOT NULL,
EXPLANATION             VARCHAR2(4000) );


---------------------------------------------------
-- DBHC_CHECKS TABLE
--------------------------------------------------

DROP TABLE DBHC_CHECKS;
  CREATE TABLE DBHC_CHECKS 
   (	CHECK_NO integer NOT NULL , 
	CHECK_DESCRIPTION VARCHAR2(1024), 
	ENVIRONMENT VARCHAR2(256), 
	CHECK_FREQUENCY VARCHAR2(256), 
	ACTIVE_FLAG CHAR(1 BYTE), 
	APPLICABLE_DATABASES varchar2(4000), 
    BIND_VARIABLES   VARCHAR2(4000),
	CHECK_NOTIFICATIONS varchar2(256)
   ) ;


COMMENT ON COLUMN DBHC_CHECKS.CHECK_NO IS 'The check number';
COMMENT ON COLUMN DBHC_CHECKS.CHECK_FREQUENCY  IS 'The frequency of the check, DBMS_SCHEDULER format';
COMMENT ON COLUMN DBHC_CHECKS.APPLICABLE_DATABASES  IS 'Either the phrase ALL, or a comma separated list of database to run on';


---------------------------------------------------
-- DBHC__ALERTS TABLE
--------------------------------------------------
DROP TABLE DBHC_ALERTS;
  CREATE TABLE DBHC_ALERTS
   (	  CHECK_EXECUTION_TIME TIMESTAMP NOT NULL,
   CHECK_NO integer NOT NULL , 
	CHECK_DESCRIPTION VARCHAR2(1024), 
	ENVIRONMENT VARCHAR2(256), 
   DATABASE_NAME VARCHAR2(1024),
    BIND_VARIABLES   VARCHAR2(4000),
    CHECK_ELAPSED_TIME  NUMBER(8,2),
	CHECK_OUTPUT CLOB,
  EMAIL_SENT  VARCHAR2(4000)
   ) 
                                       PARTITION BY RANGE (CHECK_EXECUTION_TIME) 
                                      INTERVAL(NUMTOdsINTERVAL(1, 'DAY'))   
                                     (partition empty values less than ( TO_DATE('20190101','YYYYMMDD') ) )  ;



---------------------------------------------------
-- DBHC_LOG TABLE
--------------------------------------------------

DROP TABLE DBHC_LOG;
create table DBHC_LOG (process_name VARCHAR2(1024),  DATABASE_NAME VARCHAR2(1024), log_category varchar2(10), log_time TIMESTAMP, log_text CLOB ,  INFO1 VARCHAR2(1024) , INFO2 VARCHAR2(1024), ERROR_CODE INTEGER  )     
                                       PARTITION BY RANGE (log_time) 
                                      INTERVAL(NUMTOdsINTERVAL(1, 'DAY'))   
                                     (partition empty values less than ( TO_DATE('20190101','YYYYMMDD') ) )  ;

--alter table DBHC_LOG add (log_category varchar2(10) );


---------------------------------------------------
-- DBHC_SUPPRESS TABLE
--------------------------------------------------
DROP TABLE DBHC_SUPPRESS;
  CREATE TABLE DBHC_SUPPRESS 
   (	START_DATE   DATE NOT NULL, 
        END_DATE   DATE NOT NULL,
        ENVIRONMENT   VARCHAR2(256) NOT NULL,
        CHECK_NO    INTEGER,
        DATABASE_NAME VARCHAR2(1024) NOT NULL
   ) ;

---------------------------------------------------
-- VIEWS 
--------------------------------------------------

-- DATABASE SPECIFIC :

create or replace view DBHC_THISDB_CHECKS
AS
with db_name as
(
select      sys_context('USERENV','DB_NAME') as global_this_database from DUAL
),
 remote_db as
( SELECT  REMOTE_DATABASE_NAME  from DBHC_DATABASES WHERE DATABASE_NAME = (select      sys_context('USERENV','DB_NAME') DB_NAME from DUAL) 
)
SELECT  (select  sys_context('USERENV','DB_NAME') DB_NAME from DUAL) AS DATABASE_NAME,
        C.CHECK_NO ,
        S.CHECK_DESCRIPTION, 
        S.SQL_EXECUTION_METHOD, 
      --    ACTIVE_FLAG, 
          APPLICABLE_DATABASES, 
          ENVIRONMENT, 
          CHECK_NOTIFICATIONS,
          BIND_VARIABLES,
        S.CHECK_SQL_TEXT
        FROM DBHC_CHECKS C, DBHC_SQL S, DB_NAME
where S.CHECK_NO = C.CHECK_NO
        AND ACTIVE_FLAG = 'Y' AND (APPLICABLE_DATABASES = global_this_database OR APPLICABLE_DATABASES LIKE '%' || global_this_database || ',%'   OR APPLICABLE_DATABASES LIKE '%,' || global_this_database  or APPLICABLE_DATABASES = 'ALL' )   
             AND ENVIRONMENT =  (select database_environment from dbhc_databases where database_name = global_this_database )
        UNION ALL
        SELECT  remote_database_NAME AS DATABASE_NAME,
        C.CHECK_NO ,
        S.CHECK_DESCRIPTION, 
        S.SQL_EXECUTION_METHOD, 
     --     ACTIVE_FLAG, 
          APPLICABLE_DATABASES, 
          ENVIRONMENT, 
          CHECK_NOTIFICATIONS,
          BIND_VARIABLES,
        S.CHECK_SQL_TEXT
        FROM DBHC_CHECKS C, DBHC_SQL S , remote_db
       WHERE S.CHECK_NO = C.CHECK_NO
       AND ACTIVE_FLAG = 'Y' AND (APPLICABLE_DATABASES = remote_database_name OR APPLICABLE_DATABASES LIKE '%' || remote_database_name || ',%'   OR APPLICABLE_DATABASES LIKE '%,' || remote_database_name  or APPLICABLE_DATABASES = 'ALL' )    
             AND ENVIRONMENT = (select database_environment from dbhc_databases where database_name = remote_db.remote_database_name )
         and S.check_category != 'Configuration';



create or replace view DBHC_THISDB_ALERTS
AS
SELECT * 
FROM
(
SELECT CHECK_EXECUTION_TIME, CHECK_NO, CHECK_DESCRIPTION, ENVIRONMENT, DATABASE_NAME, BIND_VARIABLES, CHECK_ELAPSED_TIME, CHECK_OUTPUT, EMAIL_SENT, ROW_NUMBER() OVER (ORDER BY CHECK_EXECUTION_TIME DESC) ROW_NUM
FROM DBHC_ALERTS
ORDER BY CHECK_EXECUTION_TIME
)
WHERE ROW_NUM < 1000;


create or replace view DBHC_THISDB_LOG
AS
SELECT *
FROM
(
SELECT LOG_TIME, LOG_CATEGORY, DATABASE_NAME, PROCESS_NAME,  LOG_TEXT, ROW_NUMBER() OVER (ORDER BY LOG_TIME DESC) ROW_NUM
 from DBHC_LOG
order by log_TIME
)
WHERE ROW_NUM < 1000; 



create or replace view DBHC_THISDB_VARIABLES
as
  WITH PIVOT1 AS
(
SELECT VARIABLE_NAME,
       VARIABLE_TYPE,
       VARIABLE_VALUE,
       EXPLANATION,
     ENVIRONMENT, (CASE ENVIRONMENT WHEN 'ALL' THEN 0  
                       WHEN DATABASE_ENVIRONMENT                THEN 1
                       WHEN (SELECT      sys_context('USERENV','DB_NAME') DB_NAME from DUAL)      THEN 2  
                       END ) AS VARIABLE_RANK
FROM DBHC_VARIABLES,  DBHC_DATABASES d
WHERE   (ENVIRONMENT = 'ALL' OR ENVIRONMENT = DATABASE_ENVIRONMENT OR ENVIRONMENT = (select      sys_context('USERENV','DB_NAME') DB_NAME from DUAL)  )
AND D.DATABASE_NAME = (select      sys_context('USERENV','DB_NAME') DB_NAME from DUAL)
ORDER BY VARIABLE_NAME
),
pivot2 as
(
SELECT variable_name, variable_type, environment, variable_value, EXPLANATION, rank() OVER (PARTITION BY VARIABLE_NAME order by variable_rank desc) as rank_col
FROM PIVOT1 p
)
select variable_name, variable_type, variable_value, EXPLANATION
from pivot2 where rank_col = 1;




-- ENVIRONMENT :

create or replace view DBHC_THISENV_CHECKS
AS
SELECT * FROM DBHC_CHECKS
WHERE ENVIRONMENT IN (SELECT DATABASE_ENVIRONMENT FROM DBHC_DATABASES WHERE DATABASE_NAME = (SELECT      sys_context('USERENV','DB_NAME') DB_NAME from DUAL) )
ORDER BY CHECK_NO;




create or replace view DBHC_THISENV_DATABASES
AS
SELECT 
DATABASE_NAME           , 
DATABASE_ROLE          ,
DATABASE_ENVIRONMENT    ,  
DBHC_VERSION             ,       
AUTOSYS_ENV_USERID       ,
AUTOSYS_ENV_PASSWORD      ,
AUTOSYS_ENV_SERVER     ,
DATABASE_CONNECT_STRING 
 FROM DBHC_DATABASES
WHERE DATABASE_ENVIRONMENT IN (SELECT DATABASE_ENVIRONMENT FROM DBHC_DATABASES WHERE DATABASE_NAME = (SELECT      sys_context('USERENV','DB_NAME') DB_NAME from DUAL) )
ORDER BY DATABASE_NAME;


create or replace view DBHC_THISENV_VARIABLES
AS
SELECT * FROM DBHC_VARIABLES
WHERE ENVIRONMENT IN (SELECT DATABASE_ENVIRONMENT FROM DBHC_DATABASES WHERE DATABASE_NAME = (SELECT      sys_context('USERENV','DB_NAME') DB_NAME from DUAL) )
OR ENVIRONMENT = 'ALL'
ORDER BY ENVIRONMENT, VARIABLE_TYPE;


