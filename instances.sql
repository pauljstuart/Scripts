

column host_name format A40 truncate
column status format A10
column version format A20
column startup_time format A20;
column instance_number format 99 heading Inst_id




select  INST_ID ,thread# ,INSTANCE_NAME, HOST_NAME , VERSION, STARTUP_TIME,STATUS , PARALLEL  ,ARCHIVER, LOGINS,
    DATABASE_STATUS
from gv$instance
order by inst_id;

