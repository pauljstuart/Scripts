

COLUMN parameter FORMAT A30
COLUMN final_size FORMAT 999,999,999,999;


col P1 new_value 1 format A10
col P2 new_value 2 format A10
column end_time format A21

select null p1, null p2 from dual where 1=2;
select nvl( '&1','%') p1, nvl('&2','%') p2 from dual ;

define SEARCH=&1  

undefine 1
undefine 2


prompt 
prompt The full history for &SEARCH:
prompt

select 
       inst_id,parameter, final_size, status, end_time
  from gv$sga_resize_ops
where 
  status = 'COMPLETE'
and parameter like '&SEARCH'
order by end_time asc;


prompt
prompt  The most recent update for each parameter :
prompt

with pivot as 
(
select 
       inst_id,parameter, final_size, status, end_time, row_number() over ( partition by inst_id,parameter order by end_time desc) rank
  from gv$sga_resize_ops
where 
  status = 'COMPLETE'
order by parameter, end_time asc
)
select * from pivot
where rank = 1
and parameter like '&SEARCH'
order by inst_id
