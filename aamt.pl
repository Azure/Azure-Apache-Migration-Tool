use strict;
# package used to get the current working folder
use aamt_wrkFolder;
my $currentLibfolder;
# get the current working folder and unset the environment variable that has been set in the 
# batch file/ shell script file 
BEGIN {$currentLibfolder = main_getCurrentLibFolder();}
use vars qw/$currentLibfolder/;
use lib $currentLibfolder;

#Standard and nonstandard packages used by the tool 
use strict;                 #for declaration of variables prior to use
use FileHandle;             #for file operations
use File::Copy;             #for copying the file in a local machine  
use File::Path;
use LWP::Simple;            #for website header information
use IO::Dir;			    #for directory handling
use Sys::Hostname;          # 
use File::Listing;          #to display a list of files in a directory  
use Time::localtime;        #get system time information

# custom packages developed to be used by the tool	
use aamt_constants;		    #for user input or error or file constants 
use aamt_utilityFunctions;  #for common procedures
use aamt_informationLog;    #used for logging information into Log,Status or Recovery file
use aamt_userInterface;     #used for user interface definition

my $globRunMode;
sub utf_getRunMode
{
    return $globRunMode;
}
sub utf_setRunMode
{
    $globRunMode=$_[0];
}

use aamt_auth;	            #used for Authentication and user query module 	
use aamt_parse;             #used for parsing the conf file and getting the site information	
use aamt_parse2;		    #used for parsing the conf file and generating the 2D array.

# main subroutine starts here
my $localConfFilePath;
my $boolVersionNumber;
my $blnWISrcRet;
my $logFileReturn;
my $RecoveryMode = "";
my $DEBUG_MODE = 0;

use Getopt::Long qw(GetOptions);

my $mode;
my $configfile;
my $siteindex;
my $pubprofile;
my @params;


eval
{
    &usage() if (
        !GetOptions(
        'help|?'=>\&modeHelp,
        'interactive'=>\&modeInteractive,
        'list=s{1,2}'=>\&modeList,
        'deploy=s{3,4}'=>\&modeDeploy));
    if($mode eq 'interactive'){
        &runInteractive();
    }
    elsif($mode eq 'list'){
        &runList();
    }
    elsif($mode eq 'deploy'){
        &runDeploy();
    }
    else{
        &runHelp();
    }
    
 
};
if($@)
{
    if ($@ !~ /EXIT_TOOL_NOW/)
    {        
        # Abnormal Termination ... 
        print "$@";
        &DeleteWorkingFolder();
    }
}
# end of main subroutine

sub usage
{
    ilog_print(1,"Unknown option:@_\n") if (@_);
    ilog_print(1,"Usage: sudo perl $0 [-i|--interactive]\n");
    ilog_print(1,"Usage: sudo perl $0 [-l|--list configfile]\n");
    ilog_print(1,"Usage: sudo perl $0 [-d|--deploy  configfile siteindex publishprofile]\n");
    ilog_print(1,"Usage: perl $0 [--help|-?]\n");
    ilog_print(1,"configfile: The apache main config file\n");
    ilog_print(1,"siteindex: The index of the source web site and should be number\n");
    ilog_print(1,"publishprofile: The publishing profile file of the target azure web site\n");
    exit 0;
}

sub modeHelp
{
    if($mode && $mode ne 'help'){&usage();};
    $mode='help';
    &utf_setRunMode($mode);
}

sub modeInteractive
{
   if($mode && $mode ne 'interactive') {&usage();};
   $mode='interactive';
   &utf_setRunMode($mode);
}

sub modeList
{
    if($mode && $mode  ne 'list') {&usage();}
    $mode='list';
    my($name,$val)=@_;
    push @params,$val;
    &usage() if($#params>0);
    $configfile=$params[0];
    &utf_setRunMode($mode);
}

sub modeDeploy
{
    if($mode && $mode ne 'deploy') {&usage();}
    $mode='deploy';
    my($name,$val)=@_;
    push @params,$val;
    &usage() if($#params>2);
    if($#params==2)
    {
        $configfile=$params[0];
        $siteindex=$params[1];
        &usage() if(!($siteindex =~ m/^\d+$/));
        $pubprofile=$params[2];
        &utf_setRunMode($mode);
    }
}


sub runInteractive
{
   my $auqRetVal;
    ($auqRetVal,$localConfFilePath) = auth_main();        # AUQ module functionality    
    if(!($auqRetVal))
    {
        &DeleteWorkingFolder();
	    die CLEANUP_AND_EXIT;
    }
    
    if (auth_isRecovery() eq "RECOVERY") 
    {
        $RecoveryMode = pars_GetRecoveryCode();
    }

    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: RECOVERY MODE: [$RecoveryMode]\n"); }
    if ( ($RecoveryMode ne RECOVERY_MODE_1) && ($RecoveryMode ne RECOVERY_MODE_2) && ($RecoveryMode ne RECOVERY_MODE_3))
    {        
	    &pars_FirstPass($localConfFilePath);    # Parser Module first pass
        &pars_SetRecoveryCode(RECOVERY_MODE_1);
    }
    
    if (($RecoveryMode ne RECOVERY_MODE_2) && ($RecoveryMode ne RECOVERY_MODE_3))
    {
        if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: CONCATENATING CONFIG FILES\n"); }
        # Concatenate all of the configuration files in preparation for the next step where we parse the master file
        use Cwd;
        my $pwd = cwd();
        # get the current working folder
        my $strCurWorkingFolder = &utf_getCurrentWorkingFolder();
        # get session name
        my $strSessionName = &ilog_getSessionName();
        # form the complete working folder
        my $workingFolder = $strCurWorkingFolder . '/' . $strSessionName;
        # change local dir
        my $retwrk_changeLocalDir = wrk_changeLocalDir($workingFolder);
        if (!($retwrk_changeLocalDir))
        {
            $logFileReturn= ilog_setLogInformation('EXT_ERROR',ERR_CWD_COMMAND,'', __LINE__);
            if(!($logFileReturn))
            {	
                $logFileReturn=ilog_print(ERR_INTERNAL_ERROR_CONSOLE.__LINE__,1);
            }

            return 0;
        }

        # my @files        = grep { -f } glob( '*.conf' );
        my @files = File::Find::Rule->file()
            ->name("*apache*")            
            ->in($workingFolder);

       if(! @files)
       {
           @files = File::Find::Rule->file()
           ->name("*httpd*")
           ->in($workingFolder);
       }
        
        my @fhs          = map { open my $fh, '<', $_; $fh } @files;
        my $concatenated = '';
        while (my $fh = shift @fhs) 
        {
            while ( my $line = <$fh> )
            {
                $concatenated .= $line;
            }

            close $fh;
        }

        # go back to orginal dir
        chdir($pwd); 

        my $confAllName = &utf_getCompleteFilePath(FILE_CONF_ALL);
        my $HANDLE_CONF_ALL = new IO::File;
        if(open(HANDLE_CONF_ALL,">> $confAllName") or die 'ERR_FILE_OPEN')
        {
            print HANDLE_CONF_ALL $concatenated;
            close(HANDLE_CONF_ALL); 
        }
     
        my $logFilereturn = ilog_setLogInformation('REC_INFO',"FILE_CONF_ALL ".REC_ADD_EQUAL,&utf_getCompleteFilePath(FILE_CONF_ALL),'');
        &pars_SetRecoveryCode(RECOVERY_MODE_2);
    }

    if (($RecoveryMode ne RECOVERY_MODE_3))
    {
        if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: RECOVERY MODE: [$RecoveryMode]\n"); }
        &pars_Generate2D(&utf_getCompleteFilePath(FILE_CONF_ALL), &utf_getCompleteFilePath(FILE_RECOVERY), $RecoveryMode);
        &pars_UploadPublishSettingsAllSites();
    }

    &pars_SetRecoveryCode(RECOVERY_MODE_3);
	utf_setCurrentModuleName(''); 
	&utf_gettimeinfo('1');
    &DeleteWorkingFolder();
    &TerminateTool();
}

sub runList
{
    my $auqRetVal;
    ($auqRetVal,$localConfFilePath) = auth_main('model_dummy_session',$configfile);        # AUQ module functionality
    if(!($auqRetVal))
    {
        &DeleteWorkingFolder();
            die CLEANUP_AND_EXIT;
    }


    &pars_FirstPass($localConfFilePath);    # Parser Module first pass
    &pars_SetRecoveryCode(RECOVERY_MODE_1);

    # Concatenate all of the configuration files in preparation for the next step where we parse the master file
    use Cwd;
    my $pwd = cwd();
    # get the current working folder
    my $strCurWorkingFolder = &utf_getCurrentWorkingFolder();
    # get session name
    my $strSessionName = &ilog_getSessionName();
    # form the complete working folder
    my $workingFolder = $strCurWorkingFolder . '/' . $strSessionName;
    # change local dir
    my $retwrk_changeLocalDir = wrk_changeLocalDir($workingFolder);
    if (!($retwrk_changeLocalDir))
    {
        $logFileReturn= ilog_setLogInformation('EXT_ERROR',ERR_CWD_COMMAND,'', __LINE__);
        if(!($logFileReturn))
       {
           $logFileReturn=ilog_print(ERR_INTERNAL_ERROR_CONSOLE.__LINE__,1);
        }

        return 0;
    }

    # my @files        = grep { -f } glob( '*.conf' );
    my @files = File::Find::Rule->file()
        ->name("*apache*")
        ->in($workingFolder);

    if(! @files)
    {
        @files = File::Find::Rule->file()
        ->name("*httpd*")
        ->in($workingFolder);
    }

    my @fhs          = map { open my $fh, '<', $_; $fh } @files;
    my $concatenated = '';
    while (my $fh = shift @fhs)
    {
        while ( my $line = <$fh> )
        {
            $concatenated .= $line;
        }

        close $fh;
    }

    # go back to orginal dir
    chdir($pwd);

    my $confAllName = &utf_getCompleteFilePath(FILE_CONF_ALL);
    my $HANDLE_CONF_ALL = new IO::File;
    if(open(HANDLE_CONF_ALL,">> $confAllName") or die 'ERR_FILE_OPEN')
    {
        print HANDLE_CONF_ALL $concatenated;
        close(HANDLE_CONF_ALL);
    }

    my $logFilereturn = ilog_setLogInformation('REC_INFO',"FILE_CONF_ALL ".REC_ADD_EQUAL,&utf_getCompleteFilePath(FILE_CONF_ALL),'');
    &pars_SetRecoveryCode(RECOVERY_MODE_2);

    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: RECOVERY MODE: [$RecoveryMode]\n"); }
    &pars_Generate2D(&utf_getCompleteFilePath(FILE_CONF_ALL), &utf_getCompleteFilePath(FILE_RECOVERY), $RecoveryMode);

    if(! &pars_IsNoSiteSelected()) { &pars_UploadPublishSettingsAllSites();}

    &pars_SetRecoveryCode(RECOVERY_MODE_3);
    &utf_setCurrentModuleName('');
    &utf_gettimeinfo('1');
    &DeleteWorkingFolder();
    &TerminateTool();
}

sub runDeploy
{
    my $auqRetVal;
    ($auqRetVal,$localConfFilePath) = auth_main('modeld_dummy_session',$configfile);        # AUQ module functionality
    if(!($auqRetVal))
    {
        &DeleteWorkingFolder();
            die CLEANUP_AND_EXIT;
    }


    &pars_FirstPass($localConfFilePath);    # Parser Module first pass
    &pars_SetRecoveryCode(RECOVERY_MODE_1);

    # Concatenate all of the configuration files in preparation for the next step where we parse the master file
    use Cwd;
    my $pwd = cwd();
    # get the current working folder
    my $strCurWorkingFolder = &utf_getCurrentWorkingFolder();
    # get session name
    my $strSessionName = &ilog_getSessionName();
    # form the complete working folder
    my $workingFolder = $strCurWorkingFolder . '/' . $strSessionName;
    # change local dir
    my $retwrk_changeLocalDir = wrk_changeLocalDir($workingFolder);
    if (!($retwrk_changeLocalDir))
    {
        $logFileReturn= ilog_setLogInformation('EXT_ERROR',ERR_CWD_COMMAND,'', __LINE__);
        if(!($logFileReturn))
       {
           $logFileReturn=ilog_print(ERR_INTERNAL_ERROR_CONSOLE.__LINE__,1);
        }

        return 0;
    }

    # my @files        = grep { -f } glob( '*.conf' );
    my @files = File::Find::Rule->file()
        ->name("*apache*")
        ->in($workingFolder);

    if(! @files)
    {
        @files = File::Find::Rule->file()
        ->name("*httpd*")
        ->in($workingFolder);
    }

    my @fhs          = map { open my $fh, '<', $_; $fh } @files;
    my $concatenated = '';
    while (my $fh = shift @fhs)
    {
        while ( my $line = <$fh> )
        {
            $concatenated .= $line;
        }

        close $fh;
    }

    # go back to orginal dir
    chdir($pwd);

    my $confAllName = &utf_getCompleteFilePath(FILE_CONF_ALL);
    my $HANDLE_CONF_ALL = new IO::File;
    if(open(HANDLE_CONF_ALL,">> $confAllName") or die 'ERR_FILE_OPEN')
    {
        print HANDLE_CONF_ALL $concatenated;
        close(HANDLE_CONF_ALL);
    }

    my $logFilereturn = ilog_setLogInformation('REC_INFO',"FILE_CONF_ALL ".REC_ADD_EQUAL,&utf_getCompleteFilePath(FILE_CONF_ALL),'');
    &pars_SetRecoveryCode(RECOVERY_MODE_2);

    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: RECOVERY MODE: [$RecoveryMode]\n"); }
    &pars_Generate2D(&utf_getCompleteFilePath(FILE_CONF_ALL), &utf_getCompleteFilePath(FILE_RECOVERY), $RecoveryMode,$siteindex);

    if(! &pars_IsNoSiteSelected()) { &pars_UploadPublishSettingsAllSites($pubprofile);}

    &pars_SetRecoveryCode(RECOVERY_MODE_3);
    &utf_setCurrentModuleName('');
    &utf_gettimeinfo('1');
    &DeleteWorkingFolder();
    &TerminateTool();
}

sub runHelp()
{
    &usage();
}

sub TerminateTool
{
    # Clean up and exit tool
    &utf_DisposeFiles();
    # Restore the include to the original value
    @INC = @lib::ORIG_INC;
    exit(0);
}

sub DeleteWorkingFolder
{
    my $strYesOrNo = "";
    if(&utf_getRunMode eq 'interactive'){
        while($strYesOrNo!~/^\s*[YynN]\s*$/)
        {
            ilog_printf(1, "    Would you like to delete the working folder used to store temporary settings? (Y/N):");
            chomp($strYesOrNo = <STDIN>);
            ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO)
                if ($strYesOrNo!~/^\s*[YynN]\s*$/);
            if ($strYesOrNo=~/^\s*[Yy]\s*$/)
            {
                rmtree([&utf_getCurrentWorkingFolder().'/'.&ilog_getSessionName()]);
            }    
        }
    }
    else{
          rmtree([&utf_getCurrentWorkingFolder().'/'.&ilog_getSessionName()]);
    }
}
