--
-- old code to read out the file using UTL_FILE
--


DECLARE

  into l_trace_file_name VARCHAR2(1024);

BEGIN


-- this query includes the full path

  select c.value || '/' || instance || '_ora_' || ltrim(to_char(a.spid,'fm99999')) || '_PJS_&SQL_ID' || '.trc' into l_trace_file_name
    from v$process a, v$session b, v$parameter c, v$thread c
    where a.addr = b.paddr
    and b.audsid = userenv('sessionid')
    and c.name = 'user_dump_dest'
    and c.instance = (select instance_name from v$instance);


  select  instance || '_ora_' || ltrim(to_char(a.spid,'fm99999')) || '_PJS_&SQL_ID' || '.trc' into l_trace_file_name
  from v$process a, v$session b, v$parameter c, v$thread c
  where a.addr = b.paddr
     and b.audsid = userenv('sessionid')
     and c.name = 'user_dump_dest'
     and c.instance = (select instance_name from v$instance);



  dbms_output.put_line('trace created in : ' || l_trace_file_name );
  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
  l_input := utl_file.fopen( 'SQLT$STAGE', l_trace_file_name, 'r', 32760 );

  
    loop
    begin
            utl_file.get_LINE( l_input, l_buffer, 32760 );
            dbms_output.put_line(l_buffer  );

        exception
            when no_data_found then exit;
        end;


     end loop;
 


   utl_file.fclose( l_input );


END;

