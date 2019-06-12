





col P1 new_value 1 format A10
col P2 new_value 2 format A10

select null p1, null p2 from dual where 1=2;
select nvl( '&1','%') p1, nvl('&2','%') p2 from dual ;

  
define RMAN_TYPE=&1  


undefine 1
undefine 2
undefine 3


prompt
prompt RMAN type : &RMAN_TYPE


column STATUS FORMAT A20 truncate
column in_size  FORMAT a10
column out_size FORMAT a10
column in_mb_persec FORMAT 999,999
column out_mb_persec FORMAT 999,999
column compression_ratio format 9.9
column session_key format 99999999
column start_time format A20
column end_time format A20
column optimized format A10

SELECT SESSION_KEY, INPUT_TYPE, STATUS,
       START_TIME ,
       END_TIME   ,
       elapsed_seconds/60 etime_mins,
       OPTIMIZED,
       INPUT_BYTES_PER_SEC/(1024*1024) in_mb_persec,
       OUTPUT_BYTES_PER_SEC/(1024*1024) out_mb_persec,
       INPUT_BYTES_DISPLAY in_size,
       OUTPUT_BYTES_DISPLAY out_size,
       trunc(COMPRESSION_RATIO,1) compression_ratio
FROM V$RMAN_BACKUP_JOB_DETAILS
where start_time > sysdate - &DAYS_AGO
and input_type like '&RMAN_TYPE%'
ORDER BY SESSION_KEY;
