
// Start SQL Developer
// 
// PJS

var mbOKCancel = 1;       // Declare variable.
var mbInformation = 64;
var mbCancel = 2;

var sSQLDeveloper = 'C:\\Users\\stuartp\\Documents\\programs\\SQLdeveloper41';
var sSQLcl= sSQLDeveloper + '\\sqlcl';
var sJavaHome = sSQLDeveloper + '\\jdk';
var sOracleHome = 'C:\\Users\\stuartp\\Documents\\programs\\instantclient_12_1';
var sTNSAdmin = 'P:\\Oracle\\Network\\Admin';


var WshShell = WScript.CreateObject("WScript.Shell");

var WshSystemEnv = WshShell.Environment( "Process");

var sText = "SQLcl= " + sSQLcl +	  "\n" +
             "Oracle Home = " + sOracleHome + "\n" +
             "TNS Admin = " + sTNSAdmin + "\n" +
             "Java Home = " + sJavaHome + "\n" ;

WScript.Echo( sText );


WshShell.CurrentDirectory = sSQLcl;

WshSystemEnv( "PATH") = sSQLcl+ "\\bin;" + sOracleHome + ";" + sJavaHome + "\\jre\\bin";
WshSystemEnv( "ORACLE_HOME" )= sOracleHome;
WshSystemEnv( "TNS_ADMIN") = sTNSAdmin;

WshShell.Run(  "cmd.exe", 1, 0	);





