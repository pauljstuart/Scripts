----------------- creating a table using DBA_TAB_COLS ------------------------------

SET SERVEROUTPUT ON

SET SERVEROUTPUT ON
DECLARE
  starting      BOOLEAN      :=true;
  p_owner       VARCHAR2(64) := 'PERF_SUPPORT';
  p_target_name VARCHAR2(64) := 'PJS_TEST_33';
BEGIN
  DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || p_target_name || ' (' );
  FOR r IN
  (
    SELECT
      '"'
      || column_name
      || '"' AS column_name,
      data_type,
      data_length,
      data_precision,
      data_scale,
      data_default,
      nullable
    FROM
      all_tab_colS
    WHERE
      table_name = p_target_name
    AND owner    = p_owner
    ORDER BY
      column_id
  )
  LOOP
    IF starting THEN
      starting:=false;
    ELSE
      dbms_output.put_line(',');
    END IF;
    IF r.data_type          ='NUMBER' THEN
      IF (r.data_precision IS NULL) THEN
        dbms_output.put(r.column_name||' NUMBER ');
      ELSE
        IF (r.data_scale IS NULL OR r.data_scale = 0) THEN
          dbms_output.put(r.column_name||' NUMBER('||r.data_precision||')');
        ELSE
          dbms_output.put(r.column_name||' NUMBER('||r.data_precision||','||r.data_scale||')');
        END IF;
      END IF;
    ELSE
      IF r.data_type = 'DATE' THEN
        dbms_output.put_line(r.column_name||' DATE');
      ELSE
        IF instr(r.data_type, 'CHAR') >0 THEN
          dbms_output.put(r.column_name||' '||r.data_type||'('||r.data_length||')');
        ELSE
          dbms_output.put(r.column_name||' '||r.data_type);
        END IF;
      END IF;
    END IF;
    IF r.data_default IS NOT NULL THEN
      dbms_output.put(' DEFAULT '|| TRIM( trailing' '  FROM r.data_default ));
    END IF;
    IF r.nullable = 'N' THEN
      dbms_output.put(' NOT NULL ');
    END IF;
  END LOOP;
  dbms_output.put_line(' ); ');
  FOR i IN
  (
    SELECT
      '"'
      || a.column_name
      || '"' AS column_name
    FROM
      all_tab_cols a
    WHERE
      a.table_name      = p_target_name
    AND a.owner         = p_owner
    AND a.hidden_column = 'YES'
    ORDER BY
      a.internal_column_id
  )
  LOOP
    dbms_output.put_line( 'ALTER TABLE ' || p_owner || '.' || p_target_name || ' SET UNUSED (' || i.column_name || ');' );
  END LOOP;
END;
/

