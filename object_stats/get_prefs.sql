prompt
prompt ==================================================================================================================================================================
prompt global statistics preferences :
prompt ==================================================================================================================================================================
prompt 

column global_value format A40

 SELECT 'stale_pct' as parameter, dbms_stats.get_prefs('STALE_PERCENT') as global_value FROM dual
union
 SELECT 'autostats_target', dbms_stats.get_prefs( 'AUTOSTATS_TARGET' )  FROM dual
union
 SELECT 'cascasde',  dbms_stats.get_prefs( 'CASCADE' ) cascade FROM dual
union
 select 'degree' ,dbms_stats.get_prefs( 'DEGREE' ) degree from dual
union
 select 'estimate_percent',dbms_stats.get_prefs('ESTIMATE_PERCENT' ) estimate_percent from dual
union
 select 'method_opt', dbms_stats.get_prefs('METHOD_OPT') method_opt from dual
union
 select 'no_invalidate', dbms_stats.get_prefs('NO_INVALIDATE' ) no_invalidate from dual
union
 select 'granularity', dbms_stats.get_prefs('GRANULARITY' ) granularity from dual
union
 select 'publish', dbms_stats.get_prefs('PUBLISH') publish from dual
union
 select 'incremental', dbms_stats.get_prefs('INCREMENTAL') incremental from dual;

