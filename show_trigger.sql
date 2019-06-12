



column trigger_body format A500
column triggering_event format A20

column when_clause format A20
column trigger_name format A20

select trigger_name,trigger_type,triggering_event, when_clause,  trigger_body 
FROM dba_triggers
where owner = upper('&1')
and trigger_name = upper('&2');




