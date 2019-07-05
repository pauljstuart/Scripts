
column "AVG RECEIVE TIME (ms)" format 9999999.9
col inst_id for 9999

prompt GCS CURRENT BLOCKS:

select b1.inst_id, b2.value "RECEIVED",
b1.value "RECEIVE TIME",
((b1.value / b2.value) * 10) "AVG RECEIVE TIME (ms)"
from gv$sysstat b1, gv$sysstat b2
where b1.name = 'gc current block receive time' and
b2.name = 'gc current blocks received' and b1.inst_id = b2.inst_id;


prompt Current block Service Time :

SELECT
   a.inst_id "Instance",
   (a.value+b.value+c.value)/d.value "Current Blk Service Time"
FROM
  GV$SYSSTAT A,
  GV$SYSSTAT B,
  GV$SYSSTAT C,
  GV$SYSSTAT D
WHERE
  A.name = 'gc current block pin time' AND
  B.name = 'gc current block flush time' AND
  C.name = 'gc current block send time' AND
  D.name = 'gc current blocks served' AND
  B.inst_id=A.inst_id AND
  C.inst_id=A.inst_id AND
  D.inst_id=A.inst_id
ORDER BY
  a.inst_id;


prompt Breakdown of Service Time :
prompt

SELECT A.inst_id "Instance",
   (A.value/D.value) "Current Block Pin",
   (B.value/D.value) "Log Flush Wait",
   (C.value/D.value) "Send Time"
FROM
  GV$SYSSTAT A,
  GV$SYSSTAT B,
  GV$SYSSTAT C,
  GV$SYSSTAT D
WHERE
  A.name = 'gc current block pin time' AND
  B.name = 'gc current block flush time' AND
  C.name = 'gc current block send time' AND
  D.name = 'gc current blocks served' AND
  B.inst_id=a.inst_id AND
  C.inst_id=a.inst_id AND
  D.inst_id=a.inst_id
ORDER BY
  A.inst_id;

