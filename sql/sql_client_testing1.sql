




set serveroutput on

clear screen

ALTER SESSION SET  statistics_level='ALL';
ALTER SESSION SET  nls_date_format='dd/mm/yyyy hh24:mi:ss';
alter session set "_sqlmon_threshold"=0;
alter session set "_sqlmon_max_planlines" = 9000;
alter session set max_dump_file_size='UNLIMITED';
--alter session set optimizer_dynamic_sampling = 2;
--alter session set "_SERIAL_DIRECT_READ"=true;
--ALTER SESSION SET  OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=TRUE ;
--ALTER SESSION SET  _nlj_batching_enabled=0;   /* Vector IO : 1 = DEFAULT, 0 = disabled */
--ALTER SESION SET "_use_nosegment_indexes"=TRUE;  /* use virtual indexes */
--alter session force parallel query ;
--ALTER SESSION SET  OPTIMIZER_USE_SQL_PLAN_BASELINES=TRUE;
--ALTER SESSION SET  sqltune_category='&CATEGORY_NAME';
--ALTER SESSION SET OPTIMIZER_USE_PENDING_STATISTICS=TRUE;
--alter session set "_optimizer_cartesian_enabled"=false
--alter session set events '10104 trace name context off'; /* HASH join tracing */


define MY_SCHEMA=PERF_SUPPORT
define APP_SCHEMA=APP_FBI

declare
  module_string   VARCHAR2(64);
BEGIN
  module_string := 'PJS_'  || to_char(mod(abs(dbms_random.random),100000)+1) ;
  dbms_application_info.set_module( module_string,'parse');
  dbms_application_info.set_client_info(module_string);
  dbms_output.put_line('Module : ' || module_string  );

END;
/
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  run it
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
alter session set current_schema=&APP_SCHEMA ;
set arraysize 10
set termout off



SELECT
        /*+ monitor ordered full (j) use_nl_with_index(je journals_ext_pk)   */
        j.comp_code                                                    ,
        j.ACCOUNT                                                      ,
        j.profit_ctr                                                   ,
        j.pcompany                                                     ,
        j.currency                                                     ,
        j.trdbalsrc                                                    ,
        j.trdbalid                                                     ,
        j.inst_src                                                     ,
        j.inst_id                                                      ,
        j.cpty_src                                                     ,
        j.cpty_id                                                      ,
        TO_CHAR(j.amountt) AS amountt                                  ,
        TO_CHAR(j.amountl) AS amountl                                  ,
        j.move_type                                                    ,
        j.gaap_code                                                    ,
        j.trnlnkid                                                     ,
        j.trnlnksrc                                                    ,
        j.riskclass                                                    ,
        j.subbook                                                      ,
        j.family                                                       ,
        j.strategy                                                     ,
        j.status_f                                                     ,
        j.chrt_accts                                                   ,
        j.fiscyear                                                     ,
        j.postdate                                                     ,
        j.trans_id                                                     ,
        j.trans_src                                                    ,
        j.func_area                                                    ,
        j.dr_cr_ind                                                    ,
        j.apgevntcd                                                    ,
        j.trandate                                                     ,
        j.feedsprec                                                    ,
        j.currencyl                                                    ,
        j.gaap_adj_ind                                                 ,
        j.acctalias                                                    ,
        j.feedsyscd                                                    ,
        j.feedfilid                                                    ,
        j.docdate                                                      ,
        j.batch_no                                                     ,
        j.recseqnum                                                    ,
        j.local_reported_account                                       ,
        je.extension_hash                                              ,
        je.amt_type_cd                                                 ,
        je.ast_loss_gl_acct_nr                                         ,
        je.liabprof_gl_acct_nr                                         ,
        je.pos_denom                                                   ,
        je.ctrct_based_pos_id                                          ,
        je.elmt_ast_pos_id                                             ,
        je.ctrct_id                                                    ,
        je.cplx_ctrct_id                                               ,
        je.prod_nr                                                     ,
        je.tax_duty_al_type_cd                                         ,
        je.busn_obj_id                                                 ,
        je.busn_type_code                                              ,
        je.cost_ctr_id                                                 ,
        je.cr_pc_id                                                    ,
        je.cr_cost_ctr_id                                              ,
        je.cost_obj_id                                                 ,
        je.emp_prtnr_rel_id                                            ,
        je.actvy_rel_prod_nr                                           ,
        je.alloc_tovr_pc_id                                            ,
        je.btxae_type_sfx                                              ,
        je.sw_compo_id                                                 ,
        je.clnt_al_flw_class_cd                                        ,
        je.clnt_ast_type_cd                                            ,
        je.clnt_liab_type_cd                                           ,
        je.dpnd_ctrct_id                                               ,
        je.cr_emp_prtnr_rel_id                                         ,
        j.fiscper                                                      ,
        TO_CHAR(j.GROUP_CURRENCY_AMOUNT_1)  AS GROUP_CURRENCY_AMOUNT_1 ,
        TO_CHAR(j.GROUP_CURRENCY_AMOUNT_2)  AS GROUP_CURRENCY_AMOUNT_2 ,
        TO_CHAR(j.SC_CURRENCY_AMOUNT_1)     AS SC_CURRENCY_AMOUNT_1    ,
        TO_CHAR(j.SC_CURRENCY_AMOUNT_2)     AS SC_CURRENCY_AMOUNT_2    ,
        TO_CHAR(j.DOMESTIC_CURRENCY_AMOUNT) AS DOMESTIC_CURRENCY_AMOUNT,
        j.GROUP_CURRENCY_CODE_1                                        ,
        j.GROUP_CURRENCY_CODE_2                                        ,
        j.SC_CURRENCY_CODE_1                                           ,
        j.SC_CURRENCY_CODE_2                                           ,
        j.DOMESTIC_CURRENCY_CODE
FROM    app_fbi.journals j,
        app_fbi.journals_extension je
WHERE   j.func_area      = 'ACFP'
        AND j.postdate  >= '20180101' 
        AND j.postdate  <= '20180129'
        AND je.func_Area(+) = j.func_Area
        AND je.feedsyscd(+) = j.feedsyscd
        AND je.feedfilid(+) = j.feedfilid
        AND je.batch_no(+)  = j.batch_no
        AND je.postdate(+)  = j.postdate
        AND j.line_no    = je.line_no(+)
        AND j.recseqnum  = je.recseqnum(+)
        AND j.comp_code  = je.comp_code(+)
        AND j.status_f   = je.status_f(+);


set termout on
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  end of run 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DECLARE
  module_string VARCHAR2(64) ;
  s_SQL_ID VARCHAR2(13);
  i_CHILD_NO integer;
  i_SQL_EXEC_ID integer;

BEGIN

  dbms_application_info.read_client_info( module_string);
  dbms_application_info.set_module( NULL, NULL);
  dbms_application_info.set_client_info(NULL);

-------------Now get the SQ_EXEC_ID for the statement --------------------

  begin
    select sql_id, sql_exec_id, child_number into s_SQL_ID, i_SQL_EXEC_ID, i_CHILD_NO
    from 
    (select SM.*, SS.child_number
     from Gv$sql_monitor SM 
    left outer join gv$sql SS ON SM.inst_id = SS.inst_id and SS.child_address = SM.sql_child_address
    WHERE SM.module = module_string   and sql_plan_hash_value != 0
    order by sql_exec_start desc
    ) 
    where rownum = 1;
    
  DBMS_OUTPUT.PUT_LINE(chr(13) ||'define SQL_ID=' || s_SQL_ID );
  DBMS_OUTPUT.PUT_LINE('define SQL_EXEC_ID=' || i_SQL_EXEC_ID );
  DBMS_OUTPUT.PUT_LINE('define SQL_CHILD_NUM=' || i_CHILD_NO);

  EXCEPTION
    when NO_DATA_FOUND THEN
      dbms_output.put_line( 'Problems finding the SQL_ID  - ' || SQLERRM);
    when TOO_MANY_ROWS then
       dbms_output.put_line('Module ' || module_string || ' has duplicate SQL!');
  end;


END;
/
