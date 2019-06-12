--
--
--
--
--
-- Dec 04


prompt Parallel processes :

select * from v$px_process;

select * from v$px_session;




SELECT NAME, VALUE FROM GV$SYSSTAT
WHERE UPPER (NAME) LIKE '%PARALLEL OPERATIONS%'
OR UPPER (NAME) LIKE '%PARALLELIZED%'
OR UPPER (NAME) LIKE '%PX%';



