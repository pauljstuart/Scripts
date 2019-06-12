column network format A20

column service format A20
column listener format A60

select network, dispatchers, connections "max conn per disp", service, listener from v$dispatcher_config;

