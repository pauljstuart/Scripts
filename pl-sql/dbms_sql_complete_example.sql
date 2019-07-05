set serveroutput on
declare

  i_records NUMBER;
  ret INTEGER;
    TARGET_COLUMN          VARCHAR2(100)  ;
    TARGET_COLUMN_ID       NUMBER   ;      
    TARGET_PATH            VARCHAR2(100) ; 
    TABLE_NAME             VARCHAR2(30)  ; 
    TABLE_ORDER            NUMBER  ;       
    VERSIONING_MODEL       VARCHAR2(50) ; 
    COLUMN_NAME            VARCHAR2(30) ;  
    COLUMN_ID              NUMBER        ; 
    DATA_TYPE              VARCHAR2(30);   
    NULLABLE               VARCHAR2(1) ;   
    VIRTUAL_COLUMN         VARCHAR2(3) ;   
    IS_KEY                 CHAR(1)    ;   
    REF_TARGET_COLUMN      VARCHAR2(100)  ;
    REF_TARGET_PATH        VARCHAR2(100);  
    REF_TABLE              VARCHAR2(30) ;  
    REF_COLUMN             VARCHAR2(30);   
    ERROR_INFO             VARCHAR2(4000) ;

sql_text_clob1 CLOB := q'# 
select * from mrp.target_column #';


   nt2  mrp.target_column%rowtype;
  cursor_name INTEGER;

begin

  i_records := 0;

   begin
     cursor_name := DBMS_SQL.OPEN_CURSOR;
    
    DBMS_SQL.PARSE(cursor_name,  sql_text_clob1  , DBMS_SQL.NATIVE);
    dbms_sql.define_column(cursor_name, 1 ,TARGET_COLUMN , 100 ) ;
    dbms_sql.define_column(cursor_name, 2 ,TARGET_COLUMN_ID ) ;
    dbms_sql.define_column(cursor_name, 3 ,TARGET_PATH ,100 ) ;
    dbms_sql.define_column(cursor_name, 4 ,TABLE_NAME ,30 ) ;
    dbms_sql.define_column(cursor_name, 5 ,TABLE_ORDER ) ;
    dbms_sql.define_column(cursor_name, 6 ,VERSIONING_MODEL ,50 ) ;
    dbms_sql.define_column(cursor_name, 7 ,COLUMN_NAME ,30 ) ;
    dbms_sql.define_column(cursor_name, 8 ,COLUMN_ID ) ;
    dbms_sql.define_column(cursor_name, 9 ,DATA_TYPE ,30 ) ;
    dbms_sql.define_column(cursor_name, 10,NULLABLE ,1 ) ;
    dbms_sql.define_column(cursor_name, 11,VIRTUAL_COLUMN, 3 ) ;
    dbms_sql.define_column(cursor_name, 12,IS_KEY ,1 ) ;
    dbms_sql.define_column(cursor_name, 13,REF_TARGET_COLUMN ,100 ) ;
    dbms_sql.define_column(cursor_name, 14,REF_TARGET_PATH ,100 ) ;
    dbms_sql.define_column(cursor_name, 15,REF_TABLE ,30 ) ;
    dbms_sql.define_column(cursor_name, 16,REF_COLUMN ,30 ) ;
    dbms_sql.define_column(cursor_name, 17,ERROR_INFO ,4000 ) ;

    ret := DBMS_SQL.EXECUTE(cursor_name);

  EXCEPTION
      WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ISSUES compiling SQL - ' || SQLERRM);
   end ;

   LOOP                                        
    ret := DBMS_SQL.FETCH_ROWS(cursor_name);
    EXIT WHEN ret = 0;
    i_records := i_records +1 ;

    dbms_sql.column_value(cursor_name, 1 ,TARGET_COLUMN ) ;
    dbms_sql.column_value(cursor_name, 2 ,TARGET_COLUMN_ID ) ;
    dbms_sql.column_value(cursor_name, 3 ,TARGET_PATH ) ;
    dbms_sql.column_value(cursor_name, 4 ,TABLE_NAME ) ;
    dbms_sql.column_value(cursor_name, 5 ,TABLE_ORDER ) ;
    dbms_sql.column_value(cursor_name, 6 ,VERSIONING_MODEL ) ;
    dbms_sql.column_value(cursor_name, 7 ,COLUMN_NAME ) ;
    dbms_sql.column_value(cursor_name, 8 ,COLUMN_ID ) ;
    dbms_sql.column_value(cursor_name, 9 ,DATA_TYPE ) ;
    dbms_sql.column_value(cursor_name, 10,NULLABLE ) ;
    dbms_sql.column_value(cursor_name, 11,VIRTUAL_COLUMN ) ;
    dbms_sql.column_value(cursor_name, 12,IS_KEY ) ;
    dbms_sql.column_value(cursor_name, 13,REF_TARGET_COLUMN ) ;
    dbms_sql.column_value(cursor_name, 14,REF_TARGET_PATH ) ;
    dbms_sql.column_value(cursor_name, 15,REF_TABLE ) ;
    dbms_sql.column_value(cursor_name, 16,REF_COLUMN ) ;
    dbms_sql.column_value(cursor_name, 17,ERROR_INFO ) ;

 insert into perf_support.target_column_test (TARGET_COLUMN,    
                TARGET_COLUMN_ID,     
                TARGET_PATH,           
                TABLE_NAME,                
                TABLE_ORDER,                 
                VERSIONING_MODEL,       
                COLUMN_NAME,            
                COLUMN_ID,                 
                DATA_TYPE,             
                NULLABLE ,              
                VIRTUAL_COLUMN,       
                IS_KEY  ,                    
                REF_TARGET_COLUMN,      
                REF_TARGET_PATH,         
                REF_TABLE,                
                REF_COLUMN  ,
                ERROR_INFO             ) 
                values (
                                TARGET_COLUMN ,
                                TARGET_COLUMN_ID      ,  
                                TARGET_PATH          ,
                                TABLE_NAME           ,   
                                TABLE_ORDER           ,     
                                VERSIONING_MODEL      , 
                                COLUMN_NAME          , 
                                COLUMN_ID             ,      
                                DATA_TYPE            ,  
                                NULLABLE             , 
                                VIRTUAL_COLUMN        , 
                                IS_KEY                 ,      
                                REF_TARGET_COLUMN     , 
                                REF_TARGET_PATH       , 
                                REF_TABLE              ,
                                REF_COLUMN            ,  
                                ERROR_INFO   );
  END LOOP;
 
  dbms_output.put_line('got ' || i_records) ;
  commit;
end;
/
