

-- other things to turn off :

begin
  sqltxadmin.sqlt$a.set_param('c_gran_cols','GLOBAL'); 
  sqltxadmin.sqlt$a.set_param('c_gran_hgrm','GLOBAL'); 
  sqltxadmin.sqlt$a.set_param('c_gran_segm','GLOBAL'); 

-- turning off the STA and test case builder :

  sqltxplain.sqlt$a.set_param('sql_tuning_advisor', 'N'); 
  sqltxplain.sqlt$a.set_param('test_case_builder', 'N'); 
  sqltxplain.sqlt$a.set_param('sta_time_limit_secs', '30'); 

-- turning off more stuff

  sqltxadmin.sqlt$a.set_sess_param('skip_metadata_for_object','%');
  SQLTXPLAIN.sqlt$a.set_sess_param('count_star_threshold',0);

  sqltxadmin.sqlt$a.set_param('export_repository','N');

  sqltxadmin.sqlt$a.set_param('connect_identifier','@MVDSP1');
end;
/


-- setting the connect identifier :

exec sqltxadmin.sqlt$a.set_param('connect_identifier','@MVDSP1');

-- running the express extract :

@sqltxprext.sql 9dkhnvs9tjrdt		    stuartp

-- running the usual extract

@sqltxtract.sql 73bwzc948mn99	 "Merival1!"


@sqltxtract.sql 1fd76bnsyvraj "asde34##2frg"


-- running XTRXEC method :
    
START sqltxtrxec.sql 73bwzc948mn99  "Merival1!"

-- running the SQL health check script


@sqlhc.sql T 1wks0cznqb6nn

T=Tuning and Diagnostic pack 

-- monitoring :

SELECT * FROM SQLTXADMIN.sqlt$_log_v;


--------------------------------------------------------

when using SQLT  and the tables which are accessed are very large then SQLT can take quite a while. This is because SQLT internally does a select count(*) on the tables which 
are accessed. In the resulting SQLT report you see then the result of this query in the section "Tables". For each table this count is reported along with the value from the data dictionary. In the data dictionary this is the value of the num_rows column in dba_tables which is taken here.

As you can imagine a select count(*) will take a long time when for example one of the tables accessed has 100 000 000 rows. 

But SQLT also works without this check. Theres a parameter in SQLT for this check which is called count_star_threshold. Just set this parameter to 0.

You can set parameters in SQLT in 2 ways, once permanently and once just for the next SQLT session.

In order to permanently set this tool parameter :

connect as SQLTXPLAIN and issue: 

SQL> EXEC sqlt$a.set_param('count_star_threshold', 0);


-- custom sql profile :

EXEC SQLTXADMIN.sqlt$a.set_param('custom_sql_profile', 'Y');


--If you want to set the parameter just for a session connect as the application user and issue: 

SQL> EXEC SQLTXPLAIN.sqlt$a.set_sess_param('count_star_threshold',0);

Current SQLT tool parameter settings are visible in SQLT report in section "Tool Configuration Parameters".

Hope this helps.


-- to see the progress of an analysis run :


SELECT * FROM sqltxadmin.sqlt$_log_v;



 Hi Paul,


There are several factors affecting the size of the repository, the top consumers usually are
 1. Number of objects involved in the SQL (including if the object is (sub)partitioned)
 2. Number of plans available for the SQL (for each plan we collect many info)
 3. History of the parameters change (which by default is limited to just a few days)
 4. ASH data (which by default is limited to just a few days) 


Ie. About the (sub)partitioned objects, by default we collect all the info (properties, object stats, column stats, histograms, etc) at each level and in case of many (sub)partitions this can take quite some time / space
You can configure SQLT to turn off any specific operation that accounts for time / space, the list of options is in Tool Configuration Parameters in the MAIN report.


Please keep in mind that all those info are important for the investigation and the repository is designed to store them all so that when you upload a SQLT zip file to a SR then the analyst has all the info he needs 


--
-- purging from the repository 
-- 

Regarding how to manage it, you can purge the history using script sqlthistpurge.sql user /sqlt/utl 
Such script performs a DELETE so the space won't be returned by default but you'll be able to run SQLT again with no troubles


as the application owner :

 @sqlthistpurge.sql


SQL>SELECT STATEMENT_ID FROM SQLT$_SQL_STATEMENT ;

STATEMENT_ID
------------
       10296
       10297
       10298
       10295
       10299


----------------------------------------------------------------------

 Hi Paul,


I'm sorry if I wasn't clear.
Such SQL is *not* coming from the SQLT TC, it's coming from DBMS_METADATA, those metadata are later on used in the SQLT TC too (but not only for that).
About sqltxrexet.sql , it doesn't turn off the SQLT TC, it only turns off the Testcase Builder (TCB) that is another testcase provided by SQLT (there are 3 TC in total, SQLT TC, SQLT TCX and TCB).


It's not possible to disable the metadata collection via any SQLT parameters (it would prevent too many useful info from being collected) but in case you want to skip some object then parameter "skip_metadata_for_object" can help.
Since for this exceptional case you prefer to skip all the objects then you can use value '%' for such parameter


To disable the metadata collection for every object *for just this session* you can use
EXEC sqltxadmin.sqlt$a.set_sess_param('skip_metadata_for_object','%');


while to disable permanently (I discourage it)
 EXEC sqltxadmin.sqlt$a.set_param('skip_metadata_for_object','%'); 


Thanks,
Mauro



other things to turn off :


SQL> exec sqltxadmin.sqlt$a.set_param('c_gran_cols','GLOBAL'); 
SQL> exec sqltxadmin.sqlt$a.set_param('c_gran_hgrm','GLOBAL'); 
SQL> exec sqltxadmin.sqlt$a.set_param('c_gran_segm','GLOBAL'); 



-- turning off the STA and test case builder :

EXEC sqltxplain.sqlt$a.set_param('sql_tuning_advisor', 'N'); 
 EXEC sqltxplain.sqlt$a.set_param('test_case_builder', 'N'); 
 EXEC sqltxplain.sqlt$a.set_param('sta_time_limit_secs', '30'); 
 
------------------------------------------------------------------------




Hello Mauro,

Excellent thanks, that makes sense.

Another - unrelated - question :

Once your XTRACT run is complete, the data sits inside the repository, with the statement ids, which we discussed earlier with the purge.

My question is :  is it possible to generate the sqlt_XXX_main.html report from the repository directly - again -  without re-invoking the sqlxtract.sql script?

regards


Paul Stuart



  

Reply  |  Edit  |  Upload attachments  |  Report abuse 

no rating 0 0 
 
 
 
 

Newbie 
12 points 


Mauro Pagano - Oracle  14. August 15, 2013 5:44 PM  in response to: PaulStuart 
Re: SQTXPLAIN: Dealing with Long Execution Times     

  Hi Paul,


Yes the file is actually already stored in the repository, you can extract it using script sqlthistfile.sql in sqlt/utl
The instructions are in the file itself


Thanks,
Mauro 
 


------------------------------------------------------------------------------------------------------------
