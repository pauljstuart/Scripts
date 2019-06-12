column tablespace_name format a20 ;
column size_mb format 999,999,999,999.9  
column segment_name format A50
column total_ts_mb format 999,999,999.9





select tablespace_name, owner, segment_name, segment_type, bytes/1024/1024 as  size_mb, (sum(bytes) over ( ) )/1024/1024 total_ts_mb
from dba_segments 
where tablespace_name like '&1';


