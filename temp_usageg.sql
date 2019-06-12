/*#########################################
## Script is from Tanel Poder tools
## changed for globalization 
## and changed the script to use v$tempseg_usage 
## instead of v$sort_usage
##
## Commented out scripts are due to misleading info 
## because of bug Bug 7210183: 
#########################################*/


col sid_serial format a10
col username format a17
col osuser format a15
col module format a15
col pid format 999999
col program format a30
col service_name format a15
col mb_used format 999999.999
col mb_total format 999999.999
col tablespace format a15
col statements format 999
col hash_value format 99999999999
col sql_text format a50

prompt 
prompt #####################################################################
prompt #######################GLOBAL TEMP USAGE#############################
prompt #####################################################################
prompt 
 
 SELECT   A.inst_id,A.tablespace_name tablespace, D.mb_total,
SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM     gv$sort_segment A,
(
SELECT   B.INST_ID,B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
FROM     gv$tablespace B, gv$tempfile C
WHERE    B.ts#= C.ts#
and c.inst_id=b.inst_id
GROUP BY B.INST_ID,B.name, C.block_size
) D
WHERE    
A.tablespace_name = D.name
and A.inst_id=D.inst_id
GROUP by a.inst_id,A.tablespace_name, D.mb_total;

prompt 
prompt #####################################################################
prompt #######################GLOBAL TEMP USERS#############################
prompt #####################################################################
prompt 

SELECT   S.INST_ID,S.sid || ',' || S.serial# sid_serial, S.username, S.osuser, 
P.spid pid, 
s.service_name,
--S.module,
--P.program, 
T.segtype ,
SUM (T.blocks)* TBS.block_size / 1024 / 1024 mb_used, T.tablespace,
COUNT(*) statements
FROM     gv$tempseg_usage T, gv$session S, dba_tablespaces TBS, gv$process P
WHERE    T.session_addr = S.saddr
AND      S.paddr = P.addr
AND	 s.inst_id=p.inst_id
and	 t.inst_id=p.inst_id
and	 s.inst_id=t.inst_id
AND      T.tablespace = TBS.tablespace_name
having SUM (T.blocks) * TBS.block_size / 1024 / 1024>10
GROUP BY 
s.inst_id,
S.sid, 
S.serial#, S.username, 
S.osuser, P.spid, 
S.Service_name,
--S.module,
--P.program, 
TBS.block_size, T.tablespace,segtype
ORDER BY mb_used;

prompt 
prompt #####################################################################
prompt #######################GLOBAL ACTIVE SQLS ###########################
prompt #####################################################################
prompt 

 SELECT sysdate "TIME_STAMP", vs.inst_id,vsu.username, vs.sid, vp.spid, vs.sql_id, vst.sql_text,vsu.segtype, vsu.tablespace,
        sum_blocks*dt.block_size/1024/1024 usage_mb
    FROM
    (
            SELECT inst_id,username, sqladdr, sqlhash, sql_id, segtype,tablespace, session_addr,
                 sum(blocks) sum_blocks
            FROM gv$tempseg_usage
	    group by inst_id,username, sqladdr, sqlhash, sql_id, segtype,tablespace, session_addr
    ) "VSU",
    gv$sqltext vst,
    gv$session vs,
    gv$process vp,
    dba_tablespaces dt
 WHERE vs.sql_id = vst.sql_id
    AND vsu.session_addr = vs.saddr
    AND VSU.INST_ID=vst.inst_id
    and vs.inst_id=vsu.inst_id
    and vp.inst_id=vs.inst_id
    and vp.inst_id=vsu.inst_id
    and vp.inst_id=vst.inst_id
    AND vs.paddr = vp.addr
    AND vst.piece = 0
    AND vs.status='ACTIVE'
    AND dt.tablespace_name = vsu.tablespace
 order by usage_mb;





prompt 
prompt #####################################################################
prompt #######################GLOBAL TEMP SQLS##############################
prompt #####################################################################
prompt 

SELECT  s.inst_id,S.sid || ',' || S.serial# sid_serial, S.username, Q.hash_value, Q.sql_text,
T.blocks * TBS.block_size / 1024 / 1024 mb_used, T.tablespace
FROM    gv$tempseg_usage T, gv$session S, gv$sqlarea Q, dba_tablespaces TBS
WHERE   T.session_addr = S.saddr
and t.inst_id=s.inst_id
and q.inst_id=s.inst_id
and t.inst_id=q.inst_id
AND     T.sqladdr = Q.address
AND     T.tablespace = TBS.tablespace_name
and T.blocks * TBS.block_size / 1024 / 1024>10
ORDER BY mb_used;


prompt 
prompt #####################################################################
prompt ####################### TEMP SPACE HEADER ##############################
prompt #####################################################################
prompt 


SELECT tablespace_name, SUM(bytes_used)/(1024*1024) "Used MB", SUM(bytes_free)/(1024*1024) "Free MB"
FROM   gV$temp_space_header
GROUP  BY tablespace_name;
