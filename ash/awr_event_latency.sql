



COLUMN sample_time    FORMAT a13     HEADING 'Hour'
COLUMN inst1_ms FORMAT 999,999.9
COLUMN inst2_ms FORMAT 999,999.9
COLUMN inst3_ms FORMAT 999,999.9
COLUMN inst4_ms FORMAT 999,999.9
COLUMN inst5_ms FORMAT 999,999.9
COLUMN inst6_ms FORMAT 999,999.9


define EVENT="log file sync"
prompt
prompt Latency for event &EVENT 
prompt
prompt


with 
sub1 as
( select   
     trunc(sample_time,'MI') sample_min,
    instance_number,
     CASE  WHEN instance_number = 1 then time_waited else 0 END as wait_inst1 ,
     CASE  WHEN instance_number = 2 then time_waited else 0 END as wait_inst2 ,
    CASE  WHEN instance_number = 3 then time_waited else 0 END as wait_inst3 ,
    CASE  WHEN  instance_number = 4 then time_waited else 0 END as wait_inst4 ,
    CASE  WHEN  instance_number = 5 then time_waited else 0 END as wait_inst5 ,
    CASE  WHEN  instance_number = 6 then time_waited else 0 END as wait_inst6 ,
    CASE WHEN instance_number = 1 then 1 else 0 end inst1_count, 
    CASE WHEN instance_number = 2 then 1 else 0 end inst2_count, 
    CASE WHEN instance_number = 3 then 1 else 0 end inst3_count, 
    CASE WHEN instance_number = 4 then 1 else 0 end inst4_count, 
    CASE WHEN instance_number = 5 then 1 else 0 end inst5_count,
    CASE WHEN instance_number = 6 then 1 else 0 end inst6_count
     from
        dba_hist_active_sess_history
       where 
           event = 'log file sync'
        and time_waited > 0  
        and session_type = 'FOREGROUND'
        AND SESSION_STATE = 'WAITING'
--order by trunc(sample_time,'MI')
--        sample_time    >= TO_DATE ('&START_TIME', 'dd/mm/yyyy hh24:mi')
--    AND sample_time    <= TO_DATE ('&END_TIME', 'dd/mm/yyyy hh24:mi')
   )
--select * from sub1;
select sample_min,
          decode( sum(inst1_count), 0, 0, sum(sub1.wait_inst1)/sum(inst1_count)/1000 ) inst1_ms,
          decode( sum(inst2_count), 0, 0, sum(sub1.wait_inst2)/sum(inst2_count)/1000 ) inst2_ms,
          decode( sum(inst3_count), 0, 0, sum(sub1.wait_inst3)/sum(inst3_count)/1000 ) inst3_ms,
          decode( sum(inst4_count), 0, 0, sum(sub1.wait_inst4)/sum(inst4_count)/1000 ) inst4_ms,
          decode( sum(inst5_count), 0, 0, sum(sub1.wait_inst5)/sum(inst5_count)/1000 ) inst5_ms,
          decode( sum(inst6_count), 0, 0, sum(sub1.wait_inst6)/sum(inst6_count)/1000 ) inst6_ms
from sub1
group by sample_min
order by sample_min ;



