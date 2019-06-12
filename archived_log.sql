
COLUMN name FORMAT A60 ;
COLUMN status FORMAT A3 HEADING Status;
COLUMN dest_id FORMAT 99;
COLUMN thread# FORMAT 99;
COLUMN first_change# FORMAT 999999999999;
COLUMN next_change#  FORMAT 999999999999;
COLUMN completion_time FORMAT A30;


clear screen

define DEST_ID = &1;
define DAYS_AGO = 30;




select distinct dest_id,
        thread#,
        sequence#,
        completion_time, 
        first_change#, 
        next_change#, 
        registrar, 
        applied, 
        status, 
        deleted, 
        backup_count, 
        FAL  , 
        name 
FROM gv$archived_log
WHERE
       completion_time > to_date(sysdate - &DAYS_AGO )
AND    dest_id = &DEST_ID
order by dest_id, thread#, completion_time asc;
  
