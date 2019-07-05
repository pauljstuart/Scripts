set echo off

-----------------------------------------------------------------
--
--	File: blocking_sess_tree.sql 
--	Description: Lock tree built up from V$SESSION
--   
--	From 'Oracle Performance Survival Guide' by Guy Harrison
--		Chapter 15 Page 477
--		ISBN: 978-0137011957
--		See www.guyharrison.net for further information
--  
--		This work is in the public domain NSA 
--   
--
-----------------------------------------------------------------




COLUMN waiter       FOR a30     HEAD "INST.SID/SERIAL"
COLUMN serial#      FORmat A10 HEAD 
COLUMN username     FOR a20    TRUNC
COLUMN machine      FOR a10     TRUNC
COLUMN module       FOR a25     TRUNC
COLUMN event        FOR a30     TRUNC
COLUMN command_name FOR a15     
COLUMN obj          FOR a50     TRUNC
COLUMN sql_id       FOR a13   
column parallel format A8

PROMPT 
PROMPT Blocking Session Tree  :
PROMPT 


WITH sessions AS
  (SELECT
    /*+ MATERIALIZE */
    inst_id || '.' || sid  waiter,
    DECODE (blocking_session, NULL, NULL, blocking_instance ||'.'  || blocking_session  ) blocker,
    inst_id,
    serial#,
    username,
    machine,
    program,
    module,
    event,
    wait_time_micro,
    command,
    row_wait_obj#,
    sql_id
  FROM gv$session
  )
SELECT LPAD ( ' ' , LEVEL*2 )  || s.waiter || '/' || s.serial# waiter,
   s.username,
  s.machine,
  s.module,
  s.event,
  regexp_substr(s.program, '\(P.*\)' ) parallel ,
  ROUND (s.wait_time_micro / 1000000) secs_in_wait,
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
WHERE s.waiter    IN (SELECT blocker FROM sessions)
                  OR s.blocker               IS NOT NULL
  CONNECT BY PRIOR s.waiter = s.blocker
  START WITH s.blocker     IS NULL;


--set echo on
