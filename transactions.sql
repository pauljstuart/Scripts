
col P_USERNAME new_value 1 format A20
col P_SQL_ID new_value 2  format A20
col P_INST new_value 3 format A20

select null P_USERNAME, null P_SQL_ID, null P_INST from dual where 1=2;
select nvl( '&1','&_USER') P_USERNAME, nvl('&2','%') P_SQL_ID, nvl('&3','%') P_INST from dual ;

define USERNAME=&1     
define SQL_ID=&2
define INSTANCE=&3

undefine 1
undefine 2
undefine 3

prompt
prompt  ############## Current Uncommitted Transactions ############## 
prompt

prompt

column undo_mb format 999,999,999.9
column sql_text format A2000 
column sid   format 9999
column "serial#" format 999999
column undo_blocks format 999,999
column undo_used_mb format 999,999,999.9
column current_undo_sum_mb format 999,999,999.9
column undo_seg_num format 99999
column consistent_gets format 999,999,999
column age_mins format 999,999
column program format A20
column osuser format A20
column username format A20
column parallel format A10

WITH pivot1 AS
(
SELECT VALUE/(1024*1024) AS block_size_mb FROM v$parameter WHERE NAME = 'db_block_size' 
)
select t.inst_id, s.sid, s.serial#, s.program, 
       s.logon_time,
       t.start_time,
       s.osuser,
       (sysdate - to_date(start_time, 'MM/DD/YY HH24:MI:SS'))*60*24 age_mins, 
       username, 
       r.name rollback_name,  
       s.sql_id,     
       t.used_ublk * (select block_size_mb from pivot1)  undo_used_mb, 
       t.XIDUSN undo_seg_num, 
       t.XIDSLOT undo_slot,
       t.STATUS, 
       t.ptx AS PARALLEL,
       cr_get consistent_gets,
       sum(t.used_ublk*(select block_size_mb from pivot1) ) over (partition by NULL) current_undo_sum_mb,
       regexp_replace(dbms_LOB.substr(sql_text, 50), '[[:cntrl:]]',null)  sql_text
from gv$transaction t
  inner join gv$session s on s.saddr = t.ses_addr and s.inst_id = t.inst_id
  left outer join v$rollname r on r.usn = t.xidusn
  left outer join dba_hist_sqltext DHST on DHST.sql_id = s.sql_id  
where 
      t.inst_id like '&INSTANCE'
and username like '&USERNAME'
and s.sql_id like '&SQL_ID'
order by start_time;
