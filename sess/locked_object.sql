

col P_USERNAME new_value 1 format A20
col P_SQL_ID new_value 2  format A20
col P_INST new_value 3 format A20

select null P_USERNAME, null P_SQL_ID, null P_INST from dual where 1=2;
select nvl( '&1','&_USER') P_USERNAME, nvl('&2','%') P_SQL_ID, nvl('&3','%') P_INST from dual ;

define USERNAME=&1     
define SQL_ID=&2
define INSTANCE=&3

undefine 1
undefine 2
undefine 3
column sql_text format A100
column object_name format A30



SELECT
  L.inst_id, 
  L.SESSION_ID,
  S.SERIAL#,
  S.PROGRAM,
  L.ORACLE_USERNAME,
       decode(L.locked_mode
        ,       0, 'None'
        ,       1, 'Null'
        ,       2, 'Row-S '
        ,       3, 'Row-X '
        ,       4, 'Share'
        ,       5, 'S/Row-X'
        ,       6, 'Exclusive') lock_mode,  
   O.ObJECT_NAME,
   sq.sql_id,
   regexp_replace(Sq.sql_text, '[' || chr(10) || chr(13) || ']', ' ')  sql_text
FROM GV$LOCKED_OBJECT L
inner join dba_objects o on  L.OBJECT_ID     = O.OBJECT_ID
inner join gv$session S on L.inst_id = S.inst_id and L.session_id = S.sid 
left outer join gv$sqlarea  sq on s.inst_id = sq.inst_id  and S.SQL_HASH_VALUE = SQ.HASH_VALUE  AND S.SQL_ADDRESS    = SQ.ADDRESS
WHERE  L.oracle_username like '&USERNAME'
and L.inst_id like '&INSTANCE';
