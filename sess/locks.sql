
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


-- from Muralli Valath


column sid format 99999
column "serial#" format 99999
column id1 format 999999999999
column id2 format 999999999999
column ID1_OBJECT_NAME format A30
column type format A10
column name format A20
column command format A10

select distinct g.inst_id,
	g.type,
	s.username,
	s.sid,
	s.serial#,
    (select command_name from v$sqlcommand where command_type = S.command)   command,
     	    s.sql_id, 
            sql_exec_id, 
  p.PNAME,
	decode(lmode,0,'None',1,'Null',2,'Row-S',3,'Row-X',4,'Share',5,'S/ROW',6,'Exclusive') lmode,
	decode(lmode,0,'None',1,'Null',2,'Row-S',3,'Row-X',4,'Share',5,'S/ROW',6,'Exclusive') request,
        decode (request,0,'BLOCKER','WAITER') STATE,
       ctime,
        id1, 
        object_name as id1_object_name, 
       (select object_name from dba_objects where object_id = g.id1) name,
        id2,   regexp_replace( substr(sql_text, 0, 300), '[[:space:]]+', ' ') sql_text
from   
        gv$lock g
inner join	gv$session s 
  on 	g.sid = s.sid and	g.inst_id = s.inst_id 
left outer join dba_objects DO on DO.object_id = g.id1
left outer JOIN  gv$process p ON  s.paddr = p.addr and S.inst_id = P.inst_id
 left outer join GV$SQLAREA DHST on DHST.sql_id = S.sql_id   and DHST.inst_id = S.inst_id
where 
    s.type != 'BACKGROUND'
and s.username LIKE '&USERNAME'
and g.type like '&SQL_ID'
order by inst_id,sid,  STATE;
	
