


prompt
prompt AAS over the last 60 secs
prompt
 
COLUMN INST_ID FORMAT 9
column AAS_Total format 999,999.9
column CPU format 999.9
column user_io format 999.9
column network format 999.9
column concurrency format 999.9
column configuration format 999.9 
column application format 999.9 
column commit format 999.9

column cpu_count format A10
column num_cores format 9,999

 with secs as (select 60 var from dual ), 
 pivot0 as
 (
 select      inst_id,count(*)/(select var from secs)     AAS,
             decode(session_state,'ON CPU','CPU',wait_class)  wait_class, 
             sum( count(*)/(select var from secs) ) over ( partition by inst_id ) AAS_Total,
             ( select value  from   gv$osstat OS where  stat_name = 'NUM_CPU_CORES' and OS.inst_id = ash.inst_id ) num_cores,
             (select value from v$parameter where name = 'cpu_count' ) cpu_count
 from gv$active_session_history ash
 where
        SAMPLE_TIME > sysdate - (select var from secs)/(24*60*60)
 and    SESSION_TYPE = 'FOREGROUND'
 group by inst_id, decode(session_state,'ON CPU','CPU',wait_class) 
having count(*)/(select var from secs) >  1
order by inst_id asc,aas desc
)
select * from pivot0
pivot  (sum(aas) for wait_class in ('CPU' as CPU, 'User I/O' as user_io, 'Network' as network, 'Concurrency' as Concurrency, 'System I/O' as system_io, 'Configuration' as configuration, 'Application' as Application, 'Commit' as Commit))
order by inst_id;
