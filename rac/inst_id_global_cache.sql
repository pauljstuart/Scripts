
column  "Avg CR block receive time (ms)" format 999999.9

select
	b1.inst_id,
	b2.value "GCS CR blocks received",
	b1.value "GCS CR block receive time",
		((b1.value / b2.value) * 10) "Avg CR block receive time (ms)"
from 
    gv$sysstat b1,
    gv$sysstat b2
where b1.name = 'gc cr block receive time'
and b2.name = 'gc cr blocks received'
and b1.inst_id = b2.inst_id;

