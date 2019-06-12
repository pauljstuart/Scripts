

select NAMESPACE, GETS ,  GETHITS GETHITRATIO ,     PINS,   PINHITS,PINHITRATIO,   RELOADS
from v$librarycache;


prompt : summary 

select sum(pins) pins,
       sum(pinhits) pinhits,
       sum(reloads) reloads,
       sum(invalidations) invalidations,
       100-(sum(pinhits)/sum(pins)) *100 reparsing
 from v$librarycache;

