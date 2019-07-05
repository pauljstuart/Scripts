
set serveroutput on 


define SQL_ID=&1


DECLARE
 myReport  CLOB;
 l_offset number := 1;

-------------------------------
    procedure printCLOB (p_clob in out nocopy clob) 
    is
       i_offset        number := 1;
       i_amount      integer;
       i_clob_length  number := dbms_lob.getlength(p_clob);
       lc_buffer     varchar2(32767);
      
     begin
     if ( dbms_lob.isopen(p_clob) != 1 ) then
         dbms_lob.open(p_clob, 0);
     end if;
    
    DBMS_OUTPUT.ENABLE (buffer_size => NULL);   
    dbms_output.put_line( 'length : ' || i_clob_length );
    LOOP
   	 BEGIN
        i_amount := 32676 ;
        DBMS_LOB.READ ( lob_loc => p_clob, amount => i_amount,  offset => i_offset, buffer => lc_buffer);
        -- remove any partial lines at the end of the string :
        --dbms_output.put_line('i_amount ' || i_amount);
        if ( i_amount = 32676 ) then
		i_amount :=   instr( lc_buffer, chr(10), -1 ) -1;
        end if;
        dbms_output.put_line( substr(lc_buffer, 1, i_amount)  );
        i_offset := i_offset + i_amount +1;
        exception
            when no_data_found then exit;
        end;

    END LOOP;

    dbms_lob.close(p_clob);
    
    exception
       when others then
          dbms_output.put_line('Error : '||sqlerrm);
    end printCLOB;
 ---------------------------





    procedure printCLOB2 (p_clob in out nocopy clob) 
    is
       i_offset        number := 1;
       i_amount      integer;
       i_clob_length  number := dbms_lob.getlength(p_clob);
       lc_buffer     varchar2(32767);
      
     begin
     if ( dbms_lob.isopen(p_clob) != 1 ) then
         dbms_lob.open(p_clob, 0);
     end if;
    
    DBMS_OUTPUT.ENABLE (buffer_size => NULL);    

    dbms_output.put_line( 'length : ' || i_clob_length );
        i_amount := 32676 ;
        DBMS_LOB.READ ( lob_loc => p_clob, amount => i_amount,  offset => i_offset, buffer => lc_buffer);
        -- remove any partial lines at the end of the string :
        --dbms_output.put_line('i_amount ' || i_amount);
        if ( i_amount = 32676 ) then
		i_amount :=   instr( lc_buffer, chr(10), -1 ) -1;
		i_offset := i_offset + i_amount +1;
        end if;
        dbms_output.put_line( substr(lc_buffer, 1, i_amount)  );

    dbms_lob.close(p_clob);
    
    exception
       when others then
          dbms_output.put_line('Error : '||sqlerrm);
    end printCLOB2;

    
   
BEGIN

  dbms_output.put_line( chr(10) || chr(10) || 'Looking for sql text for &SQL_ID : ' || chr(10) || chr(10) || 'set worksheetname SQL_ID:&SQL_ID'  || chr(10) || chr(10) );

      BEGIN
      SELECT sql_fulltext INTO myReport FROM gv$sqlarea WHERE sql_id = '&SQL_ID' AND ROWNUM = 1; 
        
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Not found in Cursor Cache');
      END;

  if ( dbms_lob.getlength( myReport ) != 0 )
  Then
    dbms_output.put_line('Found  &SQL_ID in cursor cache.');
  ELSE 
        BEGIN
        select sql_text into myReport from dba_hist_sqltext where sql_id = '&SQL_ID' and rownum = 1; 
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Not found in AWR');
        END;
    IF ( dbms_lob.getlength( myReport ) != 0 )
    Then
      dbms_output.put_line('Found  &SQL_ID in AWR.');
    END IF;  
  END IF;

  IF ( dbms_lob.getlength( myReport ) != 0 )
  THEN
    --DBMS_OUTPUT.PUT_LINE( 'sql text >> #' || myReport || '#' );
    DBMS_OUTPUT.PUT_LINE( '>>'  );
    printCLOB( myReport );
    DBMS_OUTPUT.PUT_LINE( '>>'  );
  ELSE
    dbms_output.put_line('The sql text for &SQL_ID could not be found');
  END IF;

 

  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(Substr(SQLERRM,1,255));
    raise;
END;
/

undefine SQL_ID
undefine 1



/*
SELECT sql_id,piece, sql_text 
SELECT sql_text 
FROM v$sqltext_with_newlines 
WHERE sql_id = '&SQL_ID'
ORDER BY sql_id, piece;
*/

/*


column sql_text format A80;
define SQL_ID=&1;
set serveroutput on ;
declare

  sql_text_string  CLOB;

  CURSOR SQL_ID_CUR IS
         select sql_text from dba_hist_sqltext where sql_id = '&SQL_ID' ;

begin

  OPEN SQL_ID_CUR;
  FETCH  sql_id_cur into sql_text_string;

  DBMS_OUTPUT.PUT_LINE('SQL Text => #' || sql_text_string || '#');
end;

*/


undefine SQL_ID


