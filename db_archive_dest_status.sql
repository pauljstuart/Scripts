
/*
Determine the most recent archived redo log file at each destination.

Enter the following query on the primary database to determine which archived redo 
log file was most recently transmitted to each of the archiving destinations:
*/

column destination format A50;
column dest_name format A30;
column error format A50;

clear screen


prompt
prompt Run this query on the primary
prompt


prompt "Primary :"

SELECT MAX(SEQUENCE#), THREAD# FROM V$ARCHIVED_LOG GROUP BY THREAD#;



prompt "Standbys :"

--SELECT DESTINATION, STATUS, ARCHIVED_THREAD#, ARCHIVED_SEQ#, *
select * 
FROM V$ARCHIVE_DEST_STATUS
WHERE STATUS <> 'DEFERRED' AND STATUS <> 'INACTIVE';


/*

DESTINATION         STATUS  ARCHIVED_THREAD#  ARCHIVED_SEQ#
------------------  ------  ----------------  -------------
/private1/prmy/lad   VALID                 1            947
standby1             VALID                 1            947

*/
