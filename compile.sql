
begin 
  	  	dbms_utility.compile_schema(
schema        => '&SCHEMA_TO_COMPILE' ,
compile_all   =>TRUE,
reuse_settings =>TRUE);
end;
        
