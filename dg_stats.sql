

COLUMN NAME FORMAT A18
COLUMN VALUE FORMAT A16
COLUMN TIME_COMPUTED FORMAT A24

clear screen



prompt
prompt Dataguard_status :
prompt

alter session set NLS_DATE_FORMAT='DD-MON-YY HH24:MI';

column message_num format 999 heading "messnum";
column dest_id format 999
column message format A100
column severity format A4 truncated
column facility format A15 truncated
column error_code format 999 truncated heading "ERR";
column timestamp format A20;

column dest_id format 999 heading "Dest";

select * from v$dataguard_status;


prompt
prompt Dataguard_stats (run on standby) :
prompt


SELECT * FROM V$DATAGUARD_STATS;

