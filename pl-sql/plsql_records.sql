

DECLARE
-- Declare a record type with 3 fields.
  TYPE rec1_t IS RECORD (field1 VARCHAR2(16), field2 NUMBER, field3 DATE);
-- For any fields declared NOT NULL, we must supply a default value.
  TYPE rec2_t IS RECORD (id INTEGER NOT NULL := -1,  name VARCHAR2(64) NOT NULL := '[anonymous]');
-- Declare record variables of the types declared
  rec1 rec1_t;
  rec2 rec2_t;
-- Declare a record variable that can hold a row from the EMPLOYEES table.
-- The fields of the record automatically match the names and 
-- types of the columns.
-- Don't need a TYPE declaration in this case.
  rec3 employees%ROWTYPE;

BEGIN
-- Read and write fields using dot notation
  rec1.field1 := 'Yesterday';
  rec1.field2 := 65;
  rec1.field3 := TRUNC(SYSDATE-1);
-- We didn't fill in the name field, so it takes the default value declared
  DBMS_OUTPUT.PUT_LINE(rec2.name);
END;
/



Example 5-44 Returning a Record from a Function
DECLARE
   TYPE EmpRecTyp IS RECORD (
     emp_id       NUMBER(6),
     salary       NUMBER(8,2));
   CURSOR desc_salary RETURN EmpRecTyp IS
      SELECT employee_id, salary FROM employees ORDER BY salary DESC;
   emp_rec     EmpRecTyp;
   FUNCTION nth_highest_salary (n INTEGER) RETURN EmpRecTyp IS
   BEGIN
      OPEN desc_salary;
      FOR i IN 1..n LOOP
         FETCH desc_salary INTO emp_rec;
      END LOOP;
      CLOSE desc_salary;
      RETURN emp_rec;
   END nth_highest_salary;
BEGIN
   NULL;
END;
/

