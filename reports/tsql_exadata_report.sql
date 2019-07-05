

column delta format 999,999,999,999,999
column bytes format 999,999,999,999,999
column bytes_sec format 999,999,999,999,999
column value format 999,999,999,999,999
COLUMN MODULE_NAME FORMAT A30
COLUMN NAME FORMAT a60

DEFINE MY_SCHEMA=PERF_SUPPORT

define SQL_ID=&1
define SQL_EXEC_ID=&2
      

prompt
prompt Exadata stats :
prompt



with 
stats AS 
(
                  select sn.name, sum(value) as value
                  from gv$sesstat ss
                  inner join v$statname sn on sn.statistic# = ss.statistic#
                  where sid in ( select sid from gv$sql_monitor where sql_id =  '&SQL_ID' and sql_exec_id = &SQL_EXEC_ID )
                  and value != 0
                  group by sn.name
),
 sq AS (
            SELECT
                *
            FROM (
                SELECT
                    0 inst_id
                  , 0 sid
                  , CASE WHEN TRIM(name) IN (
                        'cell physical IO bytes sent directly to DB node to balance CPU'
                      , 'cell physical IO bytes pushed back due to excessive CPU on cell'
                      , 'cell physical IO bytes sent directly to DB node to balanceCPU u'
                    ) THEN
                        'cell physical IO bytes sent directly to DB node to balance CPU'
                    ELSE name
                    END name
                  , value
                FROM
                    --gv$sesstat NATURAL JOIN v$statname
                    stats
                WHERE
                   1=1
                -- AND (name LIKE 'cell%bytes%' OR name LIKE 'physical%bytes%')
                AND TRIM(name) IN (
                     'physical read total bytes'                                 
                   , 'physical write total bytes'                                
                   , 'physical read total bytes optimized'                       
                   , 'cell physical IO bytes eligible for predicate offload'     
                   , 'cell physical IO interconnect bytes'                       
                   , 'cell physical IO interconnect bytes returned by smart scan'
                   , 'cell physical IO bytes saved by storage index'             
                   , 'cell IO uncompressed bytes'                                
                   , 'cell blocks processed by cache layer'                      
                   , 'cell blocks processed by txn layer'                        
                   , 'cell blocks processed by data layer'                       
                   , 'cell blocks processed by index layer'                      
                   , 'db block gets from cache'                                  
                   , 'consistent gets from cache' 
                   , 'db block gets direct'                                  
                   , 'consistent gets direct' 
                   -- following three stats are the same thing (named differently in different versions)
                   , 'cell physical IO bytes sent directly to DB node to balance CPU'
                   , 'cell physical IO bytes pushed back due to excessive CPU on cell'
                   , 'cell physical IO bytes sent directly to DB node to balanceCPU u'                               
                   , 'bytes sent via SQL*Net to client'
                   , 'bytes received via SQL*Net from client'
                   , 'table fetch continued row'
                   , 'chained rows skipped by cell'
                   , 'chained rows processed by cell'
                   , 'chained rows rejected by cell'
                )
            )
)
select * from sq
union
SELECT 0,0, 'Cell Offload Efficiency %', ((select value from stats where name = 'cell physical IO bytes eligible for predicate offload') - (select value from stats where name = 'cell physical IO interconnect bytes returned by smart scan'))*100/(select value from stats where name = 'cell physical IO bytes eligible for predicate offload') as value
from dual;

prompt
prompt Tanel Report
prompt


WITH 
pivot0 as ( select 2 as lv_asm_mirrors, (select DELTA_VALUE from t_sql where STAT_NUMBER = 4099 and MODULE_NAME = '&MODULE_STRING' ) as snap_seconds from dual)
, 
stats AS 
(
                  select sn.name, sum(value) as value
                  from gv$sesstat ss
                  inner join v$statname sn on sn.statistic# = ss.statistic#
                  where sid in ( select sid from gv$sql_monitor where sql_id =  '&SQL_ID' and sql_exec_id = &SQL_EXEC_ID )
                  and value != 0
                  group by sn.name
),
 sq AS (
            SELECT
                *
            FROM (
                SELECT
                    0 inst_id
                  , 0 sid
                  , CASE WHEN TRIM(name) IN (
                        'cell physical IO bytes sent directly to DB node to balance CPU'
                      , 'cell physical IO bytes pushed back due to excessive CPU on cell'
                      , 'cell physical IO bytes sent directly to DB node to balanceCPU u'
                    ) THEN
                        'cell physical IO bytes sent directly to DB node to balance CPU'
                    ELSE name
                    END name
                  , value
                FROM
                    --gv$sesstat NATURAL JOIN v$statname
                    stats
                WHERE
                   1=1
                -- AND (name LIKE 'cell%bytes%' OR name LIKE 'physical%bytes%')
                AND TRIM(name) IN (
                     'physical read total bytes'                                 
                   , 'physical write total bytes'                                
                   , 'physical read total bytes optimized'                       
                   , 'cell physical IO bytes eligible for predicate offload'     
                   , 'cell physical IO interconnect bytes'                       
                   , 'cell physical IO interconnect bytes returned by smart scan'
                   , 'cell physical IO bytes saved by storage index'             
                   , 'cell IO uncompressed bytes'                                
                   , 'cell blocks processed by cache layer'                      
                   , 'cell blocks processed by txn layer'                        
                   , 'cell blocks processed by data layer'                       
                   , 'cell blocks processed by index layer'                      
                   , 'db block gets from cache'                                  
                   , 'consistent gets from cache' 
                   , 'db block gets direct'                                  
                   , 'consistent gets direct' 
                   -- following three stats are the same thing (named differently in different versions)
                   , 'cell physical IO bytes sent directly to DB node to balance CPU'
                   , 'cell physical IO bytes pushed back due to excessive CPU on cell'
                   , 'cell physical IO bytes sent directly to DB node to balanceCPU u'                               
                   , 'bytes sent via SQL*Net to client'
                   , 'bytes received via SQL*Net from client'
                   , 'table fetch continued row'
                   , 'chained rows skipped by cell'
                   , 'chained rows processed by cell'
                   , 'chained rows rejected by cell'
                )
            )
            PIVOT (
                SUM(value)
            FOR name IN (
                    'physical read total bytes'                                      AS phyrd_bytes
                  , 'physical write total bytes'                                     AS phywr_bytes
                  , 'physical read total bytes optimized'                            AS phyrd_optim_bytes
                  , 'cell physical IO bytes eligible for predicate offload'          AS pred_offloadable_bytes
                  , 'cell physical IO interconnect bytes'                            AS interconnect_bytes 
                  , 'cell physical IO interconnect bytes returned by smart scan'     AS smart_scan_ret_bytes
                  , 'cell physical IO bytes saved by storage index'                  AS storidx_saved_bytes
                  , 'cell IO uncompressed bytes'                                     AS uncompressed_bytes
                  , 'cell blocks processed by cache layer'                           AS cell_proc_cache_blk
                  , 'cell blocks processed by txn layer'                             AS cell_proc_txn_blk
                  , 'cell blocks processed by data layer'                            AS cell_proc_data_blk
                  , 'cell blocks processed by index layer'                           AS cell_proc_index_blk
                  , 'db block gets from cache'                                       AS curr_gets_cache_blk
                  , 'consistent gets from cache'                                     AS cons_gets_cache_blk
                  , 'db block gets direct'                                           AS curr_gets_direct_blk
                  , 'consistent gets direct'                                         AS cons_gets_direct_blk
                  , 'cell physical IO bytes sent directly to DB node to balance CPU' AS cell_bal_cpu_bytes
                  , 'bytes sent via SQL*Net to client'                               AS net_to_client_bytes
                  , 'bytes received via SQL*Net from client'                         AS net_from_client_bytes
                  , 'table fetch continued row'                                      AS chain_fetch_cont_row
                  , 'chained rows skipped by cell'                                   AS chain_rows_skipped
                  , 'chained rows processed by cell'                                 AS chain_rows_processed
                  , 'chained rows rejected by cell'                                  AS chain_rows_rejected
                ) 
            ) 
        )
,
        precalc AS (
            SELECT 
                inst_id
              , sid
              , (phyrd_bytes)                                                   db_physrd_BYTES
              , (phywr_bytes)                                                   db_physwr_BYTES
              , (phyrd_bytes+phywr_bytes)                                       db_physio_BYTES
              , pred_offloadable_bytes                                          pred_offloadable_BYTES
              , phyrd_optim_bytes                                               phyrd_optim_BYTES
              , (phyrd_optim_bytes-storidx_saved_bytes)                         phyrd_flash_rd_BYTES
              , storidx_saved_bytes                                             phyrd_storidx_saved_BYTES
              , (phyrd_bytes-phyrd_optim_bytes)                                 spin_disk_rd_BYTES
              , (phyrd_bytes-phyrd_optim_bytes+(phywr_bytes*( select lv_asm_mirrors from pivot0)))    spin_disk_io_BYTES
              , uncompressed_bytes                                              scanned_uncomp_BYTES
              , interconnect_bytes                                              total_ic_BYTES
              , smart_scan_ret_bytes                                            smart_scan_ret_BYTES
              , (interconnect_bytes-smart_scan_ret_bytes)                       non_smart_scan_BYTES
              , (cell_proc_cache_blk  * (select value from v$parameter where name = 'db_block_size'))                           cell_proc_cache_BYTES
              , (cell_proc_txn_blk    * (select value from v$parameter where name = 'db_block_size'))                           cell_proc_txn_BYTES
              , (cell_proc_data_blk   * (select value from v$parameter where name = 'db_block_size'))                           cell_proc_data_BYTES
              , (cell_proc_index_blk  * (select value from v$parameter where name = 'db_block_size'))                           cell_proc_index_BYTES
              , (curr_gets_cache_blk  * (select value from v$parameter where name = 'db_block_size'))                           curr_gets_cache_BYTES
              , (cons_gets_cache_blk  * (select value from v$parameter where name = 'db_block_size'))                           cons_gets_cache_BYTES
              , (curr_gets_direct_blk * (select value from v$parameter where name = 'db_block_size'))                           curr_gets_direct_BYTES
              , (cons_gets_direct_blk * (select value from v$parameter where name = 'db_block_size'))                           cons_gets_direct_BYTES
              , cell_bal_cpu_bytes                                              cell_bal_cpu_BYTES
              , net_to_client_bytes                                             net_to_client_BYTES
              , net_from_client_bytes                                           net_from_client_BYTES
              , chain_fetch_cont_row
              , chain_rows_skipped
              , chain_rows_processed
              , chain_rows_rejected
              , (chain_rows_skipped    * (select value from v$parameter where name = 'db_block_size'))                           chain_blocks_skipped
              , (chain_rows_processed  * (select value from v$parameter where name = 'db_block_size'))                           chain_blocks_processed
              , (chain_rows_rejected   * (select value from v$parameter where name = 'db_block_size'))                           chain_blocks_rejected
            FROM sq
        ),
precalc2 AS (
            SELECT
                inst_id
              , sid
              , db_physio_BYTES
              , db_physrd_BYTES
              , db_physwr_BYTES
              , pred_offloadable_BYTES
              , phyrd_optim_BYTES
              , phyrd_flash_rd_BYTES + spin_disk_rd_BYTES phyrd_disk_and_flash_BYTES
              , phyrd_flash_rd_BYTES
              , phyrd_storidx_saved_BYTES
              , spin_disk_io_BYTES
              , spin_disk_rd_BYTES
              , ((spin_disk_io_BYTES - spin_disk_rd_BYTES)) AS spin_disk_wr_BYTES
              , scanned_uncomp_BYTES
              , ROUND((scanned_uncomp_BYTES/NULLIF(phyrd_flash_rd_BYTES+spin_disk_rd_BYTES, 0))*db_physrd_BYTES) est_full_uncomp_BYTES 
              , total_ic_BYTES
              , smart_scan_ret_BYTES
              , non_smart_scan_BYTES
              , cell_proc_cache_BYTES
              , cell_proc_txn_BYTES
              , cell_proc_data_BYTES
              , cell_proc_index_BYTES
              , cell_bal_cpu_BYTES
              , curr_gets_cache_BYTES
              , cons_gets_cache_BYTES
              , curr_gets_direct_BYTES
              , cons_gets_direct_BYTES
              , net_to_client_BYTES
              , net_from_client_BYTES
              , chain_fetch_cont_row
              , chain_rows_skipped
              , chain_rows_processed
              , chain_rows_rejected
              , chain_blocks_skipped
              , chain_blocks_processed
              , chain_blocks_rejected
            FROM
                precalc
        )
,
        unpivoted AS (
            SELECT * FROM precalc2
            UNPIVOT (
                    BYTES
                FOR metric
                IN (
                    phyrd_optim_BYTES
                  , phyrd_disk_and_flash_BYTES
                  , phyrd_flash_rd_BYTES
                  , phyrd_storidx_saved_BYTES
                  , spin_disk_rd_BYTES
                  , spin_disk_wr_BYTES
                  , spin_disk_io_BYTES
                  , db_physrd_BYTES 
                  , db_physwr_BYTES
                  , db_physio_BYTES
                  , scanned_uncomp_BYTES
                  , est_full_uncomp_BYTES
                  , non_smart_scan_BYTES
                  , smart_scan_ret_BYTES
                  , total_ic_BYTES
                  , pred_offloadable_BYTES
                  , cell_proc_cache_BYTES
                  , cell_proc_txn_BYTES
                  , cell_proc_data_BYTES
                  , cell_proc_index_BYTES
                  , cell_bal_cpu_BYTES
                  , curr_gets_cache_BYTES
                  , cons_gets_cache_BYTES
                  , curr_gets_direct_BYTES
                  , cons_gets_direct_BYTES
                  , net_to_client_BYTES
                  , net_from_client_BYTES
                  , chain_fetch_cont_row
                  , chain_rows_skipped
                  , chain_rows_processed
                  , chain_rows_rejected
                  , chain_blocks_skipped
                  , chain_blocks_processed
                  , chain_blocks_rejected
                )
            )
        )
,
        metric AS (
            SELECT 'BASIC' type,          '2 DB_LAYER_IO' category,    'DB_PHYSIO_BYTES' name             FROM dual UNION ALL             
            SELECT 'BASIC',               '2 DB_LAYER_IO',             'DB_PHYSRD_BYTES'                  FROM dual UNION ALL
            SELECT 'BASIC',               '2 DB_LAYER_IO',             'DB_PHYSWR_BYTES'                  FROM dual UNION ALL
            SELECT 'ADVANCED',            '4 AVOID_DISK_IO',           'PHYRD_OPTIM_BYTES'                FROM dual UNION ALL
            SELECT 'ADVANCED',            '4 AVOID_DISK_IO',           'PHYRD_DISK_AND_FLASH_BYTES'       FROM dual UNION ALL
            SELECT 'BASIC',               '4 AVOID_DISK_IO',           'PHYRD_FLASH_RD_BYTES'             FROM dual UNION ALL 
            SELECT 'BASIC',               '4 AVOID_DISK_IO',           'PHYRD_STORIDX_SAVED_BYTES'        FROM dual UNION ALL
            SELECT 'BASIC',               '5 REAL_DISK_IO',            'SPIN_DISK_IO_BYTES'               FROM dual UNION ALL
            SELECT 'BASIC',               '5 REAL_DISK_IO',            'SPIN_DISK_RD_BYTES'               FROM dual UNION ALL
            SELECT 'BASIC',               '5 REAL_DISK_IO',            'SPIN_DISK_WR_BYTES'               FROM dual UNION ALL
            SELECT 'ADVANCED',            'COMPRESS',                'SCANNED_UNCOMP_BYTES'             FROM dual UNION ALL
            SELECT 'ADVANCED',            'COMPRESS',                'EST_FULL_UNCOMP_BYTES'            FROM dual UNION ALL
            SELECT 'BASIC',               '2 REDUCE_INTERCONNECT',     'PRED_OFFLOADABLE_BYTES'           FROM dual UNION ALL
            SELECT 'BASIC',               '2 REDUCE_INTERCONNECT',     'TOTAL_IC_BYTES'                   FROM dual UNION ALL
            SELECT 'BASIC',               '2 REDUCE_INTERCONNECT',     'SMART_SCAN_RET_BYTES'             FROM dual UNION ALL
            SELECT 'BASIC',               '2 REDUCE_INTERCONNECT',     'NON_SMART_SCAN_BYTES'             FROM dual UNION ALL
            SELECT 'ADVANCED',            'CELL_PROC_DEPTH',         'CELL_PROC_CACHE_BYTES'            FROM DUAL UNION ALL
            SELECT 'ADVANCED',            'CELL_PROC_DEPTH',         'CELL_PROC_TXN_BYTES'              FROM DUAL UNION ALL
            SELECT 'BASIC',               'CELL_PROC_DEPTH',         'CELL_PROC_DATA_BYTES'             FROM DUAL UNION ALL
            SELECT 'BASIC',               'CELL_PROC_DEPTH',         'CELL_PROC_INDEX_BYTES'            FROM DUAL UNION ALL
            SELECT 'ADVANCED',            'CELL_PROC_DEPTH',         'CELL_BAL_CPU_BYTES'               FROM DUAL UNION ALL
            SELECT 'ADVANCED',            '1 IN_DB_PROCESSING',        'CURR_GETS_CACHE_BYTES'            FROM DUAL UNION ALL
            SELECT 'ADVANCED',            '1 IN_DB_PROCESSING',        'CONS_GETS_CACHE_BYTES'            FROM DUAL UNION ALL
            SELECT 'ADVANCED',            '1 IN_DB_PROCESSING',        'CURR_GETS_DIRECT_BYTES'           FROM DUAL UNION ALL
            SELECT 'ADVANCED',            '1 IN_DB_PROCESSING',        'CONS_GETS_DIRECT_BYTES'           FROM DUAL UNION ALL
            SELECT 'BASIC',               '7 CLIENT_COMMUNICATION',    'NET_TO_CLIENT_BYTES'              FROM DUAL UNION ALL
            SELECT 'BASIC',               '7 CLIENT_COMMUNICATION',    'NET_FROM_CLIENT_BYTES'            FROM DUAL UNION ALL
            SELECT 'ADVANCED',            'FALLBACK_TO_BLOCK_IO',    'CHAIN_FETCH_CONT_ROW'             FROM DUAL UNION ALL
            SELECT 'ADVANCED',            'FALLBACK_TO_BLOCK_IO',    'CHAIN_ROWS_SKIPPED'               FROM DUAL UNION ALL
            SELECT 'ADVANCED',            'FALLBACK_TO_BLOCK_IO',    'CHAIN_ROWS_PROCESSED'             FROM DUAL UNION ALL
            SELECT 'ADVANCED',            'FALLBACK_TO_BLOCK_IO',    'CHAIN_ROWS_REJECTED'              FROM DUAL UNION ALL
            SELECT 'ADVANCED',            'FALLBACK_TO_BLOCK_IO',    'CHAIN_BLOCKS_SKIPPED'             FROM DUAL UNION ALL
            SELECT 'ADVANCED',            'FALLBACK_TO_BLOCK_IO',    'CHAIN_BLOCKS_PROCESSED'           FROM DUAL UNION ALL
            SELECT 'ADVANCED',            'FALLBACK_TO_BLOCK_IO',    'CHAIN_BLOCKS_REJECTED'            FROM DUAL 
        )
        SELECT
         --   inst_id
         -- , sid
         -- , type
            category
          , metric
          , bytes
          , bytes_sec
          --, seconds_in_snap 
        FROM (
            SELECT 
                inst_id
              , sid
              , type
              , category
              , metric
              , bytes
              , BYTES / (SELECT snap_seconds FROM pivot0) bytes_sec
              , (SELECT decode(snap_seconds , 0, NULL, snap_seconds) FROM pivot0 ) seconds_in_snap 
            FROM
                unpivoted u
              , metric m
            WHERE
                u.metric = m.name
        )
      order by category;
      



