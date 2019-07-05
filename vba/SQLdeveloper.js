// Start SQL Developer
// 
// PJS

var mbOKCancel = 1;       // Declare variable.
var mbInformation = 64;
var mbCancel = 2;


var sSQLDeveloper = 'C:\\Users\\stuartp\\Documents\\programs\\SQLdeveloper_19_1';
var sOracleHome = "C:\\Users\\stuartp\\Documents\\programs\\instantclient_18_5";
var sTNSAdmin = "P:\\Oracle\\Network\\Admin";
var sIDE = "c:\\users\\stuartp\\documents\\programs\\SQLdeveloper18_files";
var sJavaHome = sSQLDeveloper + "\\jdk";

var WshShell = WScript.CreateObject("WScript.Shell");

var WshSystemEnv = WshShell.Environment( "Process");

var sText = "SQL Developer = " + sSQLDeveloper +	  "\n" +
              "Oracle Home = " + sOracleHome + "\n" +
             "TNS Admin = " + sTNSAdmin + "\n" +
             "Java Home = " + sJavaHome + "\n" +
             "IDE Home = " + sIDE;

WScript.Echo( sText );

WshSystemEnv( "PATH") =  sOracleHome + ";" 
WshSystemEnv( "ORACLE_HOME" )= sOracleHome;
WshSystemEnv( "TNS_ADMIN") = sTNSAdmin;
WshSystemEnv( "IDE_USER_DIR") = sIDE;

WshShell.Run(sSQLDeveloper + "\\sqldeveloper.exe", 1, 0	);


