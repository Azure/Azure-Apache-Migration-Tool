################################################################################
#Declaration of global variables for AUQ module
################################################################################ 
my $auqRetVal;                                      #Main return value from the AUQ module                            
my $sessionName;									#Session Name of a migration process (required for recovery) 
my $filePath;										#path for the http configuration file at the source machine		
my $sessionFilename ;								#Recovery file name
my $statusLogFile ;									#Status file name				
my $errorLogFile ;                                  #Log file name
my $LocalFileName;									#Renamed file name of configuration file
my $SESSIONFILELANDLE;                              #File handle for session file
my $migrationStatus;                                #To indicate the wizard is running in FRESHRUN mode or RECOVERY
my $logFilereturn;	                                #RETURN VALUE for the file access methods in aamt_informationLog 
my $parseSuccess ;                                  #To run in the recovery mode, the output of auth_parseRecovery file 
my $startTime;                                      #Migration start time for logging 
my $fileret;
my $tempretval;
my $return = 1;
my $dirSuccess=0;
my @fileparse; 
my $lineContent;
my @tempfileparse;
my $recoveryFile;
my $retval;

##############################################################################		
####  Variables used to define user prompt####################################
############################################################################## 
my  $REC_HTTPD_PATH = REC_HTTPD_PATH; 
my  $NEW_REC_HTTPD_PATH = NEW_REC_HTTPD_PATH;   
my  $LISTEN   =FP_DEFAULT_LISTEN;
my  $REC_USER_DIR     ='[USER_DIR]' ;
my  $REC_MY_NAME_VIRTUAL_HOST ='[NAME_VIRTUAL_HOST]' ; 

################################################################################
#Main Subroutine for AUQ module starts here
################################################################################ 	
sub auth_main                                               
{
    ui_clearScreen();         #used to clear screen defined in aamt_userinterface.pm file
	ui_Title();               #used for title of the migartion kit defined in aamt_userinterface.pm file	
    if (!&auth_isUserRoot())
    {
        return (0, 0);
    }

    ui_printBanner();
	&ilog_print(1,TITLE_SESSION_NAME);                      #To display title pertaining to session name    
	($tempretval,$sessionName)=auth_inputSessionName();     #user input "session name" for migration   
	if(!($tempretval))
    {
        $auqRetVal=0;
        return($auqRetVal,0);
    }
	else
    {
        ilog_setSessionName($sessionName);              #set session name for the migration  
    }
 
	utf_setCurrentWorkingFolder();    
	($dirSuccess,$migrationStatus)=auth_createSessionDirectory($sessionName);            
    #create a folder with session name in current working folder 
	if (!($dirSuccess))
    {
        $auqRetVal=0;
        return($auqRetVal,0);
    }
	
	&pars_SetSessionFolder();                              	#Set the folder to current session folder
    &utf_gettimeinfo('0');                                     #Migration start time is to be written to log file	
	utf_setCurrentModuleName(AUQ);                        #set module name as AUQ for Authentication and UserQuery 
    #Module		
	
################################################################################
#The loop basing on migration status (FRESHRUN or RECOVERY) starts here
################################################################################ 
	if ($migrationStatus eq 'FRESHRUN')
	{
		&utf_setCurrentModuleName(''); 
		$logFilereturn = ilog_setLogInformation('EXT_INFO',MSG_SESSION_NAME,$sessionName,''); 
        #Log session name to AIISMT files
		if(!($logFilereturn))
		{
			$logFilereturn=ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
			$auqRetVal=0;
			return ($auqRetVal,0); #return FALSE
		}

		utf_setCurrentModuleName(AUQ); 		
        &pars_SetRecoveryCode(RECOVERY_MODE_0);  #Log Recovery Mode to AIISMT files		
        if(!($logFilereturn))
		{
			$logFilereturn=ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
			$auqRetVal=0; 
			return ($auqRetVal,0); #return FALSE
		}

		ui_printBanner("Source Configuration Details\n");
        &ilog_print(1,TITLE_SOURCE_IP);                    #Source IP keyword    
        $sourceMachineAddress = 'localhost';

        $logFilereturn= ilog_setLogInformation('REC_INFO',REC_SOURCE_IP.REC_ADD_EQUAL,$sourceMachineAddress,'');
        $logFilereturn= ilog_setLogInformation('EXT_INFO',REC_SOURCE_IP,$sourceMachineAddress,'');
        if(!($logFilereturn))
        {
            ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
            $auqRetVal=0;
            return ($auqRetVal,0); #return FALSE
        }
        
        $auqRetVal=1; # return TRUE
        $logFilereturn= ilog_setLogInformation('REC_INFO',REC_MACHINE_TYPE.REC_ADD_EQUAL ,'S','');
        $logFilereturn= ilog_setLogInformation('EXT_INFO',REC_MACHINE_TYPE ,CON_EXEC_SOURCE_MODE,'');
        if(!($logFilereturn))
        {
            ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
            $auqRetVal=0;
            return ($auqRetVal,0); #return FALSE
        }

        ($tempretval,$filePath)=auth_inputFilePath();      # Http configuration file path of the source machine
        if($tempretval)
        {                
            $auqRetVal =1;                                 #Success of AUQ module
        }
        else
        {
            
            $auqRetVal =0;                                 #AUQ module	Failed
            return($auqRetVal,0);
        }
        #loop for FRESHRUN ends here 
	}
	else                                                    #loop for RECOVERY starts here
	{
		@fileparse = auth_displaySessionFile(); #contents of recovery file is shown
		if(@fileparse)
		{
			if($fileparse[0] eq RECOVERY_MODE_COMPLETE)
            {
                ilog_print (1,MSG_USAGE_COMPLETE);
                $auqRetVal=0;
                return ($auqRetVal,0); #return FALSE
            }

			$tempretval=auth_resumeMigrate(CON_RECOVERY_MODE);
			if($tempretval)
            {
                $auqRetVal=1;                
            }
            else
            {
                $auqRetVal=0;
            }
		}
	}

	$LocalFileName =AMW.$sessionName.FILE_CONF;              #called both for freshrun and recovery
	return ($auqRetVal,$LocalFileName);                    #returned to the main function            
}

################################################################################
#Main Subroutine for AUQ module ends here
################################################################################ 	

#---------------------------------------------------------------------------------
#Method Name	:	auth_checkIfUserIsRoot
#Description	: 	Checks if the user is root
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub auth_isUserRoot
{
    if ($> == 0)
    {        
        return 1;
    }
    
    ilog_print(1,"ERROR: Script must be run as root\n");    
    return 0;
}

#---------------------------------------------------------------------------------
#Method Name	:	auth_getConfFile
#Description	: 	Gets the http configuration file to the local working directory 
#Input		    :	Remote filename
#Output		    :	Local  filename 
#			        
#			        
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub auth_getConfFile
{
	#Local Variable declaration	
	my $RemoteFileName = shift;	                            #httpd.conf filename path 		
	my $LocalFileName;                                      #renamed httpd.conf file in the current session folder
	my $fileReturn;     
	my $ftpCount;
	my $FTPSESSIONHANDLE;
	
    #Local Variable initialization
	$LocalFileName =AMW.$sessionName.FILE_CONF;
	$LocalFileName="./$sessionName/$LocalFileName";        #appended to the full path
	$ftpCount =0;
	eval
	{
        $fileReturn = File::Copy::copy($RemoteFileName, $LocalFileName);
        if (!$fileReturn)
        {
            ilog_print(1,"ERROR: copying: $RemoteFileName TO $LocalFileName \n");
        }        
	};	
	
	if($@)
    {
        if($@ = ~/ERR_INVALID_FILE_PATH/)
        {
            ilog_print(1,"\n");
            $logFilereturn = ilog_displayandLog(ERR_INVALID_FILE_PATH,1,'INT_ERROR','','',__LINE__);
            if(!($logFilereturn))
            {
                ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
                exit(0);
                
            }
            $fileReturn= FALSE;
        }
    }
	if ($fileReturn)
    { 
        ilog_print(DEBUG_ONLY,MSG_FILE_TRANSFER_SUCCESS);
    }
	
    return $fileReturn;
}

#---------------------------------------------------------------------------------
#Method Name	:	auth_inputParam
#Description	: 	Inputs parameters from the console in visible/invisible mode
#Input			:1. Prompt Message					
#				 2. Default Value
#				 3. Visible Flag
#				 4. Validation type can be 
#						I  Integer 
#						S  String 
#						M  Machine address
#						F  File path
#                5. Machine Type Source/Target       
#
#Output		    :	Nil
#
#			        
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub auth_inputParam
{
	my $returnparam = 0;									        #return value of the function  		
	my($PromptMsg, $DefaultVal, $Visibleflag,$ValidationType, $MachineType) = @_;
    #the value input by the user goes here
	my $Value;														#VisibleFlag determines whether the input is
    #supposed to be visible or hidden
	# if($Visibleflag eq "VISIBLE")
    # {
		ilog_print(1,$PromptMsg);
		chomp($Value = <STDIN>);					                    #input the value
		$Value =~ s/^\s+//;
		$Value =~ s/\s+$//;		
		$Value = ltrim($Value);
		
		if($Value eq "")						                    #default value incase the user enters blank
        {
			if (!($DefaultVal eq ''))
            {
                $Value = $DefaultVal;
                $returnparam =1;
            }	                        
			else
            {
                $returnparam = 0;                         
                return (0,$Value)
            } # but if input and default, both are blank, ask for reinput...
        }
		else
        {
			$returnparam =1;          # basic validation has been removed for taking consideration the linux file structure 
			if ($returnparam)											#if the input is valid
            {
                if ($ValidationType eq 'M')
                {                    
                    if ($Value eq '') 
                    {
                        $logFilereturn = ilog_setLogInformation('INT_INFO',ERR_INTERNAL_ERROR_CONSOLE,'',__LINE__);
                        $returnparam  = 0;
                        return (0,$Value)				#for loopback
                    }                    
                }
            }
			else
            {
				$logFilereturn = ilog_displayandLog(ERR_INPUT_CONFIRM,1,'INT_ERROR',ERR_SERVER_IP,'',__LINE__);			  	
				return (0,$Value);
            }            
        } 
    # }
    
    # if($Visibleflag eq "HIDDEN")
    # { 
    #     ReadMode('noecho');
    #     ilog_print(1,$PromptMsg);        
    #     chop($Value = ReadLine(0));						#input the value        
    #     <STDIN>
    #     if($Value eq ""){$Value = $DefaultVal};			#default value incase the user enters blank
    #     ReadMode 1;
    #     ilog_print(1,"\n");
    #     $returnparam =1;
    # }
    
	if ($returnparam)
    {		
		return (1,$Value);
    }
}

#---------------------------------------------------------------------------------
#Method Name	:	auth_createSessionDirectory
#Description	: 	Creates a directory in the current working folder
#Input		    :	1. sessionName from user
#			        2.
#Output		    :	1. migration status (FRESHRUN or RECOVERY)
#Return Value   :	boolean
#---------------------------------------------------------------------------------
sub auth_createSessionDirectory
{
	my $DIRHANDLE;
	my $returnDirectory;
	my $fileSuccess;
	my $filename;
	my $fileExist;
	my $displaySuccess;
	my $returnCreateSuccess;
	my $tempretval;
	
	$migrationStatus='';
	$returnCreateSuccess=0;
	$sessionFilename= "./sessions/$sessionName/$sessionFilename";           #appended with the full path 
	$DIRHANDLE= new IO::Dir ".";
    if(opendir (DIRHANDLE,$sessionName))
    {
        $sessionFilename =AMW.$sessionName.FILE_RECOVERY;        
        while (defined($filename = readdir(DIRHANDLE))) 
        {            
            if ($filename =~/$sessionFilename/i)
            {
                $fileExist =1;
            }
        }
        
        if($fileExist)
        {
            ilog_setLogInformation("EXT_INFO","<Recovery Info>","","");
            $migrationStatus = 'RECOVERY';
            $returnCreateSuccess =TRUE;
        }        
        else
        {
            $logFilereturn = ilog_print(1,ERR_INVALID_FILE);
            exit(0);
        }
    }    
    else		
    {		
        eval
        {
            $returnDirectory=mkdir($sessionName) or die 'ERR_CREATE_DIRECTORY';   #creates a directory in the current working directory
            if($returnDirectory)	
            {
                $fileSuccess = auth_createSessionFile();
                if(!($fileSuccess)) 
                {
                    $logFilereturn= ilog_setLogInformation('INT_ERROR','auth_createSessionFile()',ERR_METHOD_UNSUCCESSFUL,__LINE__);
                }	
                else
                {
                    $migrationStatus = 'FRESHRUN';
                    $returnCreateSuccess =TRUE;                    
                }                
            }
        };
    }    
    
    closedir(DIRHANDLE);	
	if($@)
	{
		if($@=~/ERR_CREATE_DIRECTORY/)
        {
            # log error and exit tool
            $logFilereturn=ilog_print(1,ERR_CREATE_DIRECTORY);
        }		
	}
    
    return ($returnCreateSuccess,$migrationStatus);
}

#---------------------------------------------------------------------------------
#Method Name	:	auth_createSessionFile
#Description	: 	Creates the recovery,status and log files in the session folder
#Input		    :
#			        
#Output		    :	
#			        
#			        
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub auth_createSessionFile
{    
    my $filename;
    my $SESSIONFILELANDLE;
    my $STATUSFILEHANDLE;
    my $LOGFILEHANDLE ;
    $sessionFilename =AMW.$sessionName.FILE_RECOVERY;     # RecoveryFile appended with full path
    $sessionFilename = "./$sessionName/$sessionFilename ";
    $statusLogFile =AMW.$sessionName.FILE_STATUS;         # StatusFile appended with full path 
    $statusLogFile  = "./$sessionName/$statusLogFile ";	
    $errorLogFile =AMW.$sessionName.FILE_LOG;	          # LogFile appended with full path 
    $errorLogFile  = "./$sessionName/$errorLogFile ";	
	
	eval
	{
		$SESSIONFILELANDLE = new IO::File;
		if(open(SESSIONFILELANDLE,">$sessionFilename") or die 'ERR_FILE_OPEN')
        {
            close(SESSIONFILELANDLE);
            $STATUSFILEHANDLE = new IO::File;
            if(open(STATUSFILEHANDLE,">$statusLogFile") or die 'ERR_FILE_OPEN')                
            {
                close (STATUSFILEHANDLE);	
                $LOGFILEHANDLE= new IO::File;		
                if(open(LOGFILEHANDLE,">$errorLogFile") or die 'ERR_FILE_OPEN')                    
                {                    
                    close (LOGFILEHANDLE);
                }
            } # ErrorFile Creation#
        }
	};
	
	if($@)
	{
		if($@=~/ERR_FILE_OPEN/)
        {	
            # log error and exit tool
            $logFilereturn=ilog_print(1,ERR_FILE_OPEN.__LINE__);			  								  					
        }
		
        return FALSE;
	}
	else
	{
		ilog_setLogInformation("EXT_INFO",HTM_BEGIN,"","");    #commented for now
		$logFilereturn= ilog_setLogInformation('INT_INFO',AMW.$sessionName.FILE_RECOVERY,MSG_FILE_OPEN,'');
		$logFilereturn= ilog_setLogInformation('INT_INFO',AMW.$sessionName.FILE_STATUS,MSG_FILE_OPEN,'');
		$logFilereturn= ilog_setLogInformation('INT_INFO',AMW.$sessionName.FILE_LOG,MSG_FILE_OPEN,'');
		$logFilereturn= ilog_setLogInformation('INT_INFO','auth_createSessionFile()',MSG_METHOD_SUCCESSFUL,'');			
	}
    
    return TRUE;    
}

#---------------------------------------------------------------------------------
#Method Name	:	auth_displaySessionFile
#Description	: 	display the Recovery File contents to the user
#Input		    :	recovery filename
#			        
#Output		    :	
#			        
#			        
#Return Value   :	boolean
#---------------------------------------------------------------------------------
sub auth_displaySessionFile
{
    my $tempfilename  = shift;
    my $fileret;
    my $resumemigrate;    
    my $tempindex;
    $tempindex= 0;
    my $fileret;
    my $websitecount=0;
    my $retval;
    
    my $RECOVERYFILEHANDLE;
    $tempfilename=AMW.$sessionName.FILE_RECOVERY;     # RecoveryFile appended with full path
    $tempfilename = "./$sessionName/$tempfilename ";
    
    $RECOVERYFILEHANDLE = new IO::File;
    eval
    {
        $fileret = open ((RECOVERYFILEHANDLE,"<$tempfilename") ) or die 'ERR_FILE_OPEN';
    };
    
    if($@)
    {
        if($@=~/ERR_FILE_OPEN/)
        {
            # log error and exit tool
            $logFilereturn=ilog_print(1,ERR_FILE_OPEN.__LINE__);			  								  					
        }
        
        return FALSE;
    }
    else
    {	
        ilog_print(1,CON_RECOVERY_FILE_CONTENTS);
        ilog_print(1,"\n");
        my $siteSection = 0;
        while ($lineContent = <RECOVERYFILEHANDLE>) 
        {
            if ($siteSection)
            {
                ilog_print(1, $lineContent);
                next;
            }

            chomp($lineContent);
            $lineContent =~ s/^\s+//;
            $lineContent =~ s/\s+$//;
            if ($lineContent eq RECOVERY_MODE_0 ||  $lineContent eq RECOVERY_MODE_1 || $lineContent eq RECOVERY_MODE_2 || $lineContent eq RECOVERY_MODE_COMPLETE)
            {
                $fileparse[$tempindex]=$lineContent;
                $tempindex++;
            }

            if($lineContent=~ /$REC_HTTPD_PATH/)
            {
				$fileparse[$tempindex]=$lineContent;
				$tempindex++;
				@tempfileparse = split /\s+/,$lineContent;
				$lineContent= $tempfileparse[$#tempfileparse];
				chomp($lineContent);
				$logFilereturn=ilog_print(1,"$NEW_REC_HTTPD_PATH\t$lineContent\n");				
            }            
            
            if( ($lineContent=~/^\[/ ) )
            {                
                if( ($lineContent eq $LISTEN) || ($lineContent eq $IP_INFORMATION) || ($lineContent eq $REC_USER_DIR) || ( $lineContent eq $REC_MY_NAME_VIRTUAL_HOST))
                {                    
                    #do nothing                    
                }
                else
                {
                    $logFilereturn=ilog_print(1,CON_SITE_DETAILS);
                    ilog_print(1, "$lineContent\n");
                    $siteSection = 1;
                }
            }
        }
    }
	
    close RECOVERYFILEHANDLE;
    return  @fileparse;
}

#---------------------------------------------------------------------------------
#Method Name	:	auth_inputSessionName
#Description	: 	Returns the sessionname to the main program
#Input		    :	Nil
#			        
#Output		    :	SessionName
#			        
#
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub auth_inputSessionName()
{	
	my $count; #Count for maximum number of attempts is reset to 0	
	$count = 0;
	$tempretval = 0;	
	my $specialCharPattern = "[a-zA-Z0-9-_]"; # Allowed in directory creation
	while ($count < MAXTRIES )
    {
        ilog_print(1,CON_SESSION_NAME);
        chop($sessionName=<STDIN>);
        $sessionName =~ s/^\s+//;
        $sessionName =~ s/\s+$//;        
        $sessionName=ltrim($sessionName);        
        if (!($sessionName eq ''))
        {
            if($sessionName !~ /^$specialCharPattern+$/)
            {
                $logFilereturn=ilog_print(1,ERR_INPUT_CONFIRM);	
                $tempretval=0;				
            }
            else
            {                
                $tempretval=1;
                $count = MAXTRIES;				
            }
        }
        else
        {            
            $tempretval=0;
        }
        
        $count++;
    }
	
	if(!($tempretval))
    {        
        $logFilereturn=ilog_print(1,ERR_INPUT_OVER);
    }

	return ($tempretval,$sessionName);
}

#---------------------------------------------------------------------------------
#Method Name	:	auth_inputFilePath
#Description	: 	Returns the sessionname to the main program
#Input		    :	Nil
#			        
#Output		    :	SessionName
#			        
#			        
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub auth_inputFilePath
{
	my $count=0; #Count for maximum number of attempts is reset to 0
	$tempretval=0;
	while ($count < MAXTRIES )
    {
        ($tempretval,$filePath) = auth_inputParam(CON_HTTPD_PATH,DEFAULT_HTTPD_PATH,'VISIBLE','F','0');
        if($tempretval) 
        {
            $return = auth_getConfFile($filePath);
            
            if(!$return)
            {
                $tempretval=0;                
            }
            else
            {
                $logFilereturn= ilog_setLogInformation('REC_INFO',REC_HTTPD_PATH.REC_ADD_EQUAL,$filePath,'');
                $logFilereturn= ilog_setLogInformation('EXT_INFO',REC_HTTPD_PATH,$filePath,'');
                $count = MAXTRIES;
            }
        }
        
        $count++;
    }
	if(!($tempretval))
	{		
		$logFilereturn = ilog_displayandLog(ERR_INPUT_OVER,1,'INT_ERROR',MSG_MAXIMUM_COUNTS,MAXTRIES,__LINE__);
	}
	
    if($tempretval)        
    {
        $logFilereturn= ilog_setLogInformation('INT_INFO','auth_inputFilePath()',MSG_METHOD_SUCCESSFUL,'');
        # Log Success message to the log files 
        if(!($logFilereturn))
        {
            ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
        }
    }
    
    return ($tempretval,$filePath);	
}

#--------------------------------------------------------------------------------
#Method Name	:	auth_resumeMigrate()
#Description	: 	Returns the TRUE if user determines to resume migration process
#Input		    :	Nil
#			        
#Output		    :	SessionName
#			        
#			        
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub auth_resumeMigrate()
{	
    my $messageString=shift;
	my $resumemigrate;
	my $count=0;								#Count for maximum number of attempts is reset to 0
	$tempretval=0;
	my $exitVal;
	while ($count < MAXTRIES )
    {
        ilog_print(1,$messageString);
        chop($resumemigrate=<STDIN>);    # user input
        $resumemigrate =~ s/^\s+//;
        $resumemigrate =~ s/\s+$//;
        $resumemigrate=ltrim($resumemigrate);
        if ($resumemigrate eq 'y' || $resumemigrate eq 'Y')
        {
            $count = MAXTRIES;
            $tempretval=1;            
        }
        else 
        {
            if ($resumemigrate eq 'n' || $resumemigrate eq 'N')
            {
                $tempretval=0;
                $count = MAXTRIES;
                $exitVal =1
            }
        }

        $count++;
    }	
	if($exitVal)
	{
		$logFilereturn = ilog_print(1,TITLE_EXIT);
	}
	else
	{
		if (!($resumemigrate eq 'y' || $resumemigrate eq 'Y'))
        {
            $logFilereturn = ilog_displayandLog(ERR_INPUT_OVER,1,'INT_ERROR',MSG_MAXIMUM_COUNTS,MAXTRIES,__LINE__);
        }
	}

	return $tempretval;
}

#---------------------------------------------------------------------------------
#Method Name	:	auth_displaywebsitedetails
#Description	: 	display the details such as destination directory,site IP and SSL 
#                   enabled or not in a recovery file 
#Input		    :	website name
#			        
#Output		    :	
#
#			        
#Return Value   :	boolean
#---------------------------------------------------------------------------------	
sub auth_displaywebsitedetails
{
	my $websiteName=shift;
	my $tempfilename=shift;
	my $i;
	my $tempvar;
	my $ipportVar;    
	&ui_printline();	
	ilog_print(1,"$websiteName\n\n");
	for ($i=0; $i<5;$i++)
	{
		$lineContent = <RECOVERYFILEHANDLE>;
		if($lineContent =~/DestinationPath/)
        {
            ilog_print(1,"$lineContent\n");			
        }
		
		if($lineContent =~/SSL/i)
        {            
            @tempfileparse = split /=/,$lineContent;
            $lineContent= $tempfileparse[$#tempfileparse];
            chomp($lineContent);
            if($lineContent =~/y/i)
            {                
                ilog_print(1,ENABLE_SSL);                
            }            
        }        
	}

	return 1;	
}

#---------------------------------------------------------------------------------
#Method Name	:	auth_isRecovery()
#Description	: 	The function returns
#Input		    :	
#			        
#Output		    :	
#			        
#			        
#Return Value   :	boolean
#---------------------------------------------------------------------------------	
sub auth_isRecovery
{
	return $migrationStatus;
}
1;
