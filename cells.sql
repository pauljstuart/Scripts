

column cell_name format A20

select distinct cell_name from gv$cell_state;



COL cv_cellname       HEAD CELL_NAME        FOR A20
COL cv_cell_path      HEAD CELL_PATH        FOR A20
COL cv_cellversion    HEAD CELLSRV_VERSION  FOR A20
COL cv_flashcachemode HEAD FLASH_CACHE_MODE FOR A20

PROMPT Show Exadata cell versions from V$CELL_CONFIG....

SELECT
    cellname cv_cell_path
  , CAST(extract(xmltype(confval), '/cli-output/cell/name/text()') AS VARCHAR2(20))  cv_cellname
  , CAST(extract(xmltype(confval), '/cli-output/cell/releaseVersion/text()') AS VARCHAR2(20))  cv_cellVersion 
  , CAST(extract(xmltype(confval), '/cli-output/cell/flashCacheMode/text()') AS VARCHAR2(20))  cv_flashcachemode
  , CAST(extract(xmltype(confval), '/cli-output/cell/cpuCount/text()')       AS VARCHAR2(10))  cpu_count
  , CAST(extract(xmltype(confval), '/cli-output/cell/upTime/text()')         AS VARCHAR2(20))  uptime
  , CAST(extract(xmltype(confval), '/cli-output/cell/kernelVersion/text()')  AS VARCHAR2(30))  kernel_version
  , CAST(extract(xmltype(confval), '/cli-output/cell/makeModel/text()')      AS VARCHAR2(50))  make_model
FROM 
    v$cell_config  -- gv$ isn't needed, all cells should be visible in all instances
WHERE 
    conftype = 'CELL'
ORDER BY
    cv_cellname
/
