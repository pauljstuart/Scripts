set serveroutput on 
set feedback off

exec DBMS_OUTPUT.PUT_LINE ('Run this on the Standby');

exec DBMS_OUTPUT.PUT_LINE ('Thread 1...');



SELECT   MAX(L.SEQUENCE#) LAST_SEQ_SENT, MAX(R.SEQUENCE#) LAST_SEQ_RECD 
FROM V$ARCHIVED_LOG R, V$LOG L 
WHERE R.DEST_ID=2 AND L.ARCHIVED='YES' and r.thread# = 1  and l.thread# = 1;

exec DBMS_OUTPUT.PUT_LINE ('Thread 2...');

SELECT  max(L.SEQUENCE#) LAST_SEQ_SENT, MAX(R.SEQUENCE#) LAST_SEQ_RECD
FROM  V$ARCHIVED_LOG R, V$LOG L 
WHERE R.DEST_ID=2 AND L.ARCHIVED='YES' and r.thread# = 2 and l.thread# = 2;

exec DBMS_OUTPUT.PUT_LINE ('checking archive_gap...');

set feedback on

select * from v$archive_gap;

