

-- exporting a single partition table :

expdp app_supchk_user@EQSUPS1  parfile=supchk_answers.par



schemas=APP_SUPCHK_USER
include=TABLE:"IN ('SUPCHK_ANSWERS')" 
COMPRESSION=ALL 
directory=DATA_PUMP_DIR 
dumpfile=SUPCHK_ANSWERS_BACKUP.dmp 
logfile=output.log

