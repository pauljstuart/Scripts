

-----------------------------------------------------------------------------------------------------------------------------
--
--  OUTPUT_PKG
--
--
-- SETUP()
-- OUTPUT( p_text ,  p_log_level,  p_number ,  p_error );
--
-- log_levels :
-- 
-- Level 0 :  basic level, this level is always on and cannot be turned off
-- Level 1 : info
-- Level 3:  Debug 1
-- level 5 : Debug 5
--
-- You set the log_level like this :

-- OUTPUT_PKG.SETUP( p_log_level => 3);
--
-- The result is that anything OUTPUT with log_level 3 or below will be printed.  Everything above (4 upwards) will be ignored.
-- So, the higher, the more detailed debugging output. 
--
--  PROCESS_NAME     PROCESS_START_TIME       LOG_LEVEL LOG_TIME                LOG_TEXT                           REFERENCE ERROR_CODE
-- ---------------- ----------------------- ---------- ----------------------- --------------------------------- ---------- ----------
-- DEFAULT          WED 22-05-2019 14:57.26          0 WED 22-05-2019 14:57.26 truncated OUTPUTLOG                        0 0         
-- DEFAULT          WED 22-05-2019 14:57.26          0 WED 22-05-2019 14:57.45 test1                                      0 0         --
-- DEFAULT          WED 22-05-2019 14:57.26          0 WED 22-05-2019 14:57.45 test2                                      0 0         
-- DEFAULT          WED 22-05-2019 14:57.26          0 WED 22-05-2019 14:57.45 test3                                      0 0         
--
--

--
-----------------------------------------------------------------------------------------------------------------------------

create or replace package output_pkg as

   g_process_name VARCHAR2(128) := 'DEFAULT';
  g_start_timestamp  timestamp := SYSTIMESTAMP;
  g_log_level NUMBER(1) := 0;
  procedure output(  p_text in VARCHAR2 default null,  p_log_level in number default 0,  p_number in NUMBER default 0,  p_error in varchar2 DEFAULT 0 );

procedure setup( p_log_level in integer default null , p_process_name in VARCHAR2 default null, p_truncate IN BOOLEAN  default FALSE );

  s_logtable_name VARCHAR2(128) := 'OUTPUTLOG';
  s_create_text VARCHAR2(2048) := 'create table  ' || s_logtable_name || q'# (process_name VARCHAR2(256), process_start_time TIMESTAMP, log_level number(1), log_time TIMESTAMP, log_text CLOB ,  reference INTEGER, error_code VARCHAR2(256)  )     
                                       PARTITION BY RANGE (log_time) 
                                      INTERVAL(NUMTOdsINTERVAL(1, 'DAY'))   
                                     (partition empty values less than ( TO_DATE('20190101','YYYYMMDD') ) )   #';

end;
/

-----------------------------------------------------------------------------------------------------------------------------




create or replace package body OUTPUT_PKG 
as


procedure setup( p_log_level in integer default null , p_process_name in VARCHAR2 default null, p_truncate IN BOOLEAN  default FALSE )
is
  already_exists exception; 
  pragma exception_init( already_exists, -955 );
begin
  if ( p_log_level is not null)
  THEN 
  g_log_level := p_log_level;
    output('Log level set to ' || p_log_level);
  end if;

 if ( p_process_name is not null ) 
  THEN
  g_process_name := p_process_name;
  g_start_timestamp := SYSTIMESTAMP;
  output('Process name set to ' || g_process_name );
  end if;

  for i in (select 1 from DUAL WHERE NOT EXISTS (SELECT 1 FROM USER_TABLES WHERE TABLE_NAME =   s_logtable_name ) )
  loop
        Execute immediate s_create_text ;
      output( 'created log table ' || s_logtable_name ); 
  end loop;

  IF ( p_truncate = TRUE)
  THEN
            execute immediate 'TRUNCATE table ' || s_logtable_name ;
            output( 'truncated ' || s_logtable_name ); 
  END if;

  COMMIT;
end setup;





procedure output(  p_text in VARCHAR2 default null,  p_log_level in number default 0,  p_number in NUMBER default 0,  p_error in varchar2 DEFAULT 0 )
IS
PRAGMA AUTONOMOUS_TRANSACTION;
   lines DBMS_OUTPUT.CHARARR;
   numlines INTEGER := 2000;
  c_sqltext CLOB;
    i INTEGER := 1;
begin

  DBMS_OUTPUT.ENABLE( buffer_size => NULL);
 
  for i in (select 1 from DUAL WHERE NOT EXISTS (SELECT 1 FROM USER_TABLES WHERE TABLE_NAME =   s_logtable_name ) )
  loop
        Execute immediate s_create_text;
       dbms_output.put_line( 'created log table ' || s_logtable_name ); 
  end loop;

      DBMS_OUTPUT.GET_LINES( lines, numlines );
      WHILE i <= numlines  
        LOOP
        c_sqltext := ' insert into ' || s_logtable_name || '  (process_start_time, process_name, log_level, log_time ,  log_text, reference, error_code  ) values ( ''' || g_start_timestamp || ''',''' || g_process_name || ''', ' || g_log_level || ',  SYSTIMESTAMP, q''#'  ||  lines(i) || '#'', ' || p_number  || ', ' || p_error || ' ) '; 
     -- dbms_output.put_line( c_sqltext );
        execute immediate c_sqltext ;
        commit;
        i := i + 1;
        END LOOP;


  IF p_text is null then
    return;
  end if;

  IF ( g_log_level >= p_log_level  )  
    THEN
       
        c_sqltext := ' insert into ' || s_logtable_name || '   (process_start_time, process_name, log_level, log_time ,  log_text, reference, error_code  ) values ( ''' || g_start_timestamp || ''',''' || g_process_name || ''', ' || g_log_level || ',  SYSTIMESTAMP, q''#'  ||  p_text || '#'', ' || p_number  || ', ' || p_error || ' ) '; 
       --dbms_output.put_line( c_sqltext );
        execute immediate c_sqltext ;
      commit;
       RETURN;
    END IF;


END OUTPUT;
------------------------------------------------------------------------------

END;
/





-------------------------- monitoring code-----------------------------------------------------


column  PROCESS_NAME   format A30
column  PROCESS_START_TIME  format A30
column  LOG_LEVEL format 999
column LOG_TIME  format A20
column  LOG_TEXT   format A100
column   REFERENCE format 999,999
column  ERROR_CODE format A10


SELECT *
FROM
(
select process_START_TIME, PROCESS_NAME, LOG_LEVEL,  LOG_TIME,  LOG_TEXT,REFERENCE, ERROR_CODE, ROW_NUMBER() OVER (ORDER BY LOG_TIME DESC) ROW_NUM
 from outputlog 
order by log_TIME
)
WHERE ROW_NUM < 100; 

-----------------------------------------------------------------------------------

DROP TABLE outputlog;

exec OUTPUT_PKG.setup( p_truncate => TRUE);


drop table outputlog;


@part_table MVDS OUTPUTLOG

@TAB_PARTITIONS MVDS OUTPUTLOG


set serveroutput on
begin
  dbms_output.put_line('test1');
  dbms_output.put_line('test2' );
  OUTPUT_PKG.output('test3');

end;
/



select * from outputlog order by log_time;



set serveroutput on
begin
   dbms_output.put_line('test1');
  OUTPUT_PKG.SETUP( p_process => 'DEFAULT3', p_log_level2 => 3);
  OUTPUT_PKG.output('test4', p_log_level => 5);
  OUTPUT_PKG.output('test5');

end;
/
