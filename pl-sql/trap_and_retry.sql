

declare

 cursor_invalidated   EXCEPTION;  
PRAGMA EXCEPTION_INIT (cursor_invalidated, -12842);  
v_number_of_tries    INTEGER;     
  
BEGIN  
  

   DBMS_OUTPUT.put_line(insert_str || select_str || validity_str);  
     
EXECUTE IMMEDIATE (insert_str || select_str || validity_str);  
v_number_of_tries := 1;  

WHILE (v_number_of_tries < 10)  
LOOP  
   BEGIN  
      EXECUTE IMMEDIATE (insert_str || select_str || validity_str);  

      EXIT;  
   EXCEPTION  
      WHEN cursor_invalidated  
      THEN  
         DBMS_OUTPUT.PUT_LINE ('Caught a cursor invalidated error');  
         v_number_of_tries := v_number_of_tries + 1;  
         CONTINUE;  
   END;  
END LOOP;  


end;

