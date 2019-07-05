set echo off

-- +----------------------------------------------------------------------------+
-- | Filename	:  blocking_sess_tree.sql  
-- | Owner	:  DBA Team, MarkitServ London
-- | Purpose	:  Print out the wait-for graph in a tree structured fashion.
-- |               This is useful for diagnosing systems that are hung on
-- |               locks.
-- |
-- | Notes	:  The script is "RAC aware" and will show intra-instance
-- |               blockers and waiters.
-- |
-- |----------------------------------------------------------------------------
-- | Revision History:
-- |
-- | Ver  Date             Name            Change
-- | 1.0  26 May 2012      Austin Hackett  Initial Build
-- |
-- +----------------------------------------------------------------------------+


COLUMN current_db NEW_VALUE current_db NOPRINT;
SELECT rpad(name, 11) current_db FROM v$database;


COL waiter       FOR a14     HEAD "InstNum.Sid"
COL serial#      FOR 9999999 HEAD "Serial#"
COL username     FOR a15     HEAD "Username"    TRUNC
COL machine      FOR a10     HEAD "Machine"     TRUNC
COL module       FOR a30     HEAD "Module"      TRUNC
COL event        FOR a30     HEAD "Event"       TRUNC
COL secs         FOR 99999   HEAD "Secs"
COL command_name FOR a6      HEAD "Action"      TRUNC
COL obj          FOR a30     HEAD "Object"      TRUNC
COL sql_id       FOR a13     HEAD "SQL ID"

PROMPT 
PROMPT +------------------------------------------------------------------------+
PROMPT | Report   : Blocking Session Tree                                       |
PROMPT | Database : &current_db                                                 |
PROMPT +------------------------------------------------------------------------+



WITH sessions AS
  (SELECT
    /*+ MATERIALIZE */
    inst_id
    || '.'
    || sid waiter,
    DECODE (blocking_session, NULL, NULL, blocking_instance
    ||'.'
    || blocking_session) blocker,
    inst_id,
    serial#,
    username,
    machine,
    module,
    event,
    wait_time_micro,
    command,
    row_wait_obj#,
    sql_id
  FROM gv$session
  )
SELECT LPAD ('  ', LEVEL )
  || s.waiter waiter,
  s.serial#,
  s.username,
  s.machine,
  s.module,
  s.event,
  ROUND (s.wait_time_micro / 1000000) secs,
  c.command_name,
  o.owner
  || '.'
  || o.object_name obj,
  s.sql_id
FROM sessions s
LEFT OUTER JOIN dba_objects o
ON (o.object_id = s.row_wait_obj#)
JOIN gv$sqlcommand c
ON (c.inst_id      = s.inst_id
AND c.command_type = s.command)
WHERE s.waiter    IN
  (SELECT blocker FROM sessions
  )
OR s.blocker               IS NOT NULL
  CONNECT BY PRIOR s.waiter = s.blocker
  START WITH s.blocker     IS NULL;

CLEAR COLUMNS
set echo on
