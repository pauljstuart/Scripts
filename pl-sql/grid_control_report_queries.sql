
-------------------------------------------------------------------------
-- getting the instantaneous values for a metric
-------------------------------------------------------------------------

column tablespace_name format A30;
column target_name format A30
column value format 90.00 justify right ;

select target_name,  key_value2 as tablespace_name,  to_number(value) as value_pct
from mgmt$metric_current
where
   target_name in ( select member_target_name from MGMT$TARGET_MEMBERS where aggregate_target_name = 'PRD' and MEMBER_TARGET_TYPE = 'rac_database')
  and metric_label =  'User-Defined SQL Metrics'
  and column_label = 'Undo Tablespace Space Used (%)'
  order by target_name, tablespace_name ;

select target_name,  key_value2 as tablespace_name,  to_number(value) as value_pct
from mgmt$metric_current
where
   target_name in ( select member_target_name from MGMT$TARGET_MEMBERS where aggregate_target_name = 'PRD' and MEMBER_TARGET_TYPE = 'rac_database')
  and metric_label =  'User-Defined SQL Metrics'
  and column_label = 'Temporary Tablespace Space Used (%)'
  order by target_name, tablespace_name ;
  

-------------------------------------------------------------------------
-- getting members from a group
-------------------------------------------------------------------------

select member_target_name from MGMT$TARGET_MEMBERS
where aggregate_target_name = 'PRD' and MEMBER_TARGET_TYPE = 'rac_database';


-------------------------------------------------------------------
-- get a User Defined Metric value
-------------------------------------------------------------------


column target_name format A20
column tablespace_name format A20

select target_name, rollup_timestamp, key_value2 as tablespace_name,  maximum
from mgmt$metric_hourly
where
  rollup_timestamp > sysdate - 7
  and target_name in ( 'PRD20MSV', 'PRD10GTW', 'PRD10INT', 'PRD10MIS')
  and metric_label =  'User-Defined SQL Metrics'
  and column_label = 'Temporary Tablespace Space Used (%)'
  order by target_name, tablespace_name, rollup_timestamp ;



-------------------------------------------------------------------
-- get all the hosts which run an oracle instance :
-------------------------------------------------------------------

SELECT host_name, system_config, cpu_count
FROM   MGMT$OS_HW_SUMMARY
where  host_name in (SELECT HOST_NAME 
                     FROM   MGMT$TARGET
                     WHERE  TARGET_TYPE = 'oracle_database')
order by 1




SELECT A.TARGET_NAME TARGET_NAME_ID,A.TYPE_DISPLAY_NAME TARGET_TYPE_ID,
	A.COLUMN_LABEL METRIC_ID,A.ALERT_STATE SEVERITY_ID,
	A.MESSAGE MESSAGE_ID 
FROM MGMT$ALERT_CURRENT A,MGMT$TARGET B
        WHERE A.TARGET_GUID=B.TARGET_GUID                   
        AND A.violation_type in('Resource','Threshold Violation') 
and (A.column_label like 'Filesystem Space Available%'or A.column_label like 'Archive Area Used%')  and A.ALERT_STATE in ('Critical','Warning')
	ORDER BY A.collection_timestamp desc



SELECT A.TARGET_NAME TARGET_NAME_ID,
        A.TYPE_DISPLAY_NAME TARGET_TYPE_ID,
	A.COLUMN_LABEL METRIC_ID, 
        A.ALERT_STATE SEVERITY,
       MGMT_VIEW_UTIL.ADJUST_TZ(A.COLLECTION_TIMESTAMP,B.TIMEZONE_REGION,??EMIP_BIND_TIMEZONE_REGION??) OPEN_SINCE_ID,
	A.MESSAGE MESSAGE_ID 
from MGMT$ALERT_CURRENT A,MGMT$TARGET B 
where A.TARGET_GUID=B.TARGET_GUID AND 
	A.violation_type in('Resource','Threshold Violation') and A.ALERT_STATE in ('Critical')
AND A.violation_guid not in (select SOURCE_OBJ_GUID  from  mgmt$alert_annotations where annotATION_TYPE = 'ACKNOWLEDGED' )
	order by collection_timestamp


General File System Alerts :


SELECT A.TARGET_NAME TARGET_NAME_ID,A.TYPE_DISPLAY_NAME TARGET_TYPE_ID,
	A.COLUMN_LABEL METRIC_ID,A.ALERT_STATE SEVERITY_ID,
	A.MESSAGE MESSAGE_ID 
FROM MGMT$ALERT_CURRENT A,MGMT$TARGET B
        WHERE A.TARGET_GUID=B.TARGET_GUID                   
        AND A.violation_type in('Resource','Threshold Violation') 
and (A.column_label like 'Filesystem Space Available%'or A.column_label like 'Archive Area Used%' or A.column_label like 'Volume Used%')  and A.ALERT_STATE in ('Critical','Warning')
	ORDER BY A.collection_timestamp desc






unavailable targets :



select target_name, availability_status  from  mgmt$availability_current where availability_status not in ('Target Up','Blackout')
AND TARGET_GUID in 
         (
         SELECT target_guid
         FROM   MGMT$TARGET t, MGMT$TARGET_MEMBERS m
         WHERE  m.aggregate_target_name in  ('PRD', 'UAT')
         AND  t.TARGET_GUID = m.MEMBER_TARGET_GUID 
       )
       

Outstanding Tablespace Alerts


DECLARE
             TYPE CURSOR_TYPE IS REF CURSOR;
             result_cursor_out CURSOR_TYPE;
             tgt_guid_in   RAW(16);
             start_date_in DATE DEFAULT NULL;
             end_date_in  DATE DEFAULT NULL;
             query_string   VARCHAR(6000);
          BEGIN
              result_cursor_out := ??EMIP_BIND_RESULTS_CURSOR??;
              tgt_guid_in := ??EMIP_BIND_TARGET_GUID??;
              start_date_in := ??EMIP_BIND_START_DATE??;
              end_date_in := ??EMIP_BIND_END_DATE??;
            
          query_string := 
            ' SELECT
                T.TARGET_GUID,
                t.target_name AS DATABASE_NAME,
                 ac.alert_state AS SEVERITY,
                 ac.key_value AS TABLESPACE,
                 round(substr(ac.value_param, 1,
                             (decode(instr(ac.value_param,'' '',1),
                              0, decode(instr(ac.value_param,''&'',-1), 0, length(ac.value_param),instr(ac.value_param,''&'',-1)),
                              instr(ac.value_param,'' '',1)) -1)
                       ),2) AS USED_PERCENT,
                 ac.collection_timestamp as ALERT_TRIGGERED,
                 round(sysdate - ac.collection_timestamp,2) AS DAYS_OPEN
               FROM 
                 (SELECT target_guid, metric_name, metric_column, 
                         key_value, alert_state,
                         substr(message_params, instr(message_params,''&'',1)+1, 
                                                length(message_params)-1) as value_param,
                         collection_timestamp
                    FROM mgmt$alert_current) ac,
                 (SELECT target_guid, target_name
                    FROM mgmt$target
                    WHERE (target_type=''rac_database'' OR 
                            (target_type=''oracle_database'' AND TYPE_QUALIFIER3 != ''RACINST''))) t
               WHERE
                  ac.target_guid=t.target_guid AND
                 (ac.metric_name=''problemTbsp'' OR ac.metric_name=''problemTbsp10iDct'') AND
                 ac.metric_column=''pctUsed'' 
                   AND AC.TARGET_GUID in 
         (
         SELECT target_guid
         FROM   MGMT$TARGET t, MGMT$TARGET_MEMBERS m
         WHERE  m.aggregate_target_name in (''PRD_MSV'', ''PRD20_MSV'',''PRD10_MSV'', ''UAT_MSV'')
         AND  t.TARGET_GUID = m.MEMBER_TARGET_GUID 
       )     ';
                 
          OPEN result_cursor_out for query_string ;
      
      END;
      
      
------------------------------------------------------------------------------------------------
-- get the Instance IO throughput (mbps) for each instance
-----------------------------------------------------------------------------------------------
      

select * from mgmt_metrics
 where column_label like 'I/O Megabytes (per second)';
 
      
select target_name, collection_timestamp, value 
FROM (
      select BB.target_guid, BB.target_name, AA.collection_timestamp, RANK() OVER (PARTITION BY BB.target_guid ORDER BY AA.collection_timestamp DESC) dest_rank, AA.value
      from mgmt_metrics_raw AA,   (
               SELECT target_guid,target_name 
               FROM   MGMT$TARGET t, MGMT$TARGET_MEMBERS m
               WHERE  m.aggregate_target_name in ('UAT', 'PRD')
               AND  t.TARGET_GUID = m.MEMBER_TARGET_GUID 
               AND  t.target_type = 'oracle_database'
             )  BB
      where  BB.TARGET_GUID = AA.target_guid
      and AA.metric_guid = 'DB1E7076108F6D5898B69F2AD2EDA216'
      and collection_timestamp > sysdate -1/(24) 
) where dest_rank = 1
order by target_name;


-- Instance IO, average hourly

column average format 999,999.9 heading "Avg MB/sec";
column target_name format A30;

      select BB.target_name, AA.rollup_timestamp,AA.average
      from mgmt$metric_hourly AA,   (
               SELECT target_guid,target_name
               FROM   MGMT$TARGET t, MGMT$TARGET_MEMBERS m
               WHERE  m.aggregate_target_name in ('PRE')
               AND  t.TARGET_GUID = m.MEMBER_TARGET_GUID 
               AND  t.target_type = 'oracle_database'
             )  BB
      where  BB.TARGET_GUID = AA.target_guid
      and AA.metric_guid = 'DB1E7076108F6D5898B69F2AD2EDA216'
     and rollup_timestamp > sysdate - 2
     and average > 1
order by 1, 2;
