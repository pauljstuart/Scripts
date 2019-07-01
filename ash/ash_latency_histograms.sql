
column b1 format 999 heading 1ms
column b2 format 999 heading 2ms
column b4 format 999 heading 4ms
column b8 format 999 heading 8ms
column b16 format 999 heading 16ms
column b32 format 999 heading 32ms
column b64 format 999 heading 64ms
column b128 format 999 heading 128ms
column b256 format 999 heading 256ms
column b512 format 999 heading 512ms
column b1024 format 999 heading 1024ms
column b2048 format 999 heading 2048ms
column b4096 format 999 heading 4096ms


with pivot_table as
(select event, time_waited/1000 time_ms, 
    CASE WHEN width_bucket( time_waited/1000, 0, 1, 1) = 1 THEN 1 ELSE 0 END AS b1,
    CASE WHEN width_bucket( time_waited/1000, 2, 3, 1) = 1 THEN 1 ELSE 0 END AS b2,
    CASE WHEN width_bucket( time_waited/1000, 4, 7, 1) = 1 THEN 1 ELSE 0 END AS b4,
    CASE WHEN width_bucket( time_waited/1000, 8, 15, 1) = 1 THEN 1 ELSE 0 END AS b8,
    CASE WHEN width_bucket( time_waited/1000, 16, 31, 1) = 1 THEN 1 ELSE 0 END AS b16,
    CASE WHEN width_bucket( time_waited/1000, 32, 63, 1) = 1 THEN 1 ELSE 0 END AS b32,
    CASE WHEN width_bucket( time_waited/1000, 64, 127, 1) = 1 THEN 1 ELSE 0 END AS b64,
   CASE WHEN width_bucket( time_waited/1000, 128, 255, 1) = 1 THEN 1 ELSE 0 END AS b128,
   CASE WHEN width_bucket( time_waited/1000, 256, 511, 1) = 1 THEN 1 ELSE 0 END AS b256,
   CASE WHEN width_bucket( time_waited/1000, 512, 1023, 1) = 1 THEN 1 ELSE 0 END AS b512,
   CASE WHEN width_bucket( time_waited/1000, 1024, 2047, 1) = 1 THEN 1 ELSE 0 END AS b1024,
   CASE WHEN width_bucket( time_waited/1000, 2048, 4095, 1) = 1 THEN 1 ELSE 0 END AS b2048,
   CASE WHEN width_bucket( time_waited/1000, 4096, 8111, 1) = 1 THEN 1 ELSE 0 END AS b4096
from gv$active_session_history
--where sample_time >  TO_DATE ('21/11/2012 11:11', 'dd/mm/yyyy hh24:mi:ss') 
--and sample_time < TO_DATE ('21/11/2012 11:21', 'dd/mm/yyyy hh24:mi:ss') 
where event in ('direct path read temp', 'direct path write temp', 'cell single block physical read')
and user_id != 393
and session_type = 'FOREGROUND'
and time_waited > 0
)
select event , decode( count(*) , 0, 0, sum(b1)*100/count(*)) as  b1 ,
               decode( count(*) , 0, 0, sum(b2)*100/count(*)) as b2 ,
               decode( count(*) , 0, 0, sum(b4)*100/count(*)) as b4 ,
               decode( count(*) , 0, 0, sum(b8)*100/count(*)) as b8 ,
               decode( count(*) , 0, 0, sum(b16)*100/count(*)) as b16 ,
               decode( count(*) , 0, 0, sum(b32)*100/count(*)) as b32 ,
               decode( count(*) , 0, 0, sum(b64)*100/count(*)) as b64 ,
               decode( count(*) , 0, 0, sum(b128)*100/count(*)) as b128 ,
               decode( count(*) , 0, 0, sum(b256)*100/count(*)) as b256,
               decode( count(*) , 0, 0, sum(b512)*100/count(*)) as b512 ,
               decode( count(*) , 0, 0, sum(b1024)*100/count(*)) as b1024 ,
               decode( count(*) , 0, 0, sum(b2048)*100/count(*)) as b2048 ,
               decode( count(*) , 0, 0, sum(b4096)*100/count(*)) as b4096, 
   count(*)
from pivot_table
group by event;


