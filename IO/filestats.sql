--
-- Paul Stuart
--
-- Dec 2004

TTITLE ' DATAFILE DISK I/O REPORT'


column name format A70
column file# format 999

select  fs.file#, 
        df.name ,
        round( (singleblkrds*10)/singleblkrdtim) "avg single block Read (ms)",
        MAXIORTM*10 "MaxRead (ms)", 
        AVGIOTIM*10 "avg io time (ms)",  
        LSTIOTIM*10 "last io (ms)", 
        MAXIOWTM*10 "MaxWrite (ms)"
from v$filestat fs, v$datafile df
where df.file# = fs.file#;


clear columns
