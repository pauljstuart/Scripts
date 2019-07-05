

/*
  name : copyPartitionStats()
  written by : Paul Stuart
  Date : 14 June 2019
  Explanation :  Copies partition and subpartition statistics from source to target partition.
                 Updates global stats on the partitioning key

  Privileges required :
      object privileges : none
      system privileges : SELECT ANY DICTIONARY

*/



create or replace procedure copyPartitionStats (  p_tableOwner       in varchar2,
                                p_tableName        in varchar2,
                                 p_sourcePartition  in varchar2 default NULL,
                                 p_targetPartition  in varchar2,
                                 p_repDate          in  date     default NULL) 
is
      c_moduleName    varchar2(64) := 'copyPartitionStats';

      v_sourcePartition        user_tab_partitions.partition_name%type;
      v_sourceSubPartition        user_tab_subpartitions.partition_name%type;
      v_srec                   dbms_stats.statrec;                    -- used to hold and adjust partition column stat info
      v_distcnt                number;
      v_density                number;
      v_nullcnt                number;
      v_avgclen                number;

    i_ideal_num_rows  number;
    i_ideal_num_blocks  number;
    v_num_rows_default number := 1000000;
    v_num_blocks_default number := 500;

      s_part_column_name            user_part_key_columns.column_name%type := null;
      s_subpart_column_name         user_subpart_key_columns.column_name%type := null;
      s_part_datatype               user_tab_columns.data_type%TYPE := NULL;
      s_subpart_datatype            user_tab_columns.data_type%TYPE := NULL;
     i_date_number   NUMBER ;
     i_minDate NUMBER;
     i_maxDate NUMBER;
     s_minDate VARCHAR2(32);
     s_maxDate VARCHAR2(32);
     s_high_value VARCHAR2(256);
     s_date_string          varchar2(8);
     v_repDate                date;
      v_repDateRaw             raw(400);
      v_minDate                date;
      v_maxDate                date;
   i_subpartition_count number := 0;

begin

  OUTPUT_PKG.setup( p_log_level => 5 , p_process_name => 'CopyPartitionStats');
 
 OUTPUT_PKG.OUTPUT( 'beginning copyPartitionStats: p_tableName:'    || p_tableName  ||   ' p_tableOwner:'   || p_tableOwner  || ' p_targetPartition:' || p_targetPartition  ||  ' p_sourcePartition:' || p_sourcePartition    || ' p_repDate:'  || to_char(p_repDate,'DDMONYYYY') );
  -- version7
  -- get the name of the previous partition that has stats if no source partiton
  -- has been provided
  if p_sourcePartition is NULL then
     begin
            select partition_name
            into   v_sourcePartition
            from   dba_tab_partitions
            where  partition_position = (select max(s.partition_position)
                                         from   sys.dba_tab_partitions s
                                         where  s.last_analyzed is not null
                                         and    s.num_rows > 0 -- QC14051
                                         and    s.partition_position < (select partition_position
                                                                        from   sys.dba_tab_partitions
                                                                        where  table_name     = p_tableName
                                                                        and    table_owner    = p_tableOwner
                                                                        and    partition_name = p_targetPartition)
                                         and    s.table_name  = p_tableName
                                         and    s.table_owner = p_tableOwner)
            and table_name  = p_tableName
            and table_owner = p_tableOwner;
     exception
            when no_data_found then
               -- ignore but will need to perform a gather stats instead
               v_sourcePartition := NULL;
     end;
  else
         v_sourcePartition := p_sourcePartition;
  end if;


  -- if no source partiton was found then exit
  if v_sourcePartition is NULL then
         OUTPUT_PKG.OUTPUT('Unable to copy stats to [' || p_targetPartition || '].  No source partition specified');
         return;
  end if;

  OUTPUT_PKG.OUTPUT('Copying stats from partition [' || v_sourcePartition || '] to [' || p_targetPartition || ']');
  dbms_stats.copy_table_stats(ownname     => p_tableOwner,
                              tabname     => p_tableName,
                              srcpartname => v_sourcePartition,
                              dstpartname => p_targetPartition,
                                    force => true);

  -------------------------------------------------
   -- find partition and subpartition key types
  --------------------------------------------------

  BEGIN
    select PKC.column_name , data_type  into  s_part_column_name, s_part_datatype
    from dba_PART_KEY_COLUMNS PKC
    inner join dba_tab_columns T2 on T2.owner = PKC.owner and T2.table_name = PKC.name and T2.column_name = PKC.column_name
    where PKC.owner =  p_tableOwner and name = p_tableName and object_type = 'TABLE';
    OUTPUT_PKG.OUTPUT('Partition column name : ' || s_part_column_name || ' Partition data type : ' || s_part_datatype );
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
              OUTPUT_PKG.OUTPUT('Table ' || p_tableName || ' is not partitioned');
              RETURN;
  END;
  BEGIN
    select PKC.column_name , data_type  into  s_subpart_column_name, s_subpart_datatype
    from dba_subpart_key_columns PKC
    inner join dba_tab_columns T2 on T2.owner = PKC.owner and T2.table_name = PKC.name and T2.column_name = PKC.column_name
    where PKC.owner =  p_tableOwner and name = p_tableName and object_type = 'TABLE';
    OUTPUT_PKG.OUTPUT('Table ' || p_tableName || ' is a subpartitioned table, subpart key is ' || s_subpart_column_name || ' datatype ' || s_subpart_datatype );

  EXCEPTION
      WHEN NO_DATA_FOUND THEN
              OUTPUT_PKG.OUTPUT('Table ' || p_tableName || ' is not subpartitioned');
  END;



  --------------------------------------------------
  -- Find the target date, in all 3 datatypes
  --------------------------------------------------
  IF
        p_repdate IS NULL
  THEN
        s_date_string := regexp_substr(p_targetpartition,q'#([0-9]{8,8})#',1,1,'i',1);
        v_repdate := TO_DATE(s_date_string,'YYYYMMDD');
        i_date_number := to_number(s_date_string);
  ELSE
        v_repdate := p_repdate;
        i_date_number := to_number(TO_CHAR(p_repdate,'YYYYMMDD') );
        s_date_string := TO_CHAR(i_date_number);
  END IF;

  IF s_date_string is NULL
  THEN
         OUTPUT_PKG.OUTPUT( 'Unable to fix partition stats on [' || p_targetPartition || '].  no p_repDate parameter specified, and could not extract date from target partition name');
         RETURN;
  ELSE
         OUTPUT_PKG.OUTPUT('The target date in date format is : ' || v_repDate || ', in number format : ' || i_date_number || ', in string format : ' || s_date_string );
  END IF;


  ----------------------------------------------------------------
  -- Now deal with the global table level stats
  -----------------------------------------------------------------

  IF ( s_part_datatype = 'DATE' )
    THEN
    OUTPUT_PKG.OUTPUT('Setting global stats on DATE column ' || s_part_column_name );
    -- use dbms_stats functionality to get the raw value representation of the partition date
    v_srec.epc := 2;  -- min and max
    dbms_stats.prepare_column_values(v_srec, dbms_stats.datearray(v_repDate, v_repDate));
    v_repDateRaw := v_srec.minval;

    dbms_stats.get_column_stats(ownname => p_tableOwner,
                               tabname  => p_tableName,
                               colname  => s_part_column_name,
                               distcnt  => v_distcnt,
                               density  => v_density,
                               nullcnt  => v_nullcnt,
                               srec     => v_srec,
                               avgclen  => v_avgclen);

    dbms_stats.convert_raw_value(v_srec.minval, v_minDate);
    dbms_stats.convert_raw_value(v_srec.maxval, v_maxDate);
    -- remove histograms
    v_srec.epc := 2;
    v_srec.bkvals := null;
    dbms_stats.prepare_column_values(v_srec, dbms_stats.datearray(v_minDate, v_maxDate));
    IF  v_repDate < v_minDate
           THEN
           v_srec.minval := v_repDateRaw;
          dbms_stats.prepare_column_values(v_srec, dbms_stats.datearray(v_repDate, v_maxDate));
    ELSIF v_repDate > v_maxDate
           THEN
            v_srec.maxval    := v_repDateRaw;
           dbms_stats.prepare_column_values(v_srec, dbms_stats.datearray(v_minDate, v_repDate));
    END IF;

    dbms_stats.set_column_stats(ownname  => p_tableOwner,
                                tabname  => p_tableName,
                                colname  => s_part_column_name,
                                distcnt  => v_distcnt,
                                density  => v_density,
                                nullcnt  => v_nullcnt,
                                avgclen  => v_avgclen,
                                srec     => v_srec,
                           no_invalidate => false);
  END IF;


  IF ( s_part_datatype = 'NUMBER' )
    THEN
    OUTPUT_PKG.OUTPUT('Setting global stats on NUMBER column ' || s_part_column_name );
    -- use dbms_stats functionality to get the raw value representation of the partition date
    v_srec.epc := 2;
    dbms_stats.prepare_column_values(v_srec, dbms_stats.numarray(i_date_number, i_date_number));
    v_repDateRaw := v_srec.minval;
    dbms_stats.get_column_stats(
              ownname     => p_tableOwner,
              tabname     => p_tableName,
              colname     => s_part_column_name,
              distcnt     => v_distcnt,
              density     => v_density,
              nullcnt     => v_nullcnt,
              srec        => v_srec,
              avgclen     => v_avgclen
    );

    dbms_stats.convert_raw_value(v_srec.minval, i_minDate);
    dbms_stats.convert_raw_value(v_srec.maxval, i_maxDate);
    -- remove histogram
    v_srec.epc := 2;
    v_srec.bkvals := null;
    dbms_stats.prepare_column_values(v_srec,  dbms_stats.numarray(  i_minDate,  i_maxDate    ) );
    IF  i_date_number < i_minDate
           THEN
           v_srec.minval := v_repDateRaw;
           dbms_stats.prepare_column_values(v_srec,  dbms_stats.numarray(  i_date_number,  i_maxDate    ) );
    ELSIF i_date_number > i_maxDate
           THEN
            v_srec.maxval    := v_repDateRaw;
            dbms_stats.prepare_column_values(v_srec,  dbms_stats.numarray(  i_minDate,  i_date_number    ) );
    END IF;

    dbms_stats.set_column_stats(
              ownname     => p_tableOwner,
              tabname     => p_tableName,
              colname     => s_part_column_name,
              distcnt     => v_distcnt,
              density     => v_density,
             nullcnt     => v_nullcnt,
              srec        => v_srec,
              avgclen     => v_avgclen
    );

  END IF;




  IF ( s_part_datatype = 'VARCHAR2' )
    THEN
          OUTPUT_PKG.OUTPUT('Setting global stats on VARCHAR2 column ' || s_part_column_name );
          v_srec.epc := 2;
          dbms_stats.prepare_column_values(v_srec, dbms_stats.chararray(s_date_string, s_date_string));
          v_repDateRaw := v_srec.minval;
          dbms_stats.get_column_stats(
                    ownname     => p_tableOwner,
                    tabname     => p_tableName,
                    colname     => s_part_column_name,
                    distcnt     => v_distcnt,
                    density     => v_density,
                    nullcnt     => v_nullcnt,
                    srec        => v_srec,
                    avgclen     => v_avgclen
          );
          dbms_stats.convert_raw_value(v_srec.minval, s_minDate);
          dbms_stats.convert_raw_value(v_srec.maxval, s_maxDate);
          -- remove histograms
          v_srec.epc := 2;
          v_srec.bkvals := null;
          dbms_stats.prepare_column_values(v_srec,   dbms_stats.chararray(  s_minDate,  s_maxDate    ));
          IF to_number(s_date_string) < to_number(s_minDate)
               THEN
               v_srec.minval := v_repDateRaw;
               dbms_stats.prepare_column_values(v_srec,   dbms_stats.chararray(  s_date_string,  s_maxDate    ));
          ELSIF to_number(s_date_string) > to_number(s_maxDate)
               THEN
                v_srec.maxval    := v_repDateRaw;
                dbms_stats.prepare_column_values(v_srec,   dbms_stats.chararray(  s_minDate,  s_date_string    ));
          END IF;

          dbms_stats.set_column_stats(
                    ownname     => p_tableOwner,
                    tabname     => p_tableName,
                    colname     => s_part_column_name,
                    distcnt     => v_distcnt,
                    density     => v_density,
                    nullcnt     => v_nullcnt,
                    srec        => v_srec,
                    avgclen     => v_avgclen
          );
  END IF;


  -- global  stats done.

  ------------------------------------------------------------------------------------------------------------------------------------
  --- Setting stats on the PARTITION KEY column, at the partition level :
  ------------------------------------------------------------------------------------------------------------------------------------

  IF ( s_part_datatype = 'NUMBER' OR s_part_datatype = 'VARCHAR2' OR s_part_datatype = 'DATE' )
      THEN
      -- now setup the PARTITION_KEY  column stats, on the *target* partition
      -- this is necessary, cause the copyPartitionStas() procedure doesn't seem to set them correctly
       -- remove any histogram, and set the min and max values to the same date
      dbms_stats.get_column_stats(
          ownname     => p_tableOwner,
          tabname     => p_tableName,
          partname    => p_targetPartition,
          colname     => s_part_column_name,
          distcnt     => v_distcnt,
          density     => v_density,
          srec        => v_srec,
          nullcnt     => v_nullcnt,
          avgclen     => v_avgclen
      );
       v_srec.epc := 2;
       v_density := 1.0;
       v_distcnt := 1;
       v_srec.bkvals := null;
      OUTPUT_PKG.OUTPUT('Setting partition stats on partition key column ' || s_part_column_name );
       CASE s_part_datatype
         WHEN 'NUMBER' THEN   dbms_stats.prepare_column_values(v_srec, dbms_stats.numarray(  i_date_number,  i_date_number    ));
         WHEN 'VARCHAR2' THEN dbms_stats.prepare_column_values(v_srec, dbms_stats.chararray( s_date_string ,   s_date_string    ));
         WHEN 'DATE' THEN dbms_stats.prepare_column_values(v_srec, dbms_stats.datearray( v_repDate, v_repDate  ));
       END CASE;
       dbms_stats.set_column_stats(
              ownname     => p_tableOwner,
              tabname     => p_tableName,
              partname    => p_targetPartition,
              colname     => s_part_column_name,
              distcnt     => v_distcnt,
              density     => v_density,
              srec        => v_srec
       );
  END IF;


  ------------------------------------------------------------------------------------------------------------------------------------
  --- Setting stats on the SUBPARTITION KEY column, first at the partition level :
  ------------------------------------------------------------------------------------------------------------------------------------

    IF ( s_subpart_datatype = 'NUMBER'   )
      THEN
                OUTPUT_PKG.OUTPUT('Setting partition stats on subpartition key column : ' || s_subpart_column_name );
                -- now setup the column stats on the subpartition key column, but at the partition level, on the *target* partition :
                dbms_stats.get_column_stats(
                    ownname     => p_tableOwner,
                    tabname     => p_tableName,
                    partname    => p_targetPartition,
                    colname     => s_subpart_column_name,
                    distcnt     => v_distcnt,
                    density     => v_density,
                    nullcnt     => v_nullcnt,
                    srec        => v_srec,
                    avgclen     => v_avgclen
                );
               -- remove the partition-level histogram, and set the min and max values : this is the most important part :
                v_srec.bkvals := null;
                v_srec.epc := 2;
                v_density := 0.25;
               CASE s_subpart_datatype
                 WHEN 'NUMBER' THEN     dbms_stats.prepare_column_values(v_srec,   dbms_stats.numarray( 0,   999999999    )    );
               END CASE;

                dbms_stats.set_column_stats(
                    ownname     => p_tableOwner,
                    tabname     => p_tableName,
                    partname    => p_targetPartition,
                    colname     => s_subpart_column_name,
                    distcnt     => v_distcnt,
                    density     => v_density,
                    nullcnt     => v_nullcnt,
                    srec        => v_srec,
                    avgclen     => v_avgclen
                );
    END IF;





  ------------------------------------------------------------------------------------------------------------------------------------
  --- This section copies the subpartition stats, from the source to the target
  ------------------------------------------------------------------------------------------------------------------------------------
  IF ( s_subpart_datatype = 'NUMBER'  OR s_subpart_datatype = 'VARCHAR2')
    THEN
    OUTPUT_PKG.OUTPUT('Copying subpartition stats for subpartition key column : ' || s_subpart_column_name );
    -- now try and find an ideal subpartition that has a good number of rows in it :
    select subpartition_name  , num_rows, blocks into v_sourceSubPartition, i_ideal_num_rows, i_ideal_num_blocks
    from
    (
                    select SUBPARTITION_NAME, SUBPARTITION_POSITION, NUM_ROWS, BLOCKS, RANK() over (order by num_rows desc) as rank_col
                    from dba_tab_subpartitions
                    where table_owner = p_tableOwner
                    and table_name = p_tableName
                    and partition_name = v_sourcePartition
    ) where rank_col = 1 and rownum = 1;
    -- now, decide if this subpartition is ideal (ie has a decent about of data in it)
    IF (i_ideal_num_rows < 50000 or i_ideal_num_rows is null)
    THEN
          OUTPUT_PKG.OUTPUT('Could not find a suitable ideal subpartition in ' || v_sourcePartition || '.  Using default values');
          i_ideal_num_rows := v_num_rows_default;
          i_ideal_num_blocks := v_num_blocks_default;
    ELSE
         OUTPUT_PKG.OUTPUT('We have a winner - subpartition ' || v_sourceSubPartition || ' : max number of rows = ' || i_ideal_num_rows || ' and max blocks : ' || i_ideal_num_blocks);
    END IF;
                -- now iterating through all target subpartitions, and set or copy the stats
                FOR C2 IN (SELECT TABLE_NAME, subpartition_name,subpartition_position from dba_tab_subpartitions where table_owner =  p_tableOwner and table_name = p_tableName and partition_name = p_targetPartition )
                       LOOP
                       i_subpartition_count := i_subpartition_count + 1;
                       DBMS_APPLICATION_INFO.SET_MODULE('subpart :' || p_tableName || '.' || p_targetPartition  , C2.subpartition_name || ' subpart ' || C2.subpartition_position );
                       IF ( i_ideal_num_rows = v_num_rows_default)
                       THEN
                           -- now set the num_rows and blocks to the default values
                          -- OUTPUT_PKG.OUTPUT('Setting subpart stats on ' || C2.subpartition_name   );
                           dbms_stats.set_table_stats(ownname  => p_tableOwner,
                                                     tabname  => p_tableName,
                                                     partname => C2.subpartition_name,
                                                     numrows  => i_ideal_num_rows,
                                                     numblks => i_ideal_num_blocks);
                       ELSE
                           -- in this case we use our ideal subpartition, identified earlier, and copy that from source to target
                          -- OUTPUT_PKG.OUTPUT('Copying subpart column stats onto ' || C2.subpartition_name );
                           dbms_stats.copy_table_stats(ownname     => p_tableOwner,
                                                   tabname     => p_tableName,
                                                   srcpartname => v_sourceSubPartition,
                                                   dstpartname => C2.subpartition_name
                                                   );
                       END IF;
                       -- now setup the SUBPARTITION_KEY column stats, on the *target* subpartition :
                      --OUTPUT_PKG.OUTPUT('Setting subpart column stats on ' || C2.subpartition_name || ' column : ' || s_subpart_column_name );
                       -- remove any histogram, and set the min and max values
                       CASE s_subpart_datatype
                         WHEN 'NUMBER' THEN   dbms_stats.prepare_column_values(v_srec, dbms_stats.numarray(  0,   9999999999    ));
                          WHEN 'VARCHAR2' THEN
                                SELECT   high_value  into s_high_value
                                FROM dba_tab_subpartitions
                                where  table_owner = p_tableOwner
                                and    table_name = p_tableName
                                and subpartition_name = C2.subpartition_name;
                                s_high_value := replace(s_high_value,'''', null);
                                dbms_stats.prepare_column_values(v_srec, dbms_stats.chararray( s_high_value ,   s_high_value    ));
                       END CASE;
                      -- v_srec.bkvals := null;
                       v_srec.epc := 2;
                       v_distcnt := 1;
                       v_density := 1.0;
                       dbms_stats.set_column_stats(
                              ownname     => p_tableOwner,
                              tabname     => p_tableName,
                              partname    => C2.subpartition_name,
                              colname     => s_subpart_column_name,
                              distcnt     => v_distcnt,
                              density     => v_density,
                              nullcnt     => v_nullcnt,
                              srec        => v_srec,
                              avgclen     => v_avgclen
                       );
                       -- now setup the PARTITION_KEY  column stats, on the *target* subpartition
                       -- this is necessary, cause the copyPartitionStas() procedure doesn't seem to set them correctly
                       CASE s_part_datatype
                         WHEN 'NUMBER' THEN   dbms_stats.prepare_column_values(v_srec, dbms_stats.numarray(  i_date_number,  i_date_number    ));
                         WHEN 'VARCHAR2' THEN dbms_stats.prepare_column_values(v_srec, dbms_stats.chararray( s_date_string ,   s_date_string    ));
                         WHEN 'DATE' THEN dbms_stats.prepare_column_values(v_srec, dbms_stats.datearray( v_repDate, v_repDate  ));
                       END CASE;
                       -- remove any histogram, and set the min and max values to the same date
                       --v_srec.bkvals := null;
                       v_srec.epc := 2;
                       v_density := 1.0;
                       v_distcnt := 1;
                       dbms_stats.set_column_stats(
                              ownname     => p_tableOwner,
                              tabname     => p_tableName,
                              partname    => C2.subpartition_name,
                              colname     => s_part_column_name,
                              distcnt     => v_distcnt,
                              density     => v_density,
                              nullcnt     => v_nullcnt,
                              srec        => v_srec,
                              avgclen     => v_avgclen
                       );
                       DBMS_APPLICATION_INFO.SET_MODULE(NULL, NULL);

                       END LOOP;
                       IF ( i_ideal_num_rows = v_num_rows_default)
                       THEN
                           OUTPUT_PKG.OUTPUT('Set subpartition stats for ' || i_subpartition_count || ' subpartitions ');
                       ELSE
                         OUTPUT_PKG.OUTPUT('Copied subpartition stats for ' || i_subpartition_count || ' subpartitions ');
                       END IF;
     END IF;
     ------------------------------------------------------------------------------------------------------------------------------------
     --- end of subpartition stats section
     ------------------------------------------------------------------------------------------------------------------------------------

    OUTPUT_PKG.OUTPUT('copyPartitionStats End');
     exception
         when others then
            OUTPUT_PKG.OUTPUT( 'Error : ' || SQLCODE || ' - ' || SQLERRM  );
            raise;
   end copyPartitionStats;
