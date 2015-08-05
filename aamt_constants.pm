#---------------------------------------------------------------------------------------------------------
#Script Name 		:	aamt_constants.pm
#Description	    : 	Package is used to define the strings that would be used by the AIISMT wizard
#-----------------------------------------------------------------------------------------------

#*****************************************************************************#
# Following set of constants used to define the module names#
#*****************************************************************************#
use constant MOD_AUQ						=>						"Authentication";
use constant MOD_WIS						=>						"Work Items Source";
use constant MOD_PARS						=>						"Parser";
use constant MOD_PARS1                      =>                      "Pre-Parse Module"; 
use constant AUQ							=>						"Authentication";
use constant PARSER							=>						"Parser";
use constant WORKITEMS						=>						"WorkItems";
use constant WORKITEMS_TAR					=>						"WorkItems Target";


#*****************************************************************************#
#            The Following Constants are used by AUQ Module                   #  
#*****************************************************************************#
use constant MAXTRIES                       =>                      3; #maximum number of tries in case of iteration                      
use constant DEFAULTWIDTH                   =>                      80; #maximum number of tries in case of iteration                      
use constant WINDOWS						=>						"MSWin32";
use constant LINUX							=>						"linux";
use constant REDHAT1                        =>                      "Red-Hat";
use constant REDHAT2                        =>                      "Redhat"; 
use constant MANDRAKE                       =>                      "Mandrake";
use constant APACHE                         =>                      "Apache";   
use constant PROTOCOL                       =>                      "tcp";
use constant TITLE1							=>						" \t\tApache to Azure App Service Migration Tool\t\n";
use constant TITLE2							=>						"\t\tCopyright MICROSOFT CORPORATION Version 1.0 \t\n";
use constant TITLE3							=>						

"
Supported Platforms:
    AAASMT supports migration of Website(s) hosted on Apache
    Web Server to Azure App Service

System Requirements:
    1. Web Server running
    2. Administrative knowledge of the running Website(s)
       (e.g.:httpd.conf file path) 

More Information:  Visit http://www.movemetothecloud.net/

Important Notes:
    Super User rights are required to use the Apache to Azure App Service Migration Tool.\n";	  

use constant TITLE_SESSION_NAME				 =>				
"\n
    Please choose a name (e.g.:AASMT_1) for the current Migration Session.
    Enter a new Session Name to start a  fresh Migration process or Enter 
    the  previous  Session Name to recover  from an aborted Session. Only 
    AlphaNumeric characters, '-' and '_' are permitted in Session Name.\n
    Note that this will be used to create a working folder which will 
    store temporary files which may contain sensitive information and 
    should be deleted when this tool is finished running.";

use constant TITLE_EXIT                      =>  "\n\nThank You for using Apache to Azure App Service Migration Tool\n";
use constant SUCCESS						=>						"1000";

#*****************************************************************************#
#            The Following Constants are used TRUE/FALSE values               #
#*****************************************************************************#
use constant TRUE							=>						1;
use constant FALSE							=>						0;

#*****************************************************************************#
#            The Following Constants are used in validation functions         # 
#*****************************************************************************#
use constant  I                             =>					"Only Integer values are allowed";
use constant  S                             =>					"Only letters are allowed";
use constant  M                             =>					"Machine Address cannot have special characters (!@#$%^&*()}{[])";

#*****************************************************************************#
#            The Following Constants are used in naming the files             # 
#*****************************************************************************#
use constant AMW							=>					"aamt_";
use constant FILE_RECOVERY					=>					"_Recovery.txt";
use constant FILE_STATUS					=>					"_Status.htm";
use constant FILE_LOG						=>					"_Log.htm";
use constant FILE_CONF                      =>                  "_httpd.txt";
use constant FILE_CONF_ALL                  =>                  "_httpd_all_settings.txt"; # ALL SETTINGS
use constant FILE_TASKLIST					=>					"_Tasklist.txt";
use constant FILE_TASKLIST_TEMP				=>					"_Tasklist_temp.txt";
use constant FILE_CHECKSUM					=>					"_checksum.txt";
use constant FILE_WISTATUS_LOG				=>					"_status.log";
use constant FILE_SITES						=>					"_sites.txt";
use constant FILE_IISCONFIG					=>					"_config.xml";
use constant FILE_USERLIST					=>					"_userlist.txt";
use constant FILE_ACL						=>					"_acl.txt";	
use constant FILE_TARGET_INFO               =>                  "aamt_target_info.txt";
use constant FILE_TARGET_FPSE				=>					"aamt_target_fpse.vbs";
use constant FILE_TARGET_OVERALL			=>					"aamt_wrt_overall_target.wsf";
use constant FILE_TARGET_ACL				=>					"aamt_wrt_acl.vbs";
use constant FILE_TARGET_CREATEUSER			=>					"aamt_wrt_createuser.vbs";
use constant FILE_TARGET_IMPORT				=>					"aamt_wrt_import.vbs";
use constant FILE_TARGET_SCRIPTS			=>					"aamt_iis_scripts.vbs";
use constant FILE_TARGET_INFORMATIONLOG     =>					"aamt_informationLog.vbs";
use constant FILE_TARGET_CONSTANTS			=>					"aamt_wrt_constants.vbs";
use constant FILE_TARGET_UTILITIES			=>					"aamt_wrt_utilities.vbs";
use constant FILE_TARGET_VERIFY				=>					"aamt_verifier_verifytarget.vbs";
use constant FILE_PERLPRESENT			    =>				    "AAMT_PERLPRESENT.BAT";
use constant FILE_TARGET_BATCHFILE			=>					"AIISMT_TARGET.BAT";		
use constant FILE_TARGET_VERIFY_BAT			=>					"AIISMT_VERIFY.BAT";		

#*****************************************************************************#
#            The Following Constants are used to define user prompts          #
#*****************************************************************************#
use constant CON_SESSION_NAME               =>                  "\nEnter Session Name For Your Migration: ";
use constant CON_SOURCE_IP					=>					"\nEnter Source Machine IP Address [localhost]: ";
use constant CON_SOURCE_USERNAME            =>                  "\nEnter Source Machine Username: "   ;
use constant CON_SOURCE_PASSWORD            =>                  "\nEnter ROOT user Password: "   ;
use constant CON_TARGET_IP					=>					"\nEnter Target Machine IP Address [localhost]: ";
use constant CON_TARGET_USERNAME            =>                  "\nEnter Target Machine Username: "   ;
use constant CON_TARGET_PASSWORD            =>                  "\nEnter Target Machine password: "   ;
#Added the root user
use constant CON_ROOT_USER                  =>                  "root";
use constant CON_ROOT_PERMISSION            =>                  "This Wizard requires ROOT User Permissions. You need to Login as ROOT and
Try Again\n"; 
use constant CON_SESSION_EXISTS             =>                   "The Session Name is already used in the Target Machine. You need to restart
the migration with a Different Session Name."; 
use constant CON_HTTPD_PATH					=>					
"    
    Please enter the ABSOLUTE PATH of your  Apache  Configuration File or
    press [Enter] to continue with the default path.
NOTE: path is usually: 
      [Debian/Ubuntu]:   /etc/apache2/apache2.conf 
  OR
      [RedHat/CentOS]:   /etc/httpd/conf/httpd.conf
  OR
      [OpenSUSE]:        /etc/apache2/httpd.conf
Enter Configuration file path [/etc/apache2/apache2.conf]: "; # /etc/httpd/conf/httpd.conf

use constant CON_HTTPD_FILE_STATUS          =>                  "\n Getting the configuration file...";
use constant CON_SITE_SELECT				=>			        "\n Do you wish to migrate? (Y/N): ";
use constant CON_TARGET_DIR		            =>	                "\nDestination FTP path: ";
use constant CON_TARGET_PORT				=>					"\nDestination site PORT number: ";
use constant CON_RECOVERY_MODE              =>                  
"\nDo you want to continue migration in RECOVERY mode?(Y/N): ";  
use constant CON_RECOVERY_FILE_CONTENTS     =>                  "\nThe Wizard determines you have started migration earlier with details as mentioned...\n";  
# use constant CON_WEBSERVER_VERSION          =>                  "  Press 'Y' If Your Source
#     Machine is running on any of the following Apache Versions :

#     1.3.0   1.3.1   1.3.2   1.3.3   1.3.4   1.3.6   1.3.9   1.3.10  
#     1.3.11  1.3.12  1.3.14  1.3.17  1.3.19  1.3.20  1.3.21  1.3.22 
	 
# Is your Source Machine running on any of the above Apache Versions? (Y/N):";
# use constant CON_WEBSERVER_VERSION_INPUT    =>                  "\nEnter the Apache Web server Version (Ex:1.3.22)"; 
# use constant CON_OS_VERSION                 =>                  

# "\n    This Migration Kit supports the  following OS Versions on the Source
#     Server. Press 'Y' If APACHE is running on any of the following :

#     Redhat Linux    (Version : 6.0/6.2/7.0/7.1/7.2)
#     Mandrake Linux  (Version : 8.0/8.1/8.2) 
#     Suse Linux      (Version : 7.3/8.0)  

# Is your Source Machine running on any of the above OS Versions? (Y/N):";
use constant CON_EXEC_SOURCE_MODE           =>                  "Source";
use constant CON_EXEC_INTERMEDIATE_MODE     =>                  "Intermediate";
use constant CON_EXEC_TARGET_MODE           =>                  "Target";             

use constant CON_LOCALHOST                  =>                  "localhost";
use constant CON_IP_ADDRESS_WINDOWS         =>                  "IP Address";
use constant CON_IP_ADDRESS_LINUX           =>                  "inet addr"; 
use constant CON_DEFAULT_IP                 =>                  "127.0.0.1";

use constant CON_SUPERUSER                  =>                  
"    The Migration Kit requires SUPER USER privilege on the Source Machine\n";

use constant DEFAULT_HTTPD_PATH             =>                  "/etc/apache2/apache2.conf"; # "/etc/httpd/conf/httpd.conf";
use constant DEFAULT_PASSWORD_PATH          =>                  "/etc/passwd";
use constant FILE_PASSWORD                  =>                  "_passwd.txt";
use constant IP_INFORMATION                 =>                  "[IP_INFORMATION]";
use constant NEW_REC_HTTPD_PATH             =>                  "httpd.conf file path =";  
# use constant MSG_PER_TOOLRUN                =>                  
# "\n    Tool has  detected that  the  prerequisite  environment  has not been
#     setup on the Target Machine. Please run the  AIISMT Target Environment
#     Setup  module  on  the  Target ( IIS 6.0 ) Machine first. The current 
#     migration can be continued once that is done.\n\n"; 

# use constant MSG_PER_TOOLRUN_LOG            =>                  
# "\n    Please run the  AIISMT Target  Environment Setup module ( Packaged in 
#     aiismt_targ_virdir.zip )  on the  Target Machine before continuing with
#     the current session";
# use constant MSG_PER_TOOLRUN_CHECK          =>                  "Checking the Target Machine environment....\n";  
use constant ERR_NOT_LINUX	=>	"\nSource Platform Not running on Linux OS. Refer Installation Manual for Details\n";
use constant ERR_NOT_WINDOWS => "\nTarget Platform Not running on Windows OS. Refer Installation Manual for Details\n";

#*****************************************************************************#
#            The Following Constants are used for parser module user prompts  #
#*****************************************************************************#
use constant MSG_LINE                       => 
"---------------------------------------------------------------------------\n";
use constant MSG_LISTEN              =>
"\n    The Source Apache Server Listens at the following IP:Port combination.
    Select the corresponding  IP:Port  to be set on the  Target Machine or
    press [Enter] to continue with the current configuration settings.\n";
use constant MSG_IPMAP              =>
"\n    The following  IP Addresses  are currently used by the sites selected
    for migration. Enter a new IP Address for the sites or press  [Enter]
    to  continue  using  the  same configuration settings. Press * to use  
    <All UnAssigned IPs>.\n";
use constant ERR_NOTHING2MIGRATE    =>
"\n\n     No sites running on the Apache Web Server were selected for migration.
    Thank you for using the Azure App Service Migration Tool\n";  
use constant MSG_MIGRATE_SITE       =>  "\n    Do you want to migrate the site [%1%]? (Y/N): ";
use constant MSG_MIGRATE_MYSQL      =>  "\n    Do you want to migrate a MySQL database associated with the site [%1%]? (Y/N): ";
use constant MSG_SOURCE_PATH        =>  "    The Document Root path on the source is <%1%> \n";
use constant MSG_TARGET_PATH        =>  "    Enter destination path: ";
use constant MSG_PROCESSING         =>  "\nProcessing Apache config file :  [%1%] \n";
use constant MSG_END_OF_PARSE1      =>  "\nSuccessfully completed initial parse\n";
use constant MSG_CHANGE_IP          =>  "\nChange Listening IP from %1% to [%2%]: ";
use constant MSG_CHANGE_PORT        =>  "\nChange Listening Port from %1% to [%2%]: ";
use constant MSG_CHANGE_SITE_IP     =>  "\nChange IP from %1% to [%2%]: ";
use constant MSG_MIGRATE_SSL_YESNO  =>  "    Do you want to migrate the SSL Certificates (Y/N): ";

use constant MSG_IP_SITE_MAP        =>  
"    The IP address [%1%] is used by the following sites : 
    %2% \n";

use constant MSG_SITE_DETAILS       =>  "        [%1%] - Site Migration Details\n";
use constant MSG_SITES_SELECTED     =>  "\n    %1% Site(s) selected for migration \n";
use constant IP_ALL_UNASSIGNED      => "<All Unassigned IPs>";
use constant DEFAULT_WEB_SITE       =>  "Default Web Site";
use constant DEFAULT_SITE_ON        =>  "Site On ";
use constant DEFAULT_SITE_FILE        =>  "_Default.txt";

#*****************************************************************************#
# Following set of constants used to define recovery file inputs              #
#*****************************************************************************#
use constant REC_HTTPD_PATH                 =>                  "File Path ";   
use constant REC_ADD_EQUAL                  =>                  "=";   

#*****************************************************************************#
# Following set of constants used to define Web server details                 # 
#*****************************************************************************#
use constant WEB_SERVICE                    =>                  "http";
use constant WEB_PORT                       =>                  "80";
use constant WEB_PROTOCOL                   =>                  "tcp";
use constant WEB_TARGET_SERVER              =>                  "IIS/6.0"; 

#*****************************************************************************#
# Following set of constants are file names used by Parser module             #
#*****************************************************************************#
use constant APACHE_CONFIG          =>  "httpd.conf";
use constant APACHE_ACCESS_CONFIG   =>  "/conf/access.conf";
use constant APACHE_RESOURCE_CONFIG =>  "/conf/srm.conf";
use constant APACHE_NULL_FILE       =>  "/dev/null";

#*****************************************************************************#
# Following set of constants are used to define errors                        #
#*****************************************************************************#
use constant ERR_INTERNAL_ERROR				=>					"An Internal Error has occured.See Log file for details";
use constant ERR_INTERNAL_ERROR_CONSOLE     =>                  "An Internal Error has occured";
use constant ERR_SERVER_NOT_FOUND           =>                  
"\n    The Remote host is not reachable via HTTP.";
use constant ERR_INVALID_FTP_SERVER         =>                  "Unable to open FTP connection to the remote host\n";
use constant ERR_INVALID_LOGIN_CREDENTIALS  =>                  "Invalid login credentials\n";
use constant ERR_INVALID_FILE_PATH          =>                  "Incorrect file path\n\n";
use constant ERR_INPUT_COUNT_OVER           =>                  "Maximum login attempts are over.\n\n";
use constant ERR_INVALID_WEB_SERVER         =>                  "Invalid Web server.Please see the help file for details\n\n";
use constant ERR_INVALID_RECOVERY_FILE      =>                  "Invalid Recovery file.Please rerun the wizard\n\n";
use constant ERR_FILE_TRANSFER              =>                  "An Error has occured while transferring the file\n\n";
use constant ERR_SERVER_IP                  =>                  "Unable to resolve IP of the machine\n\n";
use constant ERR_SERVER_CREDENTIALS         =>                  "Target Machine IP same as Source Machine IP\n\n";
use constant ERR_INPUT_OVER                 =>                  "\nMaximum input attempts are over.\n\n";  
use constant ERR_FILE_READ                  =>                  "An Error occured while reading the file";
use constant ERR_FILE_WRITE                 =>                  "An Error occured while writing to the file";
use constant ERR_FILE_OPEN                  =>                  "An Error occured while opening a file";
use constant ERR_FILE_CLOSE                 =>                  "An Error occured while closing a file";
use constant ERR_FILE_DELETE                =>                  "An Error occured while deleting a file";
use constant ERR_INPUT_CONFIRM              =>                  "\nInvalid Input\n"; 
use constant ERR_FTP_HANDLE_NULL            =>					"Empty file handle for FTP session";
use constant ERR_INVALID_DIRECTORY_PATH		=>					"Directory Path in Tasklist.ini is invalid";
use constant ERR_WRITE_ACCESS_DENIED		=>					"Write access denied to file";
use constant ERR_DESTINATION_PATH			=>					"Error in the destination path.Access denied.";
use constant ERR_CREATE_DIRECTORY			=>					"Cannot create directory in the specified path.Please check permissions";
use constant ERR_OPEN_DIRECTORY				=>					"Cannot open directory";
use constant ERR_READ_DIRECTORY				=>					"Cannot read directory";
use constant ERR_INCORRECT_PERL_VERSION		=>					"AIISMT is not compatable with installed version of PERL";
use constant ERR_SERVER_HTTP_NOTFOUND       =>                  "HTTP Request cannot be completed on Source Machine on Port 80"; 
use constant ERR_VIRTUAL_LINK               =>                  "Invalid Virtual directory Name";
use constant ERR_INVALID_FILE               =>                  "File not found in Directory Path."; 
use constant ERR_INVALID_MACHINE            =>                  "Connection to the remote host cannot be established\n\n" ; 
use constant ERR_INVALID_SUPERUSER          =>                  "SUPER USER rights are required to continue with the migration process \n" ;
use constant ERR_TGT_CONFIG					=>					"Error in configuration of the sites";

###############################################################################
#   Variables added to filter the contents of userinterface
###############################################################################
use constant CON_SITE_DETAILS    =>   "\nIndividual site details\n";
use constant ENABLE_SSL          =>   "SSL Enabled\n\n"; 
use constant CON_IPPORT_SOURCE   =>   "IP:PORT on Source Machine=";
use constant CON_IPPORT_TARGET   =>   "IP:PORT on Target Machine=";
use constant CON_FTP_START       =>   "\n FTP is not running at the Local Machine.Please start FTP and rerun the wizard...\n" ;

#*****************************************************************************#
# Following set of constants are used to display messages at command prompts  #
#*****************************************************************************#
use constant MSG_METHOD_SUCCESSFUL         =>                   "method execution successful"; 
use constant ERR_METHOD_UNSUCCESSFUL       =>                   "method execution not successful";    
use constant MSG_MAXIMUM_COUNTS            =>                   "Maximum attempts";
use constant MSG_FILE_TRANSFER_SUCCESS     =>                   "\nFile transferred successfully";
use constant MSG_SESSION_NAME              =>                   "Session Name";
use constant MSG_SOURCE_WEB_SERVER		   =>                   "Source Web Server";	
use constant MSG_TARGET_WEB_SERVER		   =>                   "Target Web Server";	
use constant MSG_SESSION_START_TIME        =>                   "Start Time";
use constant MSG_SESSION_END_TIME          =>                   "End Time";
use constant MSG_RUNNING_MODE              =>                   "Running Mode "; 
use constant MSG_FILE_OPEN				   =>					"File Opened successfully";
use constant MSG_FILE_CLOSE				   =>					"File Closed successfully";	
use constant MSG_FILE_DELETE			   =>					"File Deleted successfully";	
use constant MSG_USER_VALIDATE             =>                  	"Validate User";
use constant MSG_USER_RIGHTS               =>                   "Validate User Rights";
use constant MSG_USER_PERMISSION           =>                   "Validate Permissions"; 
use constant MSG_USAGE_COMPLETE            =>                   "\nCurrent migration session name has been used and completed on current machine.\n
Please enter a different session name and continue...\n";  

#*****************************************************************************#
# Following set of constants are used to define error messages of parser      #
#*****************************************************************************#
use constant ERR_CRITICAL           =>  "\n A CRITICAL ERROR has occured. Quitting AIISMT\n";
use constant ERR_NON_CRITICAL       =>  "\n ERROR : ";
use constant ERR_INVALID_INPUT      =>  "\n INVALID INPUT : ";
use constant ERR_OPENING_CONFIG     =>  " Unable to open Apache configuration file ";
use constant ERR_INVALID_IP         =>  " is not a valid IP address! \n";
use constant ERR_INVALID_PORT       =>  " is not a valid Port Number! \n";
use constant ERR_ONLY_YES_OR_NO     =>  " Please enter only 'Y' or 'N'\n";
use constant ERR_INVALID_DRIVE      =>  " Invalid Drive! Please enter a valid path \n";
use constant ERR_INVALID_PATH       =>  " Invalid Characters found in Path \n";
use constant ERR_INVALID_OS         =>  "Local Machine is not running on Linux.Thank You for using AIISMT"; 

#*****************************************************************************#
# Following set of constants are used to define  error messages of ILog 
#*****************************************************************************#
use constant ILOG_WRKDIR			=> " Error in ilog_ChangeWorkingDirectory\n ";
use constant ILOG_OPENFILE			=> " Error in ilog_OpenFile\n ";
use constant ILOG_GETDATA			=> " Error in ilog_getDataToPopulate\n";
use constant ILOG_FILLDATA			=> " Error in ilog_FillData\n";
use constant ILOG_CLOSEFILE			=> " Error in ilog_CloseFile\n";
use constant ILOG_SETLOGINFO		=> " Error in ilog_setLogInformation\n";
use constant DEBUG_ONLY             => 9999;
use constant OVERWRITE              => 4444;

#*****************************************************************************#
# Following set of constants are used to define  messages of WorkItems Source #
#*****************************************************************************#

use constant INF_DIR_PRESENT       =>  " Destination directory is already present and is valid \n";
use constant INF_OLDDIR_PRESENT	   =>  " Old destination directory path is valid \n";
use constant INF_OLDDIR_INVALID    =>  " Old destination directory path is invalid \n";
use constant INF_ROOT_DIR		   =>  " Files to be inserted into the root directory \n";
use constant ERR_PWD_INVALID	   =>  " Error in obtaining the present working directory path \n";
use constant ERR_PWD_ERROR		   =>  " Path could not be redirected back to the working directory \n";
use constant ERR_DIR_ACCESSDENIED  =>  " Directory cannot be created cause access denied \n";
use constant ERR_CWD_COMMAND	   =>  "Error during change of working directory";
use constant ERR_MKDIR_COMMAND	   =>  "Error during make directory";
use constant ERR_MKDIR_NO_RIGHTS   =>  "Write Permission to FTP ROOT is Denied by Remotehost.
AIISMT requires write access to enable migration..."; 


#*******************************************************************************
#       Constants used for HTML Reporting...
#*******************************************************************************
use constant    HTM_BEGIN           =>   "htm_begin";
use constant    HTM_END             =>   "htm_end";
use constant    HTM_DEFAULT_BEGIN   =>  "<HTML>";
use constant    HTM_TABLE_END       =>  "</TABLE>";
use constant    HTM_DEFAULT_END     =>  HTM_TABLE_END."</BODY></HTML>"; 
use constant    HTM_STATUS_TITLE    =>  "<center><H1>Apache to Azure App Service Migration Tool</H1></center>";
use constant    HTM_LOG_TITLE       =>  "<center><H1>Apache to Azure App Service Migration Tool</H1></center>";
use constant    HTM_STATUS_TABLE    =>  "<TABLE BORDER = 1><TR><TD><b>Information</b></TD><TD><b>Description</b></TD></TR>";   
use constant    HTM_LOG_TABLE       =>  "<TABLE BORDER = 1><TR><TD><b>Line No</b></TD><TD><b>Module Name</b></TD><TD><b>Information</b></TD><TD><b>Description</b></TD></TR>";   
use constant    HTM_STATUS_BEGIN    =>  HTM_DEFAULT_BEGIN.HTM_STATUS_TITLE."<BODY><CENTER><H1>Status Report</H1></CENTER>".HTM_STATUS_TABLE;
use constant    HTM_LOG_BEGIN       =>  HTM_DEFAULT_BEGIN.HTM_LOG_TITLE."<BODY><CENTER><H1>Log Report</H1></CENTER>".HTM_LOG_TABLE;
use constant    HTM_STATUS_END      =>  HTM_DEFAULT_END;
use constant    HTM_LOG_END         =>  HTM_DEFAULT_END;

#*****************************************************************************#
# Following set of error constants are used by parser module while populating the 2d array#
#*****************************************************************************#
use constant SITENAME						=> 0;
use constant DIRECTORY						=> 1;
use constant FILES		    				=> 2;
use constant KEEPALIVE						=> 3;
use constant KEEPALIVETIMEOUT				=> 4;
use constant LISTEN							=> 5;
use constant LISTENBACKLOG					=> 6;
use constant MAXCLIENTS						=> 7;
use constant NAMEVIRTUALHOST				=> 8;
use constant OPTIONS						=> 9;  	
use constant ORDER							=> 10;
use constant PORT							=> 11;  	
use constant RESOURCECONFIG					=> 12;
use constant SCRIPTALIAS					=> 13;
use constant SCRIPTALIASMATCH				=> 14;
use constant SERVERALIAS					=> 15;
use constant SERVERNAME						=> 16;
use constant SERVERROOT						=> 17;
use constant TIMEOUT						=> 18;
use constant USERDIR						=> 19;
use constant VIRTUALHOST					=> 20;
use constant ACCESSCONFIG					=> 21;
use constant ADDENCODING					=> 22;
use constant ADDTYPE						=> 23;
use constant ALIAS							=> 24;
use constant ALIASMATCH						=> 25;
use constant AUTHGROUPFILE					=> 26;
use constant AUTHNAME						=> 27;
use constant AUTHTYPE						=> 28;
use constant AUTHUSERFILE					=> 29;
use constant BINDADDRESS					=> 30;
use constant DEFAULTTYPE					=> 31;
use constant DENY							=> 32;
use constant DIRECTORYMATCH					=> 33;
use constant DIRECTORYINDEX					=> 34;
use constant DOCUMENTROOT					=> 35;
use constant ERRORDOCUMENT					=> 36;
use constant ERRORLOG						=> 37;
use constant EXPIRESACTIVE					=> 38;
use constant EXPIRESDEFAULT					=> 39;
use constant EXPIRESBYTYPE					=> 40;
use constant FILESMATCH						=> 41;	
use constant HEADER							=> 42;
use constant HOSTNAMELOOKUPS				=> 43;
use constant IDENTITYCHECK					=> 44;
use constant IFMODULE						=> 45;
use constant ALLOWOVERRIDE					=> 46;
use constant SSLENGINE						=> 47;
use constant SSLCERTIFICATEFILE				=> 48;
use constant SSLCERTIFICATEKEYFILE		   	=> 49;
use constant USERDIRENABLED					=> 50;
use constant USERDIRDISABLED				=> 51;	
use constant ACCESSFILENAME					=> 52;
use constant DESTINATIONPATH		 		=> 53;
use constant DIRBITSET						=> 54;
use constant USERENABLED					=> 55;
use constant USERDISABLED					=> 56;
use constant TASKLIST						=> 57;
use constant XML							=> 58;
use constant HTACCESS						=> 59;
use constant MYSQL                          => 60;
use constant FRAMEWORK                      => 61;
use constant CONFIGFILE                     => 62;
use constant PUBLISH                        => 63;
use constant DB_NAME                        => 64;
use constant DB_USER                        => 65;
use constant DB_PASS                        => 66;
use constant DB_HOST                        => 67;
use constant INCLUDED_FILES                 => 68;
use constant WP_SITEURL                     => 69;

use constant WORDPRESS    => 'Wordpress';
use constant DRUPAL       => 'Drupal';
use constant JOOMLA       => 'Joomla';

use constant PATH_ABS		=> 1;
use constant PATH_REL		=> 0;
use constant FILE_READ		=> 1;
use constant FILE_WRITE		=> 2;
use constant FILE_APPEND	=> 3;
use constant FILE_WRITE_EX	=> 4;
use constant FILE_READ_EX	=> 5;
use constant AAMT_ERR_FILEOPEN_FAILED => "File could not be opened";
use constant RECOVERY_MODE_0    => "FRESHRUN";
use constant RECOVERY_MODE_1    => "WSMKREC1";
use constant RECOVERY_MODE_2    => "WSMKREC2";
use constant RECOVERY_MODE_3    => "WSMKREC3";
use constant RECOVERY_MODE_COMPLETE => "WSMKREC3";
use constant TASKLIST_DELIM		=>  "|"; # old value"²"; 
use constant L_TIME_LAPSE		=> 30;
use constant CLEANUP_AND_EXIT  =>  "EXIT_TOOL_NOW";
use constant MIME_TYPES_FILE	=>  "mime.types";
use constant ERR_OPENING_MIME_FILE => "Error opening mime file"; 
1;
