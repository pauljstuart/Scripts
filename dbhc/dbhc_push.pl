
#!/opt/csm/64-bit/perl/5.20.2/bin/perl

##############################################################################
# Purpose   :
#
# Returns   : Exit 1 if something fails
#
# Env       : Requires UTILITYSERVER, UTILITYDBO and UTILITYPASSWORD
#
# Change History :
#
# Date        By                  Version Description
# ----------- ------------------- ------- ------------------------------------
# 04-Mar-2020 Paul Stuart          0.0    Original
# 08-Apr-2020 Paul Stuart          0.1    Minor enhancements
# 02-Jun-2020 Paul Stuart          0.2    Minor enhancements
# 28-Aug-2020 Paul Stuart          0.3    Minor enhancements
#
##############################################################################

use strict;
use warnings;

use lib qw( /sbcimp/run/pd/cpan/32-bit/5.8.8-2007.09/lib );

use DBI;


use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use Getopt::Long;
use Mail::Send;
use Error qw(:try);


use vars qw( $dbh $dbh2 $sth );

#############################################################################
#   global variables
#############################################################################

my $script_id   = 'DBHC_PUSH';
my $hostname = $ENV{ "HOSTNAME"};
my $return_code = 0;
my $message_text;

#############################################################################
#   Initiate logging
#############################################################################

Log::Log4perl->easy_init(
  {
     level    => $DEBUG,
     file     => "STDOUT",
     layout   => '%d : ' . $script_id . '  %m%n' ,
             }
             );

my $logger  = get_logger();

$logger->info('#################################################################');

#############################################################################
#   setup the database connection
##############################################################################

my $database = $ENV{ "UTILITYSERVER"   };
my $user_id  = $ENV{ "UTILITYDBO"      };
my $password = $ENV{ "UTILITYPASSWORD" };
my $run_env = $ENV{ "RUN_ENVIRONMENT" };
my $fdd_bin = $ENV{ "FDD_BIN" };

if ( ! defined $database )
  {
  $logger->info('UTILITYSERVER is blank.');
  exit 1;
  };

if ( ! defined $user_id )
  {
  $logger->info('UTILITYDBO is blank.');
  exit 1;
  };

if ( ! defined $password  )
  {
  $logger->info('UTILITYPASSWORD is blank.');
  exit 1;
  };

if ( ! defined $run_env  )
  {
  $logger->info('RUN_ENVIRONMENT is blank.');
  exit 1;
  };

#############################################################################
#   prepare the SQL text
##############################################################################

my $sql = qq{
     select DATABASE_NAME ,  AUTOSYS_ENV_USERID ,  AUTOSYS_ENV_PASSWORD ,  AUTOSYS_ENV_SERVER
          from dbhc_databases
          where database_environment = '$run_env'
          AND DATABASE_ROLE = 'HOST'
          AND DATABASE_NAME  NOT IN (SELECT REMOTE_DATABASE_NAME FROM DBHC_DATABASES WHERE DATABASE_ENVIRONMENT = '$run_env' AND REMOTE_DATABASE_NAME IS NOT NULL)

};

my $sql_deploy_host = qq{
BEGIN
    DBHC_PKG.DEPLOY_DBHC_HOST( :p_user_id , :p_password, :p_database_name    ) ;
END;
};

my $sql_deploy_master = qq{
BEGIN
    DBHC_PKG.DEPLOY_DBHC_MASTER( :p_user_id , :p_password, :p_database_name    ) ;
END;
};


#############################################################################
#   connect to central Database Health Check  database
##############################################################################

$logger->info('Connecting to MASTER DBHC database ' . $database . ' as ' . $user_id  );

my $dsn      = "dbi:Oracle:$database";
my $ret;

$dbh = DBI->connect(
     $dsn,
     $user_id,
     $password,   { PrintError => 0, RaiseError => 0 }
      );

if ( ! defined $dbh  )
  {
  $logger->info('Error connecting to ' . $database . ' as ' . $user_id . ' - ' . DBI::errstr );
  $logger->info('Unable to proceed.');
  exit 1;
  }
else
  {
  $logger->info( 'Connected successfully to ' . $database . ' as '  . $user_id );
  }

$dbh->{LongReadLen} = 700000;
$dbh->{ PrintError}  = 0;
$dbh->{ RaiseError}  = 0;


#############################################################################
#   Get data from the control table
##############################################################################

$logger->info('Getting list of databases.');

  $sth = $dbh->prepare($sql);
  if ( ! defined $sth )
    {
    $logger->info('Error when parsing this statement : '.  $dbh->errstr()   );
    $dbh->disconnect ;
    exit 2;
    };
  $ret = $sth->execute();
  if ( ! defined $ret )
    {
    $logger->info('Error when getting list of databases  - ' .  $dbh->errstr() );
    $dbh->disconnect ;
    exit 2;
    };

  my $database_list = $sth->fetchall_arrayref();
  $sth->finish();

#
my $database_count = 0;

$database_count = scalar(@$database_list);
$logger->info("Found $database_count databases for this environment.");

#############################################################################
# deploy the DBHC to each database
#############################################################################

foreach my $row ( @{ $database_list } )
  {
  my $r_database_name    = $row->[0];
  my $r_env_userid  = $row->[1];
  my $r_env_password = $row->[2];
  my $r_env_server  = $row->[3];

  $logger->info( "Starting $r_database_name.  Obtaining these variables : $r_env_userid $r_env_password $r_env_server " );


  # Get the values in environment variable from the unix environment :
  my $target_user_id  = $ENV{ "$r_env_userid" };
  my $target_password = $ENV{ "$r_env_password" };
  my $target_database = $ENV{ "$r_env_server" };

  if ( ! defined $target_user_id  )
      {
      my $check_description = $script_id . ' ' . $run_env . ' ' . $database     ;
      my $message_text = $r_database_name .  ' : Error : No value specified for ' . $r_env_userid    ;
      send_dbhc_alert(  -1,  $check_description , $message_text  );
      $logger->info( $message_text   );
      $return_code=5;
      next;
      };

  if ( ! defined $target_password  )
      {
      my $check_description = $script_id . ' ' . $run_env . ' ' . $database     ;
      my $message_text = $r_database_name .  ' : Error : No value specified for ' . $r_env_password    ;
      send_dbhc_alert(  -1,  $check_description , $message_text  );
      $logger->info( $message_text   );
      $return_code=5;
      next;
      };

  if ( ! defined $target_database  )
      {
      my $check_description = $script_id . ' ' . $run_env . ' ' . $database     ;
      my $message_text = $r_database_name .  ' : Error : No value specified for ' . $r_env_server    ;
      send_dbhc_alert(  -1,  $check_description , $message_text  );
      $logger->info( $message_text   );
      $return_code=5;
      next;
      };

  $logger->info( "About to deploy to $r_database_name "   );
  # now run the deploy procedure
  $sth = $dbh->prepare($sql_deploy_host );
  $sth->bind_param( ':p_database_name',  $target_database ) ;
  $sth->bind_param( ':p_user_id',  $target_user_id    );
  $sth->bind_param( ':p_password',  $target_password   );
  $ret = $sth->execute();
  if ( ! defined $ret )
    {
    my $check_description = $script_id . ' ' . $run_env . ' ' . $database     ;
    my $message_text = 'Error when running the deploy against ' .  $r_database_name . ' - ' . $dbh->errstr()  ;
    send_dbhc_alert(  -1,  $check_description , $message_text  );
     $logger->info( $message_text   );
    $return_code=9;
    }
  else
    {
    $sth->finish();
    $logger->info( "Finished deploy to $r_database_name  "   );
    }

  }

# Finally create the checks on the Master Database itself

$logger->info( "About to create checks on the master  $database "   );
$sth = $dbh->prepare($sql_deploy_master );
$sth->bind_param( ':p_user_id',  $user_id    );
$sth->bind_param( ':p_password',  $password   );
$sth->bind_param( ':p_database_name',  $database ) ;
$sth->execute();
$sth->finish();
$logger->info( "Finished deploying on MASTER $database"   );

$dbh->disconnect();

$logger->info( "The exit code is $return_code "   );

exit $return_code ;

# the end

#############################################################################
# subroutines
#############################################################################
#
sub send_dbhc_alert {
    my ($check_no , $description ,   $message ) = @_;

  my $sql_send_alert = qq{
  BEGIN
    DBHC_PKG.REGISTER_ALERT( p_check_no => :check_no , p_check_description => :description, p_notification_list => :notification_list, p_check_exec_time => SYSTIMESTAMP  ,   p_check_elapsed_time => 1  ,      c_check_output => :message_text  );
  END;
  };

  $sth = $dbh->prepare($sql_send_alert);
  $sth->bind_param( ':check_no', $check_no ) ;
  $sth->bind_param( ':notification_list',  'ADMIN' ) ;
  $sth->bind_param( ':description',  $description   );
  $sth->bind_param( ':message_text',  $message  );
  $sth->execute();
  $sth->finish();

}

sub send_email {
    my ($email, $env, $db,  $message ) = @_;

    my $header = "[$script_id $env] " . $db  ;

    my $text   = "\n"
               . "--------------------------------------------------\n"
               . "Database       : $db\n"
               . "Environment    : $env\n"
               . "process        : $script_id\n"
               . "--------------------------------------------------\n\n"
               . $message;

    my $msg = Mail::Send->new(Subject => $header, To => $email);
    my $fh  = $msg->open;
    print $fh $text;
    $fh->close          # complete the message and send it
        or die "couldn't send whole message: $!\n";
}



exit;
