create or replace package utdirectory as

  type file_record is record
  (
    directory_name  varchar( 30 char ),
    file_name       varchar( 4000 char )
  );

  type file_table is table of file_record;

  function list( p_directory in varchar ) return file_table pipelined;


  type content_record is record
  (
    directory_name  varchar( 30 char ),
    file_name       varchar( 4000 char ),
    line            integer,
    text            varchar( 4000 char )
  );

  type content_table is table of content_record;

  function content( p_directory in varchar, p_file in varchar ) return content_table pipelined;

end;



create or replace package body utdirectory as

  function list( p_directory in varchar ) return file_table pipelined
  is

    l_pattern varchar( 4000 );
    l_ns      varchar( 4000 );
    l_record  file_record := null;

  begin

    for l_directory in
    (
      select  directory_name,
              directory_path
      from    dba_directories

      where   directory_name = upper( trim( p_directory ) )
    )
    loop

      l_pattern := l_directory.directory_path;

      sys.dbms_backup_restore.searchfiles( l_pattern, l_ns );

      for l_file in
      (
        select  fname_krbmsft as file_name
        from    sys.v_x$krbmsft

        -- FIXME: hack to exclude subdirectories...
        where   instr( fname_krbmsft, '/', length( l_directory.directory_path ) + 2 ) = 0
      )
      loop

        l_record.directory_name := l_directory.directory_name;
        l_record.file_name := substr( l_file.file_name, length( l_directory.directory_path ) + 2 );

        pipe row( l_record );

      end loop;

    end loop;

  end list;


  function content( p_directory in varchar, p_file in varchar ) return content_table pipelined
  is

    l_directory varchar( 30 ) := upper( trim( p_directory ) );
    l_file      utl_file.file_type := null;
    l_record    content_record := null;
    l_index     integer := 0;

  begin

    l_file := utl_file.fopen( l_directory, p_file, 'r' );
    if not utl_file.is_open( l_file ) then raise no_data_found; end if;

    l_record.directory_name := l_directory;
    l_record.file_name := p_file;

    loop

      utl_file.get_line( l_file, l_record.text, 4000 );

      l_index := l_index + 1;
      l_record.line := l_index;

      pipe row( l_record );

    end loop;

  exception

    when no_data_found then utl_file.fclose( l_file );
    when utl_file.invalid_operation then null;

  end content;

end;
