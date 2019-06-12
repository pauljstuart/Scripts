


set heading off
REM   Run this logged in to user with SYSDBA privs ideal
REM
REM   Runs against 10g Release 2/ 11g




col start_up format a45 justify right
col sp_size     format          999,999,999 justify right
col x_sp_used   format          999,999,999 justify right
col sp_used_shr format          999,999,999 justify right
col sp_used_per format          999,999,999 justify right
col sp_used_run format          999,999,999 justify right
col sp_avail    format          999,999,999 justify right
col sp_sz_pins format           999,999,999 justify right
col sp_no_pins format           999,999 justify right
col sp_no_obj format            999,999 justify right
col sp_no_stmts format          999,999 justify right
col sp_sz_kept_chks format      999,999,999 justify right
col sp_no_kept_chks format      999,999 justify right
col 1time_sum_pct     format      999 justify right
col 1time_ttl_pct   format        999 justify right
col ltime_ttl     format   999,999,999 justify right
col 1time_sum     format      999,999,999,999 justify right
col tot_lc format  999,999,999,999 justify right
col sp_free format 999,999,999,999 justify right

col val1 new_val x_sgasize noprint
col val2 new_val x_sp_size noprint
col val3 new_val x_lp_size noprint
col val4 new_val x_jp_size noprint
col val5 new_val x_bc_size noprint
col val6 new_val x_other_size noprint
col val7 new_val x_str_size noprint
col val8 new_val x_KGH noprint
select val1, val2, val3, val4, val5, val6, val7, val8
from (select sum(bytes) val1 from gv$sgainfo where name='Maximum SGA Size') s1,
    (select nvl(sum(bytes),0) val2 from gv$sgastat where pool='shared pool') s2,
    (select nvl(sum(bytes),0) val3 from gv$sgastat where pool='large pool') s3,
    (select nvl(sum(bytes),0) val4 from gv$sgastat where pool='java pool') s4,
    (select nvl(sum(bytes),0) val5 from gv$sgastat where name='buffer_cache') s5,
    (select nvl(sum(bytes),0) val6 from gv$sgastat where name in ('log_buffer','fixed_sga')) s6,
    (select nvl(sum(bytes),0) val7 from gv$sgastat where pool='streams pool') s7,
    (select nvl(sum(bytes),0) val8 from gv$sgastat where pool='shared pool' and name='KGH: NO ACCESS') s8;

col val1 new_val x_sp_used noprint
col val2 new_val x_sp_used_shr noprint
col val3 new_val x_sp_used_per noprint
col val4 new_val x_sp_used_run noprint
col val5 new_val x_sp_no_stmts noprint
col val6 new_val x_sp_vers noprint
select sum(sharable_mem+persistent_mem+runtime_mem) val1,
            sum(sharable_mem) val2, sum(runtime_mem) val4, sum(persistent_mem) val3,
            count(*) val5, max(version_count) val6
from   gv$sqlarea;

col val1 new_val x_1time_sum noprint
col val2 new_val x_1time_ttl noprint
select sum(sharable_mem+persistent_mem+runtime_mem) val1,
   count(*) val2
from   gv$sqlarea
where executions=1;

col val1 new_val x_ra noprint
select round(nvl((used_space+free_space),0),2) val1
from gv$shared_pool_reserved;

col val2 new_val x_sp_no_obj noprint
select count(*) val2 from gv$db_object_cache; 

col val2 new_val x_sp_no_kept_chks noprint
col val3 new_val x_sp_sz_kept_chks noprint
select decode(count(*),'',0,count(*)) val2,
       decode(sum(sharable_mem),'',0,sum(sharable_mem)) val3
from   gv$db_object_cache
where  kept='YES';

col val2 new_val x_sp_free_chks noprint
select sum(bytes) val2 from gv$sgastat
where name='free memory' and pool='shared pool';

col val2 new_val x_sp_no_pins noprint
select count(*) val2
from gv$session a, gv$sqltext b
where a.sql_address||a.sql_hash_value = b.address||b.hash_value;

col val2 new_val x_sp_sz_pins noprint
select sum(sharable_mem+persistent_mem+runtime_mem) val2
from   gv$session a,
       gv$sqltext b,
       gv$sqlarea c
where  a.sql_address||a.sql_hash_value = b.address||b.hash_value and
       b.address||b.hash_value = c.address||c.hash_value;

col val3 new_val x_tot_lc noprint
select nvl(sum(lc_inuse_memory_size)+sum(lc_freeable_memory_size),0) val3 
from gv$library_cache_memory;

col val2 new_val x_sp_avail noprint
select &x_sp_size-(&x_tot_lc*1024*1024)-&x_sp_used val2
from   dual;

col val2 new_val x_sp_other noprint
select &x_sp_size-(&x_tot_lc*1024*1024) val2 
from dual;

col val1 new_val x_trend_4031 noprint
col val2 new_val x_trend_size noprint
col val3 new_val x_trend_rS noprint
col val4 new_val x_trend_rs_size noprint
select request_misses val1,
decode(request_misses,0,0,last_Miss_Size) val2,
request_failures val3,
decode(request_failures,0,0,last_failure_size) val4
from gv$shared_pool_reserved;

col instance_number new_value x_inst_id noprint
col start_time1 new_value x_start_time noprint
col instance_name new_value x_inst_name noprint

SELECT instance_number FROM v$instance;
SELECT to_char(startup_time, 'Mon/dd/yyyy hh24:mi:ss') start_time1 FROM v$instance;
select instance_name from v$instance;


SET heading OFF

clear screen




REM
REM  SQL Area Statistics
REM
REM   runs on 8i/9i/9.2/10g/11g

set serveroutput on;
declare
   MaxInv   number(15);
   MaxVers  number(11);
   MaxVCNT  number(15);
   MaxShare number(15);

   cursor code is select max(invalidations), max(loaded_versions), max(version_count), 
                         MAX(sharable_mem) FROM v$sqlarea;

begin
   open code;
   fetch code into MaxInv, MaxVers, MaxVCNT, MaxShare;

   dbms_output.put_line('SQL Area Statistics : ' );
   dbms_output.put_line(' ' );
   dbms_output.put_line('===========================================================');
   dbms_output.put_line('HWM Information:');
   dbms_output.put_line('----- Max Invalidations:      '||to_char(MaxInv,'999,999,999,999'));
   dbms_output.put_line('----- Max Versions Loaded:        '||to_char(MaxVers,'999,999,999'));
   dbms_output.put_line('----- Versions HWM:           '||to_char(MaxVCNT,'999,999,999,999'));
   dbms_output.put_line('----- Largest Memory object:  '||to_char(MaxShare,'999,999,999,999'));
   dbms_output.put_line('============================================================');
  dbms_output.put_line(         '                                    ');
  dbms_output.put_line(         '                                    ');
end;
/





BEGIN


dbms_output.put_line('============================================================');

dbms_output.put_line(         '                                    ');
dbms_output.put_line(        'Instance Name :     &x_inst_name') ;
dbms_output.put_line(        'Database Started:  &x_start_time' );
dbms_output.put_line(         '                                    ');

dbms_output.put_line(        ' *** If database started recently, this data is not as useful ***' );
dbms_output.put_line(        ' ' );
dbms_output.put_line(        '   Breakdown of SGA           '||round((&x_sgasize/1024/1024),2)||'M   ' );
dbms_output.put_line(        '   Shared Pool Size                 : '  ||round((&x_sp_size/1024/1024),2)||'M (' ||round((&x_sp_size/&x_sgasize)*100,0)||'%)  Reserved '    ||round((&x_ra/1024/1024),2)||'M ('  ||round((&x_ra/&x_sp_size)*100,0)||'%)' );
dbms_output.put_line(        '   Large Pool                       : '||round((&x_lp_size/1024/1024),2)||'M (' ||round((&x_lp_size/&x_sgasize)*100,0)||'%)' );
dbms_output.put_line(        '   Java Pool                        : '||round((&x_jp_size/1024/1024),2)||'M ('   ||round((&x_jp_size/&x_sgasize)*100,0)||'%)' );
dbms_output.put_line(        '   Buffer Cache                     : '||round((&x_bc_size/1024/1024),2)||'M (' ||round((&x_bc_size/&x_sgasize)*100,0)||'%)' );
dbms_output.put_line(        '   Streams Pool                     : '||round((&x_str_size/1024/1024),2)||'M ('   ||round((&x_str_size/&x_sgasize)*100,0)||'%)' );
dbms_output.put_line(        '   Other Areas in SGA               : '||round((&x_other_size/1024/1024),2)||'M ('  ||round((&x_other_size/&x_sgasize)*100,0)||'%)' );


dbms_output.put_line( ' ');
dbms_output.put_line( ' ' );
dbms_output.put_line(   ' *** High level breakdown of memory ***' );
dbms_output.put_line(     '     sharable                      :  ' ||round((&x_sp_used_shr/1024/1024),2)||'M' );
dbms_output.put_line(        '     persistent                    :  '     ||round((&x_sp_used_per/1024/1024),2)||'M' );
dbms_output.put_line(        '     runtime                       :  '  ||round((&x_sp_used_run/1024/1024),2)||'M' );


dbms_output.put_line( ' ');
dbms_output.put_line( ' ' );
dbms_output.put_line(   'SQL Memory Usage (total)                     : '   ||round((&x_sp_used/1024/1024),2)||'M ('   ||round((&x_sp_used/&x_sp_size)*100,0)||'%)' );
dbms_output.put_line(     '    ' );
dbms_output.put_line(     ' *** No guidelines on SQL in Library Cache, but if pinning a lot of code--may need larger Shared Pool ***' ) ;
dbms_output.put_line(        '# of SQL statements                : '   ||&x_sp_no_stmts  );
dbms_output.put_line(        '# of pinned SQL statements         : '  ||&x_sp_no_pins  );
dbms_output.put_line(        '# of programmatic constructs       : '  ||&x_sp_no_obj  );
dbms_output.put_line(        '# of pinned programmatic construct : '  ||&x_sp_no_kept_chks );

dbms_output.put_line( ' ');
dbms_output.put_line( ' ' );

dbms_output.put_line(         'Efficiency Analysis:                     ');
dbms_output.put_line(        ' *** High versions (100s) could be bug ***');
dbms_output.put_line(         '                                    ');
dbms_output.put_line(         '  Max Child Cursors Found                              : '||&x_sp_vers);
dbms_output.put_line(         '  Programmatic construct memory size (Kept)            : '  ||round((&x_sp_sz_kept_chks/1024/1024),2)||'M' );
dbms_output.put_line(         '  Pinned SQL statements memory size (active sessions)  : '  ||round((&x_sp_sz_pins/1024/1024),2)||'M' );
dbms_output.put_line(         '                                    ');
dbms_output.put_line(         ' *** LC at 50% or 60% of Shared Pool not uncommon ***');
dbms_output.put_line(         '                                    ');
dbms_output.put_line(         '  Estimated Total Library Cache Memory Usage  : '||&x_tot_lc||'M ('||   100*(round(((&x_tot_lc) / (&x_sp_size/1024/1024)),2))||'%)' );       
dbms_output.put_line(         '  Other Shared Pool Memory                    : '||  round((&x_sp_other/1024/1024),2)||'M');
dbms_output.put_line(         '  Shared Pool Free Memory Chunks              : '||  round(((&x_sp_free_chks) /1024/1024),2)||'M ('||  100*(round((&x_sp_free_chks / &x_sp_size),2))||'%)' );
dbms_output.put_line(         '                                    ');
dbms_output.put_line(         ' ****Ideal percentages for 1 time executions is 20% or lower****     ');
dbms_output.put_line(         '                                    ');
dbms_output.put_line(         '  # of objects executed only 1 time           : '||&x_1time_ttl||' ('||   100*round(((&x_1time_ttl / &x_sp_no_stmts)),2)||'%)');
dbms_output.put_line(         '  Memory for 1 time executions:               : '||  round((&x_1time_sum/1024/1024),2)||'M ('|| 100*round(((&x_1time_sum / &x_sp_used)),2)||'%)');
dbms_output.put_line(         '                                    ');
dbms_output.put_line(         '  ***If these chunks are growing, SGA_TARGET may be too low***');
dbms_output.put_line(         '                                    ');
dbms_output.put_line(         '  Current KGH: NO ACCESS Allocations:  '||round((&x_KGH/1024/1024),2)||'M (' ||100*round((&x_KGH/&x_sp_size),2)||'%)');
dbms_output.put_line(         '                                    ');
dbms_output.put_line(         ' ***0 misses is ideal, but if growing value points to memory issues***');
dbms_output.put_line(         '                                    ');
dbms_output.put_line(         '  # Of Misses for memory                      : '|| &x_trend_rs);
dbms_output.put_line(         '  Size of last miss                           : '|| &x_trend_rs_size);
dbms_output.put_line(         '  # Of Misses for Reserved Area               : '|| &x_trend_4031);
dbms_output.put_line(         '  Size of last miss Reserved Area             : '|| &x_trend_size);
 

dbms_output.put_line( ' ');
dbms_output.put_line( ' ' );

dbms_output.put_line('============================================================');
dbms_output.put_line('============================================================');
END;
/


prompt
prompt Calculating Library Cache Ratios : 
prompt


SET heading ON

select sum(pins) pins,
       sum(pinhits) pinhits,
       sum(reloads) reloads,
       sum(invalidations) invalidations,
       100-(sum(pinhits)/sum(pins)) *100 reparsing_pct
FROM v$librarycache;





