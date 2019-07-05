


-- take a date range, and break it into 8 smaller sub ranges.


alter session set nls_date_format='YYYYMMDD';
WITH C AS
(
SELECT 123 EMPID,TO_DATE('20141219','YYYYMMDD') STDT,TO_DATE('20150323','YYYYMMDD') ENDT
FROM DUAL
),
D as
(
SELECT EMPID, DT
FROM (SELECT EMPID, STDT+LEVEL-1 DT
      FROM C
      CONNECT BY LEVEL <= (ENDT-STDT+1))
)
select TO_CHAR(min(dt), 'YYYYMMDD') start_id, TO_CHAR(max(dt), 'YYYYMMDD')  end_id, count(*), nt
from ( select dt, ntile(8) over (order by dt) nt from d        )
group by nt
order by nt;





START_ID END_ID           COUNT(*)         NT
-------- -------- ---------------- ----------
20141219 20141230               12          1
20141231 20150111               12          2
20150112 20150123               12          3
20150124 20150204               12          4
20150205 20150216               12          5
20150217 20150228               12          6
20150301 20150312               12          7
20150313 20150323               11          8
