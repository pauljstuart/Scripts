




define OWNER=&1
define THIS_MVIEW=&2



alter session set nls_date_format = 'DD-MON-YY HH24:MI';
column query format A30
column last_refresh_date  format A16


select mview_name,updatable ,rewrite_enabled , refresh_mode, refresh_method, fast_refreshable, last_refresh_date, 
          last_refresh_type "Last Ref Type", 
        staleness, compile_state
from dba_mviews
where owner = upper('&OWNER')
and mview_name = upper('&THIS_MVIEW');


column query format A200 wrap
select query from dba_mviews
where owner = upper('&OWNER')
and mview_name = upper('&THIS_MVIEW');
