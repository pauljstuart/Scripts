SELECT table_name,
       TO_NUMBER (
          EXTRACTVALUE (
             xmltype (
                DBMS_XMLGEN.getxml ('select count(*) X from gglas.' || table_name)),
             '/ROWSET/ROW/X'))
          COUNT
  FROM all_tables



-- and with partitions :




SELECT table_name, partition_name,
       TO_NUMBER (
          EXTRACTVALUE (
             xmltype (    DBMS_XMLGEN.getxml('select count(*) X from mrp.' || table_name || ' partition(' || partition_name || ')' )      ),    '/ROWSET/ROW/X'))
          COUNT
  FROM ALL_TAB_PARTITIONS where TABLE_owner = 'MRP' AND TABLE_NAME = 'TMP$ORG_UNIT_NODE';


-- advanced one with partitions :


with pivot1 as
(
SELECT table_name, partition_name,
  DBMS_XMLGEN.getxml('select  dbid, min(snap_id) X , max(snap_id) Y  from SYS.' || table_name || ' partition ( ' ||  partition_name || ' )  group by dbid' )   as xml_out
  FROM ALL_TAB_PARTITIONS  where TABLE_owner = 'SYS' AND TABLE_NAME = 'WRH$_ACTIVE_SESSION_HISTORY'
)
select table_name, partition_name,  
   case when xml_out is not null then to_number( EXTRACTVALUE(  xmltype(xml_out) , '/ROWSET/ROW/DBID')  )  end as DBID,
   case when xml_out is not null then to_number( EXTRACTVALUE(  xmltype(xml_out) , '/ROWSET/ROW/X')  ) end as min_snap,
   case when xml_out is not null then to_number( EXTRACTVALUE(  xmltype(xml_out) , '/ROWSET/ROW/Y')  ) end as max_snap
from pivot1


