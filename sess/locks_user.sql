

select * from v$lock where type = 'UL';

select * from dbms_lock_allocated where lockid=1073741921;

select * from dba_lock where lock_type = 'UL' and lock_id1 = '1073742182';


SELECT name
FROM sys.dbms_lock_allocated la, v$session_wait sw
WHERE sw.event='enq: UL - contention'
AND la.lockid=sw.p2;


