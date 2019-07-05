



SET SERVEROUTPUT ON
DECLARE
STATUS VARCHAR2(20);
   DSTART DATE;
 DSTOP DATE;
PVALUE NUMBER;
 PNAME VARCHAR2(30);
BEGIN

PNAME := 'sreadtim';
   DBMS_STATS.GET_SYSTEM_STATS(status, dstart, dstop, pname, pvalue);
   DBMS_OUTPUT.PUT_LINE('single block readtime in ms : '||pvalue);

PNAME := 'iotfrspeed';
DBMS_STATS.GET_SYSTEM_STATS(status, dstart, dstop, pname, pvalue);
DBMS_OUTPUT.PUT_LINE('I/O transfer speed in bytes for each millisecond : '|| pvalue);

PNAME := 'ioseektim';
DBMS_STATS.GET_SYSTEM_STATS(status, dstart, dstop, pname, pvalue);
DBMS_OUTPUT.PUT_LINE('seek time + latency time + operating system overhead time, in milliseconds '|| pvalue);


PNAME := 'sreadtim';
DBMS_STATS.GET_SYSTEM_STATS(status, dstart, dstop, pname, pvalue);
DBMS_OUTPUT.PUT_LINE('average time to read single block (random read), in milliseconds : '||pvalue);


PNAME := 'mreadtim';
DBMS_STATS.GET_SYSTEM_STATS(status, dstart, dstop, pname, pvalue);
DBMS_OUTPUT.PUT_LINE('average time to read an mbrc block at once (sequential read), in millisecond : '||pvalue);


PNAME := 'cpuspeed';
DBMS_STATS.GET_SYSTEM_STATS(status, dstart, dstop, pname, pvalue);
DBMS_OUTPUT.PUT_LINE('average number of CPU cycles for each second, in millions : '||pvalue);


PNAME := 'mbrc';
DBMS_STATS.GET_SYSTEM_STATS(status, dstart, dstop, pname, pvalue);
DBMS_OUTPUT.PUT_LINE('average multiblock read count for sequential read, in blocks : '||pvalue);


PNAME := 'maxthr';
DBMS_STATS.GET_SYSTEM_STATS(status, dstart, dstop, pname, pvalue);
DBMS_OUTPUT.PUT_LINE('maximum I/O system throughput, in bytes/second : '||pvalue);


PNAME := 'slavethr';
DBMS_STATS.GET_SYSTEM_STATS(status, dstart, dstop, pname, pvalue);
DBMS_OUTPUT.PUT_LINE('average slave I/O throughput, in bytes/second : '||pvalue);



END;
/
