CREATE TABLE t1
(c1    NUMBER,
 c2    NUMBER,
 c3    VARCHAR2(50),
 c4    VARCHAR2(50),
 c5    DATE,
 c6    DATE)
compress for query high;
 
DECLARE
  -- Define a collection
  TYPE t1_tbl_type IS TABLE OF t1%ROWTYPE;
  t1_tbl    t1_tbl_type := t1_tbl_type();
BEGIN
 
  -- Populate the collection
  FOR i IN 1..32000 LOOP
    t1_tbl.EXTEND;
    t1_tbl(i).c1 := i;
    t1_tbl(i).c2 := i*i;
    t1_tbl(i).c3 := 'i=' || TO_CHAR(i);
    t1_tbl(i).c4 := 'i*i=' || TO_CHAR(i*i);
    t1_tbl(i).c5 := SYSDATE;
    t1_tbl(i).c6 := SYSDATE;
  END LOOP;
 
  -- Bulk Insert the collection into table T1
  FORALL i IN 1..t1_tbl.COUNT
    INSERT /*+ append_values */ INTO t1
      (c1,
       c2,
       c3,
       c4,
       c5,
       c6)
    VALUES
      (t1_tbl(i).c1,
       t1_tbl(i).c2,
       t1_tbl(i).c3,
       t1_tbl(i).c4,
       t1_tbl(i).c5,
       t1_tbl(i).c6);
 
END;
/
