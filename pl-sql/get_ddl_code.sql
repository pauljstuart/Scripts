


set serveroutput on
declare

   c_ddl CLOB;
   i_linecount INTEGER;
   i_thisline integer;
   i_endofline INTEGER;
   i_lengthofline INTEGER;
   s_oneline varchar2(32767);
   
   offset INTEGER := 1;
begin

  DBMS_OUTPUT.ENABLE (buffer_size => NULL); 
  dbms_metadata.set_transform_param (dbms_metadata.session_transform,'STORAGE',false);
       dbms_metadata.set_transform_param (dbms_metadata.session_transform,'TABLESPACE',false);
       dbms_metadata.set_transform_param (dbms_metadata.session_transform,'SEGMENT_ATTRIBUTES', false);
       dbms_metadata.set_transform_param (dbms_metadata.session_transform,'REF_CONSTRAINTS', false);
       dbms_metadata.set_transform_param (dbms_metadata.session_transform,'CONSTRAINTS', false);
       dbms_metadata.set_transform_param (dbms_metadata.session_transform,'PARTITIONING', false);

 
c_ddl := dbms_metadata.get_ddl(  object_type => 'TABLE', name => 'ICDCAP', schema => 'MVDS');

select regexp_count(c_ddl, chr (10)) into i_linecount from dual;

dbms_output.put_line('Number of lines is ' || i_linecount);

for i_thisline IN 1..i_linecount+1
LOOP

  if (i_thisline = i_linecount+1) -- last line situation
  then
    i_endofline :=  dbms_lob.getlength(c_ddl);
  else
    i_endofline := DBMS_LOB.INSTR( c_ddl, chr(10), 1 , i_thisline  );
  end if;
 
  i_lengthofline := greatest(i_endofline - offset, 1);

  dbms_lob.read(c_ddl, i_lengthofline, offset, s_oneline);
  dbms_output.put_line( s_oneline);
  offset := i_endofline+1;
END LOOP;


END;
/

desc mvds.ICDCAP;
 

   
   select dbms_metadata.get_ddl ('TABLE', 'ICDCAP', 'MVDS')
      from dual
    /

@who





declare
   h   number; --handle returned by OPEN
   th  number; -- handle returned by ADD_TRANSFORM
   doc clob;
begin
   -- Specify the object type.
   h := dbms_metadata.open('TABLE');
   -- Use filters to specify the particular object desired.
   dbms_metadata.set_filter(h
                           ,'SCHEMA'
                           ,'MVDS');
   dbms_metadata.set_filter(h
                           ,'NAME'
                           ,'ICDCAP');
   -- Request that the schema name be modified.
  /*
   th := dbms_metadata.add_transform(h
                                    ,'MODIFY');
   dbms_metadata.set_remap_param(th
                                ,'REMAP_SCHEMA'
                                ,'ALEX'
                                ,null);
  */
   -- Request that the metadata be transformed into creation DDL.
   th := dbms_metadata.add_transform(h
                                    ,'DDL');
   -- Specify that segment attributes are not to be returned.
       dbms_metadata.set_transform_param(th,'SEGMENT_ATTRIBUTES'   ,false);
       dbms_metadata.set_transform_param(th,'STORAGE',false);
       dbms_metadata.set_transform_param (th,'TABLESPACE',false);
       dbms_metadata.set_transform_param (th, 'SEGMENT_ATTRIBUTES', false);
       dbms_metadata.set_transform_param (th, 'REF_CONSTRAINTS', false);
       dbms_metadata.set_transform_param (th,'CONSTRAINTS', false);
       dbms_metadata.set_transform_param (th,'PARTITIONING', false);

   -- Fetch the object.
   doc := dbms_metadata.fetch_clob(h);
   -- Release resources.
   dbms_metadata.close(h);
end;
/

 



   
   
   
