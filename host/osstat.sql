

COLUMN os_parameter format A30
column value format 999,999,999,999,999

select 'cpu run queue' as os_parameter, value from v$osstat where stat_name = 'LOAD'
union
select 'num cpu cores' os_parameter, value from v$osstat where stat_name = 'NUM_CPU_CORES'
union
select 'num logical cpus' os_parameter, value from v$osstat where stat_name = 'NUM_LCPUS'
union
select 'CALC num CPUS' os_parameter, (select  value from v$osstat where stat_name = 'NUM_CPU_SOCKETS') * (select  value from v$osstat where stat_name = 'NUM_CPU_CORES') as value from dual
union
select  'phys memory gbytes' os_parameter, value/(1024*1024*1024) from v$osstat where stat_name = 'PHYSICAL_MEMORY_BYTES'
union
select 'cpu sockets' os_parameter, value from v$osstat where stat_name = 'NUM_CPU_SOCKETS'
union
select 'tcp send size default' os_parameter, value from v$osstat where stat_name = 'TCP_SEND_SIZE_DEFAULT'
union
select 'tcp receive size default' os_parameter, value from v$osstat where stat_name = 'TCP_RECEIVE_SIZE_DEFAULT'
union
select 'tcp send size max' os_parameter, value from v$osstat where stat_name = 'TCP_SEND_SIZE_MAX'
union
select 'tcp receive size max' os_parameter, value from v$osstat where stat_name = 'TCP_RECEIVE_SIZE_MAX';
