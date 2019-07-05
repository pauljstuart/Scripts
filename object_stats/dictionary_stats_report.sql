

-- how many tables in SYS are stale?

select distinct stale_stats, 
      count(*) over (partition by stale_stats) count_stale, 
      round(count(*) over (partition by stale_stats)*100/( count(*) over () )) as stal_pct
from dba_tab_statistics
where owner = 'SYS'
and stale_stats is not null;
