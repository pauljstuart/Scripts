

SET AUTOTRACE OFF           - switch AUTOTRACE OFF
SET AUTOTRACE ON EXPLAIN    - show only the optimizer execution path
SET AUTOTRACE ON STATISTICS - show only the execution statistics
SET AUTOTRACE ON            - show both the optimizer execution path
                              and execution statistics
SET AUTOTRACE TRACEONLY     - like SET AUTOTRACE ON, but suppress output (use when large result sets expected)

set autotrace on statistics;



alter session set tracefile_identifier="paul";


BEGIN

DBMS_SESSION.SET_IDENTIFIER ( client_id => 'TLM_301');
DBMS_SESSION.SESSION_TRACE_ENABLE( waits => TRUE,binds => TRUE);
DBMS_SESSION.SESSION_TRACE_DISABLE( );

END;
/
