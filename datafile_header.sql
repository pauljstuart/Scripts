alter session set NLS_DATE_FORMAT='DD-MON-YY HH24:MI';

column name format A50

column checkpoint_change# format 99999999999
column file# format 999

select file#, status,name, fuzzy,checkpoint_change#, checkpoint_time, recover , error
from v$datafile_header;

