-- convert from CET timezone to UTC


with t as (
           select to_timestamp_tz('05/10/2015 17:00 +2:00','mm/dd/yyyy hh24:mi TZH:TZM') ts_cet from dual
          )
select ts_cet,
         ts_cet at time zone 'UTC' ts_utc
  from t
/
