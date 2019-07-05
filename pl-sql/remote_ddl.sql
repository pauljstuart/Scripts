
------------------------------------------------------------------------------------------------------------------------------------------------------



CREATE OR REPLACE FUNCTION get_metadata_over_dblink(p_object_type VARCHAR2,
                                                    p_object_owner VARCHAR2, p_object_name VARCHAR2 )
  RETURN clob is

  doc      clob;
  v_schema VARCHAR2(30) ;
  h        number;
  th       number;

  partial NUMBER;
BEGIN
/*
  SELECT DISTINCT OWNER
    INTO v_schema
    FROM all_objects@TO_MERIVAL_MVDS_PRD
   where object_name = UPPER(pi_object_name)
     AND object_type = UPPER(pi_object_type);
*/
  
  h := DBMS_METADATA.OPEN@TO_MERIVAL_MVDS_PRD(UPPER(p_object_type));
  DBMS_METADATA.SET_FILTER@TO_MERIVAL_MVDS_PRD(h, 'SCHEMA', v_schema);
  DBMS_METADATA.SET_FILTEr@TO_MERIVAL_MVDS_PRD(h, 'NAME', UPPER(p_object_name));
  th := DBMS_METADATA.ADD_TRANSFORM@TO_MERIVAL_MVDS_PRD(h, 'MODIFY');
  th := DBMS_METADATA.ADD_TRANSFORM@TO_MERIVAL_MVDS_PRD(h, 'DDL');
  dbms_metadata.SET_TRANSFORM_PARAM@TO_MERIVAL_MVDS_PRD(th,
                                                'SEGMENT_ATTRIBUTES',
                                                false);
  LOOP
    BEGIN
      doc := doc ||
             to_cLOB(dbms_metadata.fetch_ddl_text@TO_MERIVAL_MVDS_PRD(h, partial));
      EXIT WHEN partial = 0;
    END;
  END LOOP;

  dbms_metadata.CLOSE@TO_MERIVAL_MVDS_PRD(h);
  return doc;

END get_metadata_over_dblink;


----------------------------------------------------------------------------------------------------------------------------------------------------------
