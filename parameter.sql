
COLUMN name FORMAT a30
COLUMN value FORMAT a200
COLUMN display_value FORMAT A50

define SEARCH=&1


prompt
prompt parameters with &1 :
prompt

SELECT inst_id, NAME, VALUE, isdefault
FROM gv$parameter
where name like '%&SEARCH%';


prompt
prompt underscore parameters with &1 :
prompt

SELECT inst_id, NAME, VALUE, isdefault
FROM gv$parameter
where name like '\_%SEARCH%' escape '\';
