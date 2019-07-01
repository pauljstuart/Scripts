set echo off
--------------------------------------------------------------------------------
--
-- File name:   ash_wait_chains.sql (v0.2 BETA)
-- Purpose:     Display ASH wait chains (multi-session wait signature, a session
--              waiting for another session etc.)
--              
-- Author:      Tanel Poder
-- Copyright:   (c) http://blog.tanelpoder.com
--              
-- Usage:       
--     @ash_wait_chains <grouping_cols> <filters> <fromtime> <totime>
--
-- Example:
--     @ash_wait_chains username||':'||program2||event2 session_type='FOREGROUND' sysdate-1/24 sysdate
--
--     ash/ash_wait_chains sql_opname||':'||event2 1=1 sysdate-1/24/60 sysdate
--
--  @ash/ash_wait_chains username||':'||program2||':'||event2 user_id=265 "to_date('27-03-2014 05:00', 'DD-MM-YYYY HH24:MI')"  "to_date('27-03-2014 08:00', 'DD-MM-YYYY HH24:MI')"
--
-- Other:
--     This script uses only the in-memory V$ACTIVE_SESSION_HISTORY, use
--     @dash_wait_chains.sql for accessiong the DBA_HIST_ACTIVE_SESS_HISTORY archive
--
--     Oracle 10g does not  have the BLOCKING_INST_ID column in ASH so you'll need
--     to comment out this column in this script. This may give you somewhat
--     incorrect results in RAC environment with global blockers.
--              
--------------------------------------------------------------------------------



define ASH=gv$active_session_history

prompt
prompt ASH=&ASH
prompt filter=&2
prompt

prompt
prompt A simple sum of the waiters from a particular blocker :
prompt

SELECT 
  BLOCKING_INST_ID,
  blocking_session bsid,
  blocking_session_serial# bserial,
  event blockee_event,
  count(distinct session_id) blocking_session_count,
        MIN(sample_time) wait_start_time, 
        MAX(sample_time) wait_end_time, 
  ((CAST(MAX(sample_time)  AS DATE)) - (CAST(MIN(sample_time) AS DATE))) * (3600*24) duration_secs
FROM &ASH ASH
WHERE 
    sample_time   between &3 and &4 
AND session_type = 'FOREGROUND'
and blocking_session is not null
and    &2
--AND event like  '&event'
group by blocking_inst_id, blocking_session, blocking_session_serial#, event
ORDER BY 5 desc;



COL wait_chain FOR A300 WORD_WRAP
COL "%This" FOR A6

PROMPT
PROMPT -- Display ASH Wait Chain Signatures script v0.2 BETA by Tanel Poder ( http://blog.tanelpoder.com )
prompt

WITH 
bclass AS (SELECT class, ROWNUM r from v$waitstat),
ash AS (SELECT /*+ QB_NAME(ash) LEADING(a) USE_HASH(u) SWAP_JOIN_INPUTS(u) */
            a.*
          , u.username
          , CASE WHEN a.session_type = 'BACKGROUND' OR REGEXP_LIKE(a.program, '.*\([PJ]\d+\)') THEN
              REGEXP_REPLACE(SUBSTR(a.program,INSTR(a.program,'(')), '\d', 'n')
            ELSE
                '('||REGEXP_REPLACE(REGEXP_REPLACE(a.program, '(.*)@(.*)(\(.*\))', '\1'), '\d', 'n')||')'
            END || ' ' program2
          , NVL(a.event||CASE WHEN a.event IN ('buffer busy waits', 'gc buffer busy', 'gc buffer busy acquire', 'gc buffer busy release') 
                              THEN ' ['||(SELECT class FROM bclass WHERE r = a.p3)||']' ELSE null END,'ON CPU') 
                       || ' ' event2
          , TO_CHAR(CASE WHEN session_state = 'WAITING' THEN p1 ELSE null END, '0XXXXXXXXXXXXXXX') p1hex
          , TO_CHAR(CASE WHEN session_state = 'WAITING' THEN p2 ELSE null END, '0XXXXXXXXXXXXXXX') p2hex
          , TO_CHAR(CASE WHEN session_state = 'WAITING' THEN p3 ELSE null END, '0XXXXXXXXXXXXXXX') p3hex
        FROM 
            &ASH a
          , dba_users u
        WHERE
            a.user_id = u.user_id (+)
        AND sample_time BETWEEN &3 and &4
    ),
ash_samples AS (SELECT DISTINCT sample_id FROM ash),
ash_data AS (SELECT /*+ MATERIALIZE */ * FROM ash),
chains AS (
    SELECT
        sample_time ts
      , level lvl
      , session_id sid
      --, SYS_CONNECT_BY_PATH(&1, ' -> ')||CASE WHEN CONNECT_BY_ISLEAF = 1 THEN '('||d.session_id||')' ELSE NULL END path
      , REPLACE(SYS_CONNECT_BY_PATH(&1, '->'), '->', ' -> ') ||CASE WHEN CONNECT_BY_ISLEAF = 1 THEN '(session:'||d.session_id||')' ELSE NULL END path -- there's a reason why I'm doing this (ORA-30004 :)
      , CASE WHEN CONNECT_BY_ISLEAF = 1 THEN d.session_id ELSE NULL END sids
      , CONNECT_BY_ISLEAF isleaf
      , CONNECT_BY_ISCYCLE iscycle
      , d.*
    FROM
        ash_samples s
      , ash_data d
    WHERE
        s.sample_id = d.sample_id 
    AND d.sample_time BETWEEN &3 and &4
    CONNECT BY NOCYCLE
        (    PRIOR d.blocking_session = d.session_id
         AND PRIOR d.blocking_inst_id = d.inst_id
         AND PRIOR s.sample_id = d.sample_id
        )
    START WITH  &2
    -- session_type='FOREGROUND'
    -- top_level_sql_id='dnhrhy100qhhq'
)
SELECT * FROM (
    SELECT
        LPAD(ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100)||'%',5,' ') "%This",
      --, COUNT(*) seconds
         ((CAST(MAX(sample_time)  AS DATE)) - (CAST(MIN(sample_time) AS DATE))) * (3600*24) duration_secs,
      --, ROUND(COUNT(*) / ((CAST(&4 AS DATE) - CAST(&3 AS DATE)) * 86400), 1) AAS
        COUNT(DISTINCT sids) num_waiters,
        MIN(sample_time) wait_start_time, 
        MAX(sample_time) wait_end_time, 
        path wait_chain    
      -- , MIN(sids)
      -- , MAX(sids)
    FROM
        chains
    WHERE
        isleaf = 1
    GROUP BY
        &1
      , path
    ORDER BY
        COUNT(*) DESC
    )
WHERE
    ROWNUM <= 30
/

set echo on
