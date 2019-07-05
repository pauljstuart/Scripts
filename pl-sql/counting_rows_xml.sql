
SELECT table_name, PARTITION_NAME, 
       TO_NUMBER (
          EXTRACTVALUE (
             xmltype (
                DBMS_XMLGEN.getxml ('select /*+ parallel(4) */ count(*) X from FBI_FDR_BALANCE.BALANCE PARTITION(' || partition_name || ')' )),
             '/ROWSET/ROW/X'))
          COUNT
  FROM dba_tab_partitions
WHERE table_owner = 'FBI_FDR_BALANCE'
AND TABLE_NAME = 'BALANCE';
