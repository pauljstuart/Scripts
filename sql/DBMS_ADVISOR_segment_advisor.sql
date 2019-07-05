



@tablespaces;

-- running the segment Advisor over a tablespace


variable id number;
begin
  declare
  name varchar2(100);
  descr varchar2(500);
  obj_id number;

begin
  name:='Manual_Employees';
  descr:='Segment Advisor Example';

  dbms_advisor.create_task (
    advisor_name     => 'Segment Advisor',
    task_id          => :id,
    task_name        => name,
    task_desc        => descr);

  dbms_advisor.create_object (
    task_name        => name,
    object_type      => 'TABLESPACE',
    attr1            => 'FDR_DATA',
    attr2            => NULL,
    attr3            => NULL,
    attr4            => NULL,
    attr5            => NULL,
    object_id        => obj_id);

  dbms_advisor.set_task_parameter(
    task_name        => name,
    parameter        => 'recommend_all',
    value            => 'TRUE');

  dbms_advisor.execute_task(name);
  end;
end; 
/

-- getting the recommendations 

select tablespace_name, segment_name, segment_type, partition_name,
recommendations, c1 from
table(dbms_space.asa_recommendations( all_runs => 'FALSE', show_manual => 'TRUE', show_findings => 'FALSE'));


-- checking the status of the task 

COLUMN DESCRIPTION format A30

SELECT task_name, description, advisor_name, execution_start, execution_end, status
     FROM dba_advisor_tasks
     WHERE owner='PERF_SUPPORT'
     ORDER BY task_id DESC;
