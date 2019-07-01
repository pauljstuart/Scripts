

-- (c) Kyle Hailey 2007


column name for A20
column program for a25
column CPU for 9999
column IO for 9999
column TOTAL for 99999
column WAIT for 9999
column user_id for 99999
column sid for 9999



select
        decode(nvl(to_char(s.sid),-1),-1,'DISCONNECTED','CONNECTED')
                                                        "STATUS",
        topsession.sid             "SID",
        u.username  "NAME",
        topsession.program                  "PROGRAM",
        max(topsession.CPU)              "CPU",
        max(topsession.WAIT)       "WAITING",
        max(topsession.IO)                  "IO",
        max(topsession.TOTAL)           "TOTAL"
        from (
select * from (
select
     ash.session_id sid,
     ash.session_serial# serial#,
     ash.user_id user_id,
     ash.program,
     sum(decode(ash.session_state,'ON CPU',1,0))     "CPU",
     sum(decode(ash.session_state,'WAITING',1,0))    -
     sum(decode(ash.session_state,'WAITING',
        decode(wait_class,'User I/O',1, 0 ), 0))    "WAIT" ,
     sum(decode(ash.session_state,'WAITING',
        decode(wait_class,'User I/O',1, 0 ), 0))    "IO" ,
     sum(decode(session_state,'ON CPU',1,1))     "TOTAL"
from gv$active_session_history ash
group by session_id,user_id,session_serial#,program
order by sum(decode(session_state,'ON CPU',1,1)) desc
) where rownum < 10
   )    topsession,
        v$session s,
        all_users u
   where
        u.user_id =topsession.user_id and
        /* outer join to v$session because the session might be disconnected */
        topsession.sid         = s.sid         (+) and
        topsession.serial# = s.serial#   (+)
   group by  topsession.sid, topsession.serial#,
             topsession.user_id, topsession.program, s.username,
             s.sid,s.paddr,u.username
   order by max(topsession.TOTAL) desc
/


