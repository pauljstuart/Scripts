
clear screen

column link_name format A20
column queue_manager format A30
column hostname format A30
column channel format A20

select * from mgw_mqseries_links;
