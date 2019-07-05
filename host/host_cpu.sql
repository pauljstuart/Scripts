

column value format 999,999,999.99

-- last 60 seconds

column begin_time format A21
column end_time format A21
column maxval format 999,999,999.9
column minval format 999,999,999.9
column average format 999,999,999.9

select INST_ID ,BEGIN_TIME,          END_TIME   ,  METRIC_NAME, MAXVAL 
  ,    MINVAL ,   AVERAGE, METRIC_UNIT 
 from 
gv$sysmetric_summary
where metric_name =  'Host CPU Utilization (%)';

-- last hour


column inst1_cpu format 999.9
column inst2_cpu format 999.9
column inst3_cpu format 999.9
column inst4_cpu format 999.9
column inst5_cpu format 999.9
column inst6_cpu format 999.9

column inst1_cpu_queue format 999
column inst2_cpu_queue format 999
column inst3_cpu_queue format 999
column inst4_cpu_queue format 999
column inst5_cpu_queue format 999
column inst6_cpu_queue format 999




set linesize 2000
with pivot1 as
(
select to_char(begin_time,'DD-MON-YYYY hh24:mi') Time_Delta,inst_id ,
   case when metric_name = 'Host CPU Utilization (%)' then value else 0 end as cpu,
case when metric_name = 'Current OS Load' then value else 0 end as cpu_q
 from gv$sysmetric_history
 where  trunc(intsize_CSEC, -2) in ( 6000, 5900)
)
select *  from pivot1
pivot 
   ( sum(cpu) cpu,
     sum(trunc(cpu_q)) cpu_queue
    for inst_id in (1 as inst1,2 as inst2,3 as inst3 ,4 as inst4,5 as inst5,6 as inst6)
     )
order by time_delta;



