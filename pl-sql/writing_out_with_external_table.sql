
Writing to an external table from an Oracle database takes about 16 min for 40 million rows the first time.
mvdss1> CREATE TABLE post_ext_datapump
  2  ORGANIZATION EXTERNAL
  3   (TYPE ORACLE_DATAPUMP DEFAULT DIRECTORY EXT_DIR_SBCIMP
  4     ACCESS PARAMETERS
  5      (LOGFILE EXT_DIR_SBCIMP:'POSTING_RJS_ext_via_datapump.log')
  6      LOCATION (EXT_DIR_SBCIMP:'POSTING_RJS_ext_via_datapump.dat')
  7   )
  8  as select /*+ parallel(16) */ * from PERF_SUPPORT.POSTING_RJS
  9  ;
Table created.
Elapsed: 00:16:26.00
