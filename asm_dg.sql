
-- general query on asm diskgroups

column total_gb format 999,999,999,999,999
column usable_file_gb format 999,999,999,999,999
column free_gb format 999,999,999,999,999
column name format A15
column group_number format 999
column compatibility format A20
column allocation_unit_size format 999,999,999
column used_gb format 999,999,999
column usable_gb format 999,999,999

SELECT group_number,
       name,
       type,
       allocation_unit_size,
       state,
       total_mb/1024 total_gb,
      (total_mb-free_mb)/1024 used_gb,
       free_mb/1024 free_gb,
      usable_file_mb/1024 usable_gb,
       offline_disks,
       compatibility, DATABASE_COMPATIBILITY
FROM V$ASM_DISKGROUP;


