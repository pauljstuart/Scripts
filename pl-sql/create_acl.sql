begin
  dbms_network_acl_admin.create_acl(
   acl =>'mis-permissions.xml',
   description=>'test ACL',
   principal=>'SWMIS_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');

end;
/

begin
  dbms_network_acl_admin.create_acl(
   acl =>'plvision-permissions.xml',
   description=>'PLVISION ACL',
   principal=>'PLVISION_OWNER',
   is_grant=>TRUE,
   privilege=>'connect');
end;
/

begin
  dbms_network_acl_admin.assign_acl(
   acl=>'plvision-permissions.xml',
  host=>'mailhost');

end;
/

begin
  dbms_network_acl_admin.assign_acl(
   acl=>'mis-permissions.xml',
  host=>'mailhost');

end;
/



begin
  dbms_network_acl_admin.assign_acl(
   acl=>'plvision-permissions.xml',
  host=>'uksmtp.markit.partners');

end;
/

begin
  dbms_network_acl_admin.assign_acl(
   acl=>'mis-permissions.xml',
  host=>'uksmtp.markit.partners');

end;
/

