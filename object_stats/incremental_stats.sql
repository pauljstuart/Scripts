Hello Srijith,

You're right actually.  I did a bit more reading, and I discussed it with Doug Burns too.

My confusion was this : you don't get any benefit from the incremental option when gathering 
stats initially at the table level.  In fact, as oracle has to create the synopses needed for the incremental option, stats gathering at
the tabel level may well take longer than without.

You do gather global table and partitions stats of course, but you only do it once.


What you do is :

1.	Set INCREMENTAL option on for your table
2.	Gather global and partitioned statistics on the table using GRANULARITY => GLOBAL AND PARTITION
3.	Add a new partition and populate it
4.	Gather statistics again, but this time explicitly referencing the partition you just created.
ie partname => 'NEW_PART', and still use granularity => 'GLOBAL AND PARTITION'
5.	You will find that stats were gathered on the partition, and also updated globally too.

Your global table stats are now up to date, and yet you didnt have to gather global stats again
on the whole table.

regards

Paul Stuart

-----------------------------------------------------------------------------------------------------------------------------------------

Hi Nikhil,

Lets setup incremental stats on MV_BO_B3PILLAR3_CUBE.   

This is how it will work.  

1.	enable incremental statistics on the table :

begin
  dbms_stats.set_table_prefs(tabname => 'MV_BO_B3PILLAR3_CUBE',
        ownname  => 'APP_BO_STAGE',
       pname => 'INCREMENTAL',
    pvalue => 'TRUE');
end;
/

2.	 re-gather stats on the table :

begin
  dbms_stats.gather_table_stats( ownname => 'APP_BO_STAGE', tabname => 'MV_BO_B3PILLAR3_CUBE', 
                    method_opt => 'FOR ALL COLUMNS SIZE 1', 
                    DEGREE => 128, 
                    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE ,
                    no_invalidate => FALSE,
                    granularity => 'GLOBAL AND PARTITION' );
end;
/

This command will take quite a few hours, as per the weekend job.

Then, once you have added or modified a partition, you just update them. You change your current 'partition stats' command to be just this :

3.	Command to run in code when partition added.  

begin
  dbms_stats.gather_table_stats( ownname => 'APP_BO_STAGE', tabname => 'MV_BO_B3PILLAR3_CUBE', degree => 8);
end;
/

And, that is it.  That command should not take long - the global stats are updated and you don't need to run them on the weekend at all.

And, obviously we would need to remove the MV_BO_B3PILLAR3_CUBE from your weekend stats job.

Let's try it in test first, so I can check if it's working properly.
