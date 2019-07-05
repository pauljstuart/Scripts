-------------
-- create host-permissions ACL
------------
begin
  dbms_network_acl_admin.create_acl(
   acl =>'host-permissions.xml',
   description=>'host ACL list',
   principal=>'SWAPP_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');

end;
/

-------------
--
------------
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'host-permissions.xml',
   principal=>'PLVISION_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'host-permissions.xml',
   principal=>'SWREF_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'host-permissions.xml',
   principal=>'STORM_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'host-permissions.xml',
   principal=>'SWSHARED_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'host-permissions.xml',
   principal=>'PLVISION_OWNER',
   is_grant=>TRUE,
   privilege=>'resolve');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'host-permissions.xml',
   principal=>'SWREF_OWNER',
   is_grant=>TRUE,
   privilege=>'resolve');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'host-permissions.xml',
   principal=>'STORM_OWNER',
   is_grant=>TRUE,
   privilege=>'resolve');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'host-permissions.xml',
   principal=>'SWSHARED_OWNER',
   is_grant=>TRUE,
   privilege=>'resolve');
end;
/


--
-- create mail ACL
--
begin
  dbms_network_acl_admin.create_acl(
   acl =>'mail-permissions.xml',
   description=>'mailhost ACL list',
   principal=>'SWAPP_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');

end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'mail-permissions.xml',
   principal=>'PLVISION_OWNER',
   is_grant=>TRUE,
   privilege=>'resolve');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'mail-permissions.xml',
   principal=>'SWREF_OWNER',
   is_grant=>TRUE,
   privilege=>'resolve');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'mail-permissions.xml',
   principal=>'STORM_OWNER',
   is_grant=>TRUE,
   privilege=>'resolve');
end;
/

begin
  dbms_network_acl_admin.add_privilege(
   acl =>'mail-permissions.xml',
   principal=>'PLVISION_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'mail-permissions.xml',
   principal=>'SWREF_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');
end;
/
begin
  dbms_network_acl_admin.add_privilege(
   acl =>'mail-permissions.xml',
   principal=>'STORM_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');
end;
/

begin
  dbms_network_acl_admin.assign_acl(
   acl=>'mail-permissions.xml',
  host=>'mailhost');

end;
/
begin
  dbms_network_acl_admin.assign_acl(
   acl=>'mail-permissions.xml',
  host=>'uksmtp.markit.partners');

end;
/

--
--
--

begin
  dbms_network_acl_admin.assign_acl(
   acl=>'host-permissions.xml',
  host=>'production.swapswire.com');

end;
/
begin
  dbms_network_acl_admin.assign_acl(
   acl=>'host-permissions.xml',
  host=>'prdadmin10');

end;
/

begin
  dbms_network_acl_admin.assign_acl(
   acl=>'host-permissions.xml',
  host=>'prdadmin20');

end;
/

begin
  dbms_network_acl_admin.assign_acl(
   acl=>'host-permissions.xml',
  host=>'uat.swapswire.com');
end;
/
begin
  dbms_network_acl_admin.assign_acl(
   acl=>'host-permissions.xml',
  host=>'www.markit.com');
end;
/

begin
  dbms_network_acl_admin.assign_acl(
   acl=>'host-permissions.xml',
  host=>'bfmrr.bloomberg.com');
end;
/
begin
  dbms_network_acl_admin.assign_acl(
   acl=>'host-permissions.xml',
  host=>'192.165.219.225');
end;
/
begin
  dbms_network_acl_admin.assign_acl(
   acl=>'host-permissions.xml',
  host=>'financialcalendar.net');
end;
/

commit;



SET DEFINE OFF;
set serveroutput on

DECLARE

   V_STATUS  NUMBER;
   V_REASON_PHRASE VARCHAR2(256);
BEGIN


swhttp.post(url_in => 'https://www.markit.com/export.jsp'
,wallet_path_in => 'file:/u06/admin/wallet'
,wallet_password_in => 'mark-it.com'
,content_type_in =>  'application/x-www-form-urlencoded'
,content_in => utl_url.ESCAPE('user=SwapsWire&password=swapred4&date=20130116&format=xml&version=9&report=credindexannex&family=CDX')
,output_dirname_in => '/u06/load/data'
,output_filename_in => 'credindexannex.zip'
,status_out => v_status
,reason_phrase_out => v_reason_phrase);

DBMS_OUTPUT.PUT_LINE('STATUS IS ' || v_status || ' phrase : ' || v_reason_phrase );
END;
