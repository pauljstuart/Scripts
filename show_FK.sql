


define FOREIGN_CONSTRAINT_NAME=&1;

COLUMN constraint_source FORMAT A70 HEADING "Constraint Name: (Table.Column)"
COLUMN  references_column FORMAT A70 HEADING "References: (Table.Column)"

prompt
prompt &FOREIGN_CONSTRAINT_NAME
prompt

SELECT   uc.constraint_name  ||    ' ('||ucc1.TABLE_NAME||'.'||ucc1.column_name||')' constraint_source
        ,       'REFERENCES: '|| ucc2.owner || ' ('||ucc2.TABLE_NAME||'.'||ucc2.column_name||')' references_column,
        ucc2.constraint_name PARENT_KEY_NAME
FROM     all_constraints uc
,        all_cons_columns ucc1
,        all_cons_columns ucc2
WHERE    uc.constraint_name = ucc1.constraint_name
AND      uc.r_constraint_name = ucc2.constraint_name
AND      ucc1.POSITION = ucc2.POSITION -- Correction for multiple column primary keys.
AND      uc.constraint_type = 'R'
AND      uc.constraint_name like UPPER('&FOREIGN_CONSTRAINT_NAME')
ORDER BY ucc1.TABLE_NAME
,        uc.constraint_name;
