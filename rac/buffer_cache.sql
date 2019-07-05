

column c1 heading "Object|Name"                 format a30
column c2 heading "Object|Type"                 format a12
column c3 heading "Number of|Blocks"            format 999,999,999,999
column c4 heading "Percentage|of object|data blocks|in Buffer" format 999


with  t1 as
(
select
   o.object_name    object_name,
   o.object_type    object_type,
   count(1)         num_blocks
from
   dba_objects  o,
   v$bh         bh
where
   o.object_id  = bh.objd
and
   o.owner not in ('SYS','SYSTEM')
group by
   o.object_name,
   o.object_type
order by
   count(1) desc
)
select
   object_name       c1,
   object_type       c2,
   num_blocks        c3,
   (num_blocks/decode(sum(blocks), 0, .001, sum(blocks)))*100 c4
from
   t1,
   dba_segments s
where
   s.segment_name = t1.object_name
and
   num_blocks > 10
group by
   object_name,
   object_type,
   num_blocks
order by
   num_blocks desc
;
