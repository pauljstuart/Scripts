rem
rem Show tablespace storage parameters
rem
rem  By Paul Stuart
rem June 2003
rem Oct 2004
rem July 2012




COLUMN  max_extents FORMAT 99,999,999,999 
COLUMN  tablespace_name FORMAT a25
COLUMN  status FORMAT A10
COLUMN  logging FORMAT A5
COLUMN  extent_management FORMAT A15 
COLUMN  allocation_type  FORMAT A15  
COLUMN   segment_space_management FORMAT A20 
COLUMN  contents FORMAT A20
COLUMN next_ext_mb format 999,999
COLUMN initial_ext_mb format 999,999
COLUMN min_ext_mb format 999,999

column pct_increase format 999.9


select tablespace_name, contents, extent_management ,
      allocation_type ,
      bigfile,
      block_size,
      segment_space_management, 
      initial_extent/(1024*1024) initial_ext_mb, 
      next_extent/(1024*1024) next_ext_mb, 
      pct_increase , 
      min_extlen/(1024*1024) min_ext_MB, 
      status
from dba_tablespaces
order by 2;

prompt 
prompt Segment Management :
prompt MANUAL = Freelists.
prompt AUTO = Bitmaps
prompt
prompt Allocation Type :		
prompt     SYSTEM = Autoallocate (System allocated) 
prompt     UNIFORM = Uniform Sizes
prompt     USER = Dictionary Managed 
prompt



