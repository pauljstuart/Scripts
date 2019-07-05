
column undo_ts format A10
column active_mb format 999,999.9;
column new_undo_mb format 999,999.9;
column unexpired_mb format 999,999.9;
column expired_mb format 999,999.9;
column undo_mb_persec format 999.99;
column used_undo_mb format 999,999,999.9;
column tuned_undoretention  format 999,999,999;
column undo_ts_size_max_mb  format 999,999,999;
column undo_ts_free_mb  format 999,999,999;
column break format A1 print heading '|' ;

define INSTANCE = &1

define DAYS_AGO=45

clear screen

prompt
prompt Undo stats for instance number : &INSTANCE
prompt


WITH pivot1 AS
(
SELECT VALUE/(1024*1024) AS block_size_mb FROM v$parameter WHERE NAME = 'db_block_size' 
), 
pivot2 as 
(
select sum(decode (autoextensible, 'YES', maxbytes, bytes))/(1024*1024) as undo_ts_max_mb from   dba_data_files where  tablespace_name = (select value from gv$parameter where inst_id = &INSTANCE and name = 'undo_tablespace')  
)
SELECT instance_number, 
        u.begin_time  BEGIN, 
	    u.end_time END ,
		(select value from gv$parameter where inst_id = &INSTANCE and name = 'undo_tablespace')   undo_ts,
        u.undoblks*(select block_size_mb from pivot1) new_undo_mb,
 --       sum(u.undoblks*(select block_size_mb from pivot1)) over  () sum_over_period_mb,
        u.undoblks*(select block_size_mb from pivot1)/((end_time-begin_time)*3600*24) undo_mb_persec,
        u.UNEXPIREDBLKS*(select block_size_mb from pivot1)            unexpired_mb,  
        u.ACTIVEBLKS*(select block_size_mb from pivot1)               active_mb,  
		u.EXPIREDBLKS*(select block_size_mb from pivot1)             expired_mb, 
	    '|' as break,
        (select undo_ts_max_mb from pivot2) undo_ts_size_max_mb, 
		(u.ACTIVEBLKS + u.UNEXPIREDBLKS + u.EXPIREDBLKS)*(select block_size_mb from pivot1)    used_undo_mb, 
        (select undo_ts_max_mb from pivot2) - (u.ACTIVEBLKS + u.UNEXPIREDBLKS + u.EXPIREDBLKS)*(select block_size_mb from pivot1) undo_ts_free_mb,
        '|' as break,
        u.TUNED_UNDORETENTION ,       
        u.expblkrelcnt stolen_extents,
        u.ssolderrcnt ora_01555_errors,
        u.UNXPBLKREUCNT unexpired_blocks_reused,
        u.NOSPACEERRCNT no_space_request_count,       
		u.txncount transactions,
		u.maxquerylen longest_query_length,
		u.maxquerysqlid  longest_query_sql_id
FROM dba_hist_undostat u
where instance_number = &INSTANCE
and u.begin_time > SYSDATE - &DAYS_AGO
order by 1 , 2;


/*



-- a report to show max undo :


column UNDO_MAX_SIZE_MB format 999,999,999.9
column highest_used_undo_mb format 999,999,999.9
with undo_size
as
(
select tablespace_name, sum(decode (autoextensible, 'YES', maxbytes, bytes))/(1024*1024) as undo_max_size_mb from   dba_data_files where  tablespace_name like 'UNDO%'
group by tablespace_name
)
select 
  TN.name undo_name,
  US.undo_max_size_mb,
	max((u.ACTIVEBLKS + u.UNEXPIREDBLKS + u.EXPIREDBLKS)*(SELECT VALUE/(1024*1024) AS block_size_mb FROM v$parameter WHERE NAME = 'db_block_size' ) )   highest_used_undo_mb
from dba_hist_undostat u
inner join v$tablespace TN on TN.ts# = u.undotsn
inner join undo_size US on TN.name = US.tablespace_name
group by   US.undo_max_size_mb, TN.name
order by TN.name;




*/
