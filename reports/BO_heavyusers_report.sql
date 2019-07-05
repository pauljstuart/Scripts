

-- finding BO queries from v$session :

select distinct SID, SERIAL#,
      username ,
      regexp_substr( dbms_LOB.substr(sql_fulltext, 300, dbms_lob.getlength(sql_FULLtext) - 300) ,q'#AppUserName='([a-z]+[0-9]*)+',.*#', 1,1,'i', 1) as BO_user,
      regexp_substr( dbms_LOB.substr(sql_fulltext, 300, dbms_lob.getlength(sql_FULLtext) - 300) ,q'#AppName='(.*)',AppUserName.*#', 1,1,'i', 1) as report_name,
      SM.sql_id, 
         plan_hash_value,
      sql_exec_start as px_start_time
from gv$session SM 
left outer join gv$sqlarea DHST on DHST.sql_id = SM.sql_id and DHST.inst_id = SM.inst_id
where status = 'ACTIVE'
AND sm.SQL_ID IS NOT NULL AND SM.SQL_EXEC_ID IS NOT NULL AND USERNAME IS NOT NULL;


alter session set nls_timestamp_format='DY dd/mm/yyyy hh24:mi.FF';
alter session set nls_date_format='DY dd/mm/yyyy hh24:mi.SS';

column  px_start_time format A20
column  px_end_time format A20
column px_phys_total_gb format 999,999,999,999
column  px_temp_gb format 999,999,999,999
column parallel_deg format 999
COLUMN PX_ETIME_MINS FORMAT 999,999
column bo_user format A10
column oracle_username format A15
column report_name format A50
column parallel_instances format A20 


-- finding BO queries from the AWR :

--set sqlformat csv
with
pivot2 as
(
select  
      instance_number ,
      user_id, 
      session_id,
      session_serial#,
      sql_id, 
      sql_exec_id,
      sql_exec_start , 
      sql_plan_hash_value,
      MAX(sample_time) sql_end_time, 
      (CAST(MAX(sample_time)  AS DATE) - CAST( SQL_EXEC_START AS DATE)) * 60*24 etime_mins ,
	     sum(nvl(delta_write_io_bytes, 0) + nvl(delta_read_io_bytes, 0))/(1024*1024*1024)   phys_total_gb,
       max(temp_space_allocated)/(1024*1024*1024) max_temp_gb
from dba_hist_active_sess_history 
WHERE  
     session_type = 'FOREGROUND'
and     snap_id > (select min(snap_id) from dba_hist_snapshot where begin_interval_time  > trunc(sysdate - &DAYS_AGO, 'DD') AND  dbid = (select dbid from v$database) )
AND  SQL_EXEC_ID IS NOT NULL
and sql_opname = 'SELECT'
and user_id in (select user_id from dba_users where username  LIKE '%BO%')
group by  instance_number, user_id, session_id, session_serial#,   sql_id,  sql_exec_id, sql_exec_start,    sql_plan_hash_value
)
select
      username as oracle_username,
      regexp_substr( dbms_LOB.substr(sql_text, 300, dbms_lob.getlength(sql_text) - 300) ,q'#AppUserName='([a-z]+[0-9]*)+)',.*#', 1,1,'i', 1) as BO_user,
      regexp_substr( dbms_LOB.substr(sql_text, 300, dbms_lob.getlength(sql_text) - 300) ,q'#AppName='(.*)',AppUserName.*#', 1,1,'i', 1) as report_name,
      SM.sql_id, 
         sql_plan_hash_value,
      sql_exec_start as px_start_time, 
      max(sql_end_time) as px_end_time,
      max(etime_mins)  px_etime_mins ,
    sum(   phys_total_gb ) px_phys_total_gb,
    sum(max_temp_gb)   px_temp_gb,
    count(*) parallel_deg,
     lpad(  LISTAGG(instance_number, ',') WITHIN GROUP (ORDER BY instance_number) , 20) as parallel_instances
from pivot2 SM 
inner join dba_users DU on DU.user_id = SM.user_id
left outer join dba_hist_sqltext DHST on DHST.sql_id = SM.sql_id
group by username, SM.sql_id, sql_exec_id, sql_exec_start,    sql_plan_hash_value,regexp_substr( dbms_LOB.substr(sql_text, 300, dbms_lob.getlength(sql_text) - 300) ,q'#AppUserName='([a-z]+)',.*#', 1,1,'i', 1) ,  regexp_substr( dbms_LOB.substr(sql_text, 300, dbms_lob.getlength(sql_text) - 300) ,q'#AppName='(.*)',AppUserName.*#', 1,1,'i', 1)
--,dbms_lob.substr(sql_text, 4000)
having max(etime_mins) > 30
order by  sum(   phys_total_gb )  desc
--order by sum(max_temp_mb) desc
--order by max(etime_mins) desc
/
set sqlformat default
