

COLUMN avg_phyio_mb_sec FORMAT 999,999,999;
COLUMN sql_opname FORMAT A10;


--break on inst_id skip page duplicates

with pivot as
(
select inst_id, 
       ASH.user_id,  ASH.sql_id, 
         ASH.sql_exec_id,  
         ASH.sql_exec_start, 
         ASH.sql_opname,
         count(*) etime_sec, 
         decode( sum(delta_time), 0, 0, (sum(delta_read_io_bytes+delta_write_io_bytes)/1024/1024)/(sum(delta_time)/1000000) ) avg_phyio_mb_sec
from gv$active_session_history ASH 
where  
--   ASH.sample_time >  TO_DATE ('10/03/2016 05:34', 'dd/mm/yyyy hh24:mi') 
-- and ASH.sample_time < TO_DATE ('10/03/2016 12:42', 'dd/mm/yyyy hh24:mi') 
--  ash.sample_time > sysdate -1
       ASH.session_type = 'FOREGROUND'
   and ASH.session_state = 'WAITING'
   and ASH.sql_id is not null
   and ASH.sql_exec_id is not null
--and  ASH.sql_id in ('gh9pd08vhptgr' )
group by ash.inst_id, ash.user_id, ASH.sql_id, ASH.sql_exec_id, ASH.sql_exec_start, ASH.sql_opname
)
select * from pivot
where avg_phyio_mb_sec > 10
and etime_sec > 60
order by  avg_phyio_mb_sec desc;



/*

-- And attempt to sum the physical IO per minute, but not very useful


COLUMN avg_sql_kb_sec1 FORMAT 999,999.9
COLUMN avg_sql_kb_sec2 FORMAT 999,999.9
COLUMN avg_sql_kb_sec3 FORMAT 999,999.9
COLUMN avg_sql_kb_sec4 FORMAT 999,999.9


with 
sub1 as
( select   
    trunc(sample_time,'MI') sample_min,
    inst_id,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and inst_id = 1 and sql_id is not NULL then delta_read_io_bytes + delta_write_io_bytes else 0 END as phy_inst1 ,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and inst_id = 2 and sql_id is not NULL then delta_read_io_bytes + delta_write_io_bytes  else 0 END as phy_inst2 ,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and inst_id = 3 and sql_id is not NULL then delta_read_io_bytes + delta_write_io_bytes else 0 END as phy_inst3 ,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and inst_id = 4 and sql_id is not NULL then delta_read_io_bytes + delta_write_io_bytes else 0 END as phy_inst4, 
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and inst_id = 1 and sql_id is not NULL then delta_time else 0 END as delta_time_inst1 ,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and inst_id = 2 and sql_id is not NULL then delta_time  else 0 END as delta_time_inst2 ,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and inst_id = 3 and sql_id is not NULL then delta_time  else 0 END as delta_time_inst3 ,
     CASE  WHEN session_type =  'FOREGROUND' AND session_state = 'WAITING' and inst_id = 4 and sql_id is not NULL then delta_time  else 0 END as delta_time_inst4 
     from
        gv$active_session_history
--     where
--        sample_time    >= TO_DATE ('&START_TIME', 'dd/mm/yyyy hh24:mi')
--    AND sample_time    <= TO_DATE ('&END_TIME', 'dd/mm/yyyy hh24:mi')
   )
, sub2 as 
(
select sub1.sample_min,
          sum(phy_inst1)/1024 sum_kb_inst1,
          sum(delta_time_inst1)/1000000  sum_time_sec_inst1,
          sum(phy_inst2)/1024 sum_kb_inst2,
          sum(delta_time_inst2)/1000000  sum_time_sec_inst2,
          sum(phy_inst3)/1024 sum_kb_inst3,
          sum(delta_time_inst3)/1000000  sum_time_sec_inst3,
          sum(phy_inst4)/1024 sum_kb_inst4,
          sum(delta_time_inst4)/1000000  sum_time_sec_inst4
from sub1
group by sub1.sample_min
order by sub1.sample_min 
)
select sub2.sample_min,
decode( sum_time_sec_inst1 , 0 ,0 , sum_kb_inst1/sum_time_sec_inst1) avg_sql_kb_sec1,
decode( sum_time_sec_inst2 , 0 ,0 , sum_kb_inst2/sum_time_sec_inst2) avg_sql_kb_sec2,
decode( sum_time_sec_inst3 , 0 ,0 , sum_kb_inst3/sum_time_sec_inst3) avg_sql_kb_sec3,
decode( sum_time_sec_inst4 , 0 ,0 , sum_kb_inst4/sum_time_sec_inst4) avg_sql_kb_sec4
from sub2;

*/
