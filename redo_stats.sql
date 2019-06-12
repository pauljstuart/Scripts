
define DAYS_AGO=14




COLUMN redo_generated_mb FORMAT 999,999,999,999
column block_changes format 999,999,999,999,999

WITH 
pivot1 AS
(
select value/(1024*1024) as block_size_mb from v$parameter where name = 'db_block_size' 
)
select trunc(completion_time, 'HH') rundate ,
      count(*)  logswitch ,
      sum(blocks*(select block_size_mb from pivot1)) redo_generated_mb
from v$archived_log
group by trunc(completion_time, 'HH')
HAVING trunc(completion_time, 'HH') > sysdate - &DAYS_AGO
order by 1;



-- daily, or hourly, redo report, broken down by instances



column total_mb format 999,999,999,999
COLUMN inst1_mb FORMAT 999,999,999,999
COLUMN inst2_mb FORMAT 999,999,999,999
COLUMN inst3_mb FORMAT 999,999,999,999
COLUMN inst4_mb FORMAT 999,999,999,999
COLUMN inst6_mb FORMAT 999,999,999,999



select trunc(first_time,'DD'),
   sum(decode(thread#,1,blocks*block_size,0))/1024/1024 inst1_MB, 
   sum(decode(thread#,2,blocks*block_size,0))/1024/1024 inst2_MB, 
   sum(decode(thread#,3,blocks*block_size,0))/1024/1024 inst3_MB,
   sum(decode(thread#,4,blocks*block_size,0))/1024/1024 inst4_MB,  
   sum(decode(thread#,5,blocks*block_size,0))/1024/1024 inst5_MB, 
   sum(decode(thread#,6,blocks*block_size,0))/1024/1024 inst6_MB,
   sum(blocks*block_size)/1024/1024 total_mb 
from v$archived_log where first_time> SYSDATE - &DAYS_AGO
and standby_dest='NO' and archived='YES' 
group by trunc(first_time,'DD')
order by 1;


-- a simple query to see which sessions are generating redo, must be run in real time though.

prompt
prompt session level redo stats :
prompt

SELECT s.inst_id, s.sid, s.serial#, s.username, s.program,
           i.block_changes
FROM gv$session s
inner join gv$sess_io i on  s.sid = i.sid and i.inst_id = s.inst_id
and type = 'USER'
and block_changes > 0
ORDER BY block_changes desc;



-- an old query showing switches in a table format

select to_char(first_time,'YYYY-MM-DD') day,
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'00',1,0)),'9,999') "00",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'01',1,0)),'9,999') "01",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'02',1,0)),'9,999') "02",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'03',1,0)),'9,999') "03",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'04',1,0)),'9,999') "04",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'05',1,0)),'9,999') "05",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'06',1,0)),'9,999') "06",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'07',1,0)),'9,999') "07",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'08',1,0)),'9,999') "08",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'09',1,0)),'9,999') "09",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'10',1,0)),'9,999') "10",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'11',1,0)),'9,999') "11",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'12',1,0)),'9,999') "12",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'13',1,0)),'9,999') "13",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'14',1,0)),'9,999') "14",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'15',1,0)),'9,999') "15",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'16',1,0)),'9,999') "16",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'17',1,0)),'9,999') "17",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'18',1,0)),'9,999') "18",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'19',1,0)),'9,999') "19",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'20',1,0)),'9,999') "20",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'21',1,0)),'9,999') "21",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'22',1,0)),'9,999') "22",
to_char(sum(decode(substr(to_char(first_time,'HH24'),1,2),'23',1,0)),'9,999') "23"
from v$log_history
group by to_char(first_time,'YYYY-MM-DD')
order by to_char(first_time,'YYYY-MM-DD')
/
