set echo off
--
-- undostats
--
-- Paul Stuart
--
-- Nov 2004

column undo_ts format A10
column active_mb format 999,999
column new_undo_mb format 999,999
column unexpired_mb format 999,999,999
column expired_mb format 999,999,999;
column undo_mb_persec format 999.99;
column undo_freespace_plusexpired_mb format 999,999,999
column undo_freespace_mb format 999,999,999
column tuned_undoretention  format 999,999,999;
column undo_ts_maxsize_mb  format 999,999,999;
column undo_active_plus_unexpired_mb  format 999,999,999;
column break format A1 print heading '|' ;
column stolen_extents format 999,999,999,999
column begin format A20
column end format A20
column  ORA_01555_ERRORS format 999,999,999,999
column UNEXPIRED_BLOCKS_REUSED format 999,999,999
column NO_SPACE_REQUEST_COUNT  format 999,999,999
column TRANSACTIONS format 999,999,999,999
column longest_query_length format 999,999,999

define INSTANCE = &1;

clear screen






prompt
prompt Undo stats for instance number : &INSTANCE
prompt


WITH pivot1 AS
(
SELECT VALUE/(1024*1024) AS block_size_mb FROM v$parameter WHERE NAME = 'db_block_size' 
), 
snap_list as
(
select trunc(A.end_interval_time,'HH') snap_hour, max(snap_id) snap_id
from dba_hist_snapshot A
where begin_interval_time > sysdate - &DAYS_AGO
AND  dbid = (select dbid from v$database)
group by trunc(A.end_interval_time,'HH')
)
SELECT inst_id, 
        u.begin_time  BEGIN, 
	    u.end_time END ,
		t.name undo_ts,
        u.undoblks*(select block_size_mb from pivot1) new_undo_mb,
        u.undoblks*(select block_size_mb from pivot1)/((end_time-begin_time)*3600*24) undo_mb_persec,
        u.UNEXPIREDBLKS*(select block_size_mb from pivot1)            unexpired_mb,  
        u.ACTIVEBLKS*(select block_size_mb from pivot1)               active_mb,  
		u.EXPIREDBLKS*(select block_size_mb from pivot1)             expired_mb, 
	    '|' as break,
        B.tablespace_maxsize*(select block_size_mb from pivot1)  undo_ts_maxsize_mb, 
		(u.ACTIVEBLKS + u.UNEXPIREDBLKS )*(select block_size_mb from pivot1)    undo_active_plus_unexpired_mb, 
        (B.tablespace_maxsize - u.ACTIVEBLKS - u.UNEXPIREDBLKS )*(select block_size_mb from pivot1) undo_freespace_mb,
        (B.tablespace_maxsize - u.ACTIVEBLKS - u.UNEXPIREDBLKS + u.EXPIREDBLKS )*(select block_size_mb from pivot1) undo_freespace_plusexpired_mb,
        '|' as break,
        u.TUNED_UNDORETENTION ,       
        u.expblkrelcnt stolen_extents,
        u.ssolderrcnt ora_01555_errors,
        u.UNXPBLKREUCNT unexpired_blocks_reused,
        u.NOSPACEERRCNT no_space_request_count,       
		u.txncount transactions,
		u.maxquerylen longest_query_length,
		u.maxqueryid  longest_query_sql_id
FROM gv$undostat u
inner join v$tablespace t on u.undotsn = t.ts# 
inner join snap_list A on A.snap_hour = trunc(end_time,'HH') 
INNER join dba_hist_tbspc_space_usage B on B.snap_id = A.snap_id and  tablespace_id = u.undotsn 
--and u.maxqueryid like 'SQLID'
and inst_id = &INSTANCE
order by 1 , 2;


prompt
prompt Longest query in the period : 
prompt



SELECT TO_CHAR( u.begin_time, 'DD-MON-YY HH:MI a.m.' ) "BEGIN" , 
	TO_CHAR( u.end_time, 'DD-MON-YY HH:MI a.m.') "END" ,
		u.maxquerylen "Longest Query",
		u.maxqueryid "Max Query ID",
                u.expblkrelcnt "stolen extents",
                u.ssolderrcnt "01555 errors" 
FROM v$undostat u where u.maxquerylen = (select max(maxquerylen) from v$undostat );


prompt
prompt undo segments for instance &INSTANCE
prompt



/*
WITH pivot1 AS
(
SELECT VALUE/(1024*1024) AS block_size_mb FROM v$parameter WHERE NAME = 'db_block_size' 
)
select  segment_name, 
        blocks*(select block_size_mb from pivot1) as segment_size_mb,
        sum( blocks*(select block_size_mb from pivot1)) over ( ) total_mb
from    dba_segments
where   tablespace_name = (select value from gv$parameter where inst_id = &INSTANCE and name = 'undo_tablespace')
order by        blocks;
*/


column segment_size_mb format 999,999,999
column total_mb format 999,999,999,999
column segment_name format a30 head Segment_Name
column active_mb format 999,999,999
column unexpired_mb format 999,999,999
column expired_mb format 999,999,999
column num_extents format 999,999,999

with pivot1 as
(
select tablespace_name,
      segment_name,
      case when status = 'ACTIVE' then bytes else 0 end as active,
      case when status = 'UNEXPIRED' then bytes else 0 end as unexpired,
     case when status = 'EXPIRED' then bytes else 0 end as expired
from dba_undo_extents
)
select tablespace_name, segment_name,  nvl(sum(active),0)/(1024*1024) active_mb,
                                        nvl(sum(unexpired),0)/(1024*1024) unexpired_mb,
                                     nvl(sum(expired),0)/(1024*1024) expired_mb,
                                     count(*)   num_extents
from pivot1
where tablespace_name = (select value from gv$parameter where inst_id = &INSTANCE and name = 'undo_tablespace')
group by tablespace_name, segment_name
order by 3 desc;






@transactions % % &INSTANCE





/*
old query, which joins on addr and taddr.  is that right?

WITH pivot1 AS
(
SELECT VALUE/(1024*1024) AS block_size_mb FROM v$parameter WHERE NAME = 'db_block_size' 
)
select t.inst_id, s.sid, s.serial#, s.program, 
       s.logon_time,
       t.start_time, 
       t.used_ublk * (select block_size_mb from pivot1)  undo_used_mb,  
       s.sql_id,     
       t.XIDUSN undo_seg_num, 
       t.XIDSLOT undo_slot,
       t.STATUS, 
       t.ptx AS PARALLEL,
       cr_get consistent_gets,
  sum(t.used_ublk*(select block_size_mb from pivot1) ) over (partition by NULL) current_undo_sum_mb
from   gv$transaction t,
       gv$session s
where  t.addr = s.taddr
and    t.inst_id = s.inst_id
and    t.inst_id = '&INSTANCE'
order by undo_used_mb desc;
*/







