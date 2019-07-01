set echo off

define SID=&1
define SERIAL=&2

undefine 1
undefine 2

column mins format 999,999;
column secs format 999,999
COLUMN sql_opname FORMAT A10
COLUMN max_temp_mb FORMAT 999,999,999
COLUMN max_pga_mb FORMAT 999,999,999
COLUMN sql_id  FORMAT A13
column sql_start_time format A20
column sql_end_time format A20
column in_hard_parse format A10
column session_serial# format 999999

prompt
prompt Looking for &SID/&SERIAL in gv$session and gv$process :
prompt

set serveroutput on

DECLARE
  v_sid number;
  s gv$session%ROWTYPE;
  p gv$process%ROWTYPE;
BEGIN

  begin
    select * into s from gv$session where sid  = &SID and  serial# = &SERIAL ;
    select * into p from gv$process where addr = s.paddr and inst_id = s.inst_id ;

  exception
    when  NO_DATA_FOUND
    then 
       dbms_output.put_line('Couldnt find that session in gv$session.');
      return ;
  end;

  dbms_output.put_line('=====================================================================');
  dbms_output.put_line('Instance    : '|| p.inst_id);  
  dbms_output.put_line('SID/Serial  : '|| s.sid||','||s.serial#);
  dbms_output.put_line('Foreground  : '|| 'PID: '||s.process||' - '||s.program);
  dbms_output.put_line('Shadow      : '|| 'PID: '||p.spid||' - '||p.program);
  dbms_output.put_line('OS User     : '|| s.osuser||' on '||s.machine);
  dbms_output.put_line('Ora User    : '|| s.username);
  dbms_output.put_line('Status Flags: '|| s.status||' '||s.server||' '||s.type);
  dbms_output.put_line('Tran Active : '|| nvl(s.taddr, 'NONE'));
  dbms_output.put_line('Login Time  : '|| to_char(s.logon_time, 'Dy HH24:MI:SS'));
  dbms_output.put_line('Last Call   : '|| to_char(sysdate-(s.last_call_et/60/60/24), 'Dy HH24:MI:SS') || ' - ' || to_char(s.last_call_et/60, '990.0') || ' min');
  dbms_output.put_line('Lock/ Latch : '|| nvl(s.lockwait, 'NONE')||'/ '||nvl(p.latchwait, 'NONE'));
  dbms_output.put_line('Latch Spin  : '|| nvl(p.latchspin, 'NONE'));


  dbms_output.put_line('Locks:');
  for c1 in ( select /*+ ordered */
          decode(l.type,
          -- Long locks
                      'TM', 'DML/DATA ENQ',   'TX', 'TRANSAC ENQ',
                      'UL', 'PLS USR LOCK',
          -- Short locks
                      'BL', 'BUF HASH TBL',  'CF', 'CONTROL FILE',
                      'CI', 'CROSS INST F',  'DF', 'DATA FILE   ',
                      'CU', 'CURSOR BIND ',
                      'DL', 'DIRECT LOAD ',  'DM', 'MOUNT/STRTUP',
                      'DR', 'RECO LOCK   ',  'DX', 'DISTRIB TRAN',
                      'FS', 'FILE SET    ',  'IN', 'INSTANCE NUM',
                      'FI', 'SGA OPN FILE',
                      'IR', 'INSTCE RECVR',  'IS', 'GET STATE   ',
                      'IV', 'LIBCACHE INV',  'KK', 'LOG SW KICK ',
                      'LS', 'LOG SWITCH  ',
                      'MM', 'MOUNT DEF   ',  'MR', 'MEDIA RECVRY',
                      'PF', 'PWFILE ENQ  ',  'PR', 'PROCESS STRT',
                      'RT', 'REDO THREAD ',  'SC', 'SCN ENQ     ',
                      'RW', 'ROW WAIT    ',
                      'SM', 'SMON LOCK   ',  'SN', 'SEQNO INSTCE',
                      'SQ', 'SEQNO ENQ   ',  'ST', 'SPACE TRANSC',
                      'SV', 'SEQNO VALUE ',  'TA', 'GENERIC ENQ ',
                      'TD', 'DLL ENQ     ',  'TE', 'EXTEND SEG  ',
                      'TS', 'TEMP SEGMENT',  'TT', 'TEMP TABLE  ',
                      'UN', 'USER NAME   ',  'WL', 'WRITE REDO  ',
                      'TYPE='||l.type) type,
       decode(l.lmode, 0, 'NONE', 1, 'NULL', 2, 'RS', 3, 'RX', 4, 'S',    5, 'RSX',  6, 'X',  to_char(l.lmode) ) lmode,
       decode(l.request, 0, 'NONE', 1, 'NULL', 2, 'RS', 3, 'RX',   4, 'S', 5, 'RSX', 6, 'X',  to_char(l.request) ) lrequest,
       decode(l.type, 'MR', o.name,
                      'TD', o.name,
                      'TM', o.name,
                      'RW', 'FILE#='||substr(l.id1,1,3)||  ' BLOCK#='||substr(l.id1,4,5)||' ROW='||l.id2,
                      'TX', 'RS+SLOT#'||l.id1||' WRP#'||l.id2,
                      'WL', 'REDO LOG FILE#='||l.id1,
                      'RT', 'THREAD='||l.id1,
                      'TS', decode(l.id2, 0, 'ENQUEUE', 'NEW BLOCK ALLOCATION'),
                      'ID1='||l.id1||' ID2='||l.id2) objname
       from  gv$lock l, sys.obj$ o
       where sid   = s.sid
         and l.id1 = o.obj#(+) 
         and l.inst_id = p.inst_id) 
   LOOP
       dbms_output.put_line(chr(9)||c1.type||' Mode: '||c1.lmode||' Request: '||c1.lrequest||' - '||c1.objname);
   END LOOP;

  /*
  dbms_output.put_line( chr(10) ||'Current SQL statement:');
  for c1 in ( select * from gv$sqltext  where HASH_VALUE = s.sql_hash_value  and inst_id =p.inst_id order by piece) 
  loop
    dbms_output.put_line(chr(9)||c1.sql_text);
  end loop;
*/

  dbms_output.put_line( chr(10) || 'Previous SQL statement:');
  for c1 in ( select * from gv$sqltext where HASH_VALUE = s.prev_hash_value and inst_id = p.inst_id order by piece) 
  loop
    dbms_output.put_line(chr(9) || c1.sql_text);
  end loop;

  dbms_output.put_line(chr(10) || 'Session Waits:');
  for c1 in ( select * from gv$session_wait where sid = s.sid and inst_id = p.inst_id) 
  loop
    dbms_output.put_line(chr(9) || c1.state||': '||c1.event);
  end loop;


  dbms_output.put_line('=====================================================================');


END;
/


prompt
prompt All sql found in ASH:
prompt


Select ash.inst_id, session_id, session_serial#,
       ash.sql_id,
       sql_exec_id, 
       sql_opname,
       in_hard_parse,
       min(sample_Time) sql_start_time,
       max(sample_Time) sql_end_time,
       ((cast(max(sample_time)  As DATE)) - (cast(min(sample_time) as DATE))) * (3600*24) secs,
       ((cast(max(sample_time)  As DATE)) - (cast(min(sample_time) as DATE))) * (60*24) mins,
       max(temp_space_allocated)/(1024*1024) max_temp_mb,
       max(pga_allocated)/(1024*1024) max_pga_mb,
   regexp_replace( substr(sql_text, 0, 100), '[[:space:]]+', ' ') sql_text  
from   gv$active_session_history ash
left outer join GV$SQLAREA DHST on DHST.sql_id = ash.sql_id   and DHST.inst_id = ash.inst_id
where session_id = &SID
and   session_serial# = &SERIAL
and session_type = 'FOREGROUND'
group By ash.inst_id,session_id, session_serial#,  ash.sql_id, sql_exec_id, sql_opname, in_hard_parse, regexp_replace( substr(sql_text, 0, 100), '[[:space:]]+', ' ') 
order by sql_start_time;

prompt
prompt SQL Monitor :
prompt

COLUMN etime_min FORMAT 999,999.9;
COLUMN module FORMAT A20 TRUNCATE
COLUMN sid FORMAT 99999
COLUMN buffer_gets FORMAT 999,999,999,999
COLUMN username FORMAT A15
COLUMN sql_text FORMAT A200 TRUNCATE
COLUMN binds_xml FORMAT A300 TRUNCATE
COLUMN program FORMAT A20  TRUNCATE
COLUMN osuser FORMAT A10  TRUNCATE
COLUMN status Format A20 TRUNCATE;
COLUMN sql_id FORMAT A14
column sql_exec_start format A20
column phys_read_blocks format 999,999,999,999
column service_name format A20
column action format A40
column error_message format A100

select INST_ID, STATUS, USERNAME, MODULE,ACTION,  SERVICE_NAME, PROGRAM, SID, session_serial#,  PROCESS_NAME,  SQL_ID , sql_exec_id, SQL_EXEC_START ,SQL_PLAN_HASH_VALUE ,sQL_CHILD_ADDRESS , PX_SERVERS_ALLOCATED, PX_SERVER# , elapsed_time/1000000/60 etime_min,  BUFFER_GETS,  DISK_READS phys_read_blocks, ERROR_MESSAGE, regexp_replace(substr(sql_text, 1, 200), '[' || chr(10) || chr(13) || ']', ' ') ,BINDS_XML
 from gv$sql_monitor
where sid = &SID
and   session_serial# = &SERIAL
order by sql_exec_start;


prompt
prompt TEMP usage :
prompt

column temp_used_mb format 999,999,999
column total_temp_used_mb format 999,999,999
column workarea_size_mb format 999,999,999.9
column expected_size_mb format 999,999,999.9
column actual_mem_used_mb format 999,999,999.9
column max_mem_used_mb format 999,999,999.9
column client_info format A10
column machine format A30

prompt
prompt note sql_id is often wrong in v$tempseg_usage
prompt

WITH pivot1 AS
(
select value/(1024*1024) as block_size_mb from v$parameter where name = 'db_block_size' 
)
 SELECT sysdate, b.username, b.inst_id,  b.segtype, b.sql_id,  b.tablespace,
                                      b.blocks*(select block_size_mb from pivot1) temp_used_mb, 
                                      sum( b.blocks*(select block_size_mb from pivot1) ) over () total_temp_used_mb ,
                                      a.inst_id, a.username, a.sid, a.serial#, a.osuser,  a.process, a.machine, a.sql_id, a.prev_sql_id, a.module, a.client_info,
                                      '|',
                                      C.SQL_ID, C.SQL_EXEC_ID, C.ACTIVE_TIME, C.WORK_AREA_SIZE/(1024*1024) workarea_size_mb, C.EXPECTED_SIZE/1024/1024 expected_size_mb, C.ACTUAL_MEM_USED/1024/1024 actual_mem_used_mb, C.MAX_MEM_USED/1024/1024 max_mem_used_mb, C.NUMBER_PASSES, C.TEMPSEG_SIZE/(1024*1024) tempseg_mb
                --                      D.sql_text
FROM  gv$tempseg_usage b
inner JOIN gv$session a  ON b.inst_id = a.inst_id  and a.saddr = b.session_addr
left outer join gv$sql_workarea_active C ON b.inst_id = C.inst_id and  b.tablespace = C.tablespace and b.SEGRFNO# = C.SEGRFNO# and b.SEGBLK# = C.SEGBLK#
--left outer join gv$sqlarea D ON c.inst_id = D.inst_id AND  c.sql_id = D.sql_id 
 WHERE 
    a.sid = &SID  and a.serial# = &SERIAL;


prompt
prompt v$session_longops :
prompt

select distinct INST_ID, sid,serial#,username, opname, trunc(elapsed_seconds/60) etime_mins, trunc(time_remaining/60) remaining_mins, last_update_time, message
from gv$session_longops 
where sid = &SID
and serial# = &SERIAL
order by LAST_UPDATE_TIME ;


prompt
prompt V$SESSION_EVENT :
prompt

select inst_id, sid,   seq#, wait_class, event
from gv$session_wait
where sid = &SID;



prompt
prompt most recent events from ASH for &SID/&SERIAL
prompt



COLUMN top_level_call_name FORMAT A10
COLUMN program FORMAT A20
COLUMN module FORMAT A20
COLUMN action format A40
COLUMN client_id FORMAT A20
COLUMN machine   FORMAT A20
COLUMN wait_event FORMAT A30
column sample_time format A24
column sql_exec_start format A20


select * from
(
SELECT sample_time, user_id,  session_id, session_serial#, program, module, action, machine, event, sql_id, sql_exec_id, sql_opname, sql_exec_start,  sql_plan_hash_value, sql_plan_operation, sql_plan_options, sql_plan_line_id, session_state, event as wait_event, blocking_inst_id, blocking_session, blocking_session_serial#,
        row_number() over (order by sample_id desc) as sample_order
from gv$active_session_history
where session_id = &SID
and session_serial# = &SERIAL
and session_type = 'FOREGROUND'
)
where sample_order < 200
order by sample_order desc; 


PROMPT
prompt most recent SQL from AWR ASH data
prompt


define DAYS_AGO=1
WITH 
pivot1 as
(
select min(snap_id) AS begin_snap_id
from dba_hist_snapshot 
where trunc( begin_interval_time, 'DD')  > trunc(sysdate - &DAYS_AGO, 'DD')
AND  dbid = (select dbid from v$database)
)
Select instance_number as inst_id, session_id, session_serial#,
       sql_id,
       sql_exec_id, 
       sql_opname,
       in_hard_parse,
       min(sample_Time) sql_start_time,
       max(sample_Time) sql_end_time,
       ((cast(max(sample_time)  As DATE)) - (cast(min(sample_time) as DATE))) * (3600*24) secs,
       ((cast(max(sample_time)  As DATE)) - (cast(min(sample_time) as DATE))) * (60*24) mins,
       max(temp_space_allocated)/(1024*1024) max_temp_mb,
       max(pga_allocated)/(1024*1024) max_pga_mb
from   dba_hist_active_sess_history
where session_id = &SID
and   session_serial# = &SERIAL
and session_type = 'FOREGROUND'
and  snap_id > (select begin_snap_id from pivot1)
group By instance_number,session_id, session_serial#,  sql_id, sql_exec_id, sql_opname, in_hard_parse
order by sql_start_time;

