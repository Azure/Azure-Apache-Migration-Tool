#----------------------------------------------------------------------------------------------
#Script Name 	    :	aamt_utilityfunctions.pm
#Description	    : 	General utility functions.		
#use of standard packages
use Cwd;

#use of custom packages
use aamt_constants;
use LWP::Simple;
use FileHandle;

#global variables declaration
my $glob_workingFolder;				#stores the present working folder information
my $glob_moduleName;				#stores the present running module name
my $glob_CurrentMachineType = 'T';	#indicates the current type of machine, i.e whether it is Source, Target or Intermediate
my @Unlinkables;                    # List of path of files marked for deletion..

#---------------------------------------------------------------------------------
#Method Name	:	utf_validateInput
#Description	: 	Validates the supplied input value for a particular type
#Input		    :	1. Input to be validated
#                   2. Type of validation to be performed, i.e Integer, String, or 
#					   MachineAddress 
#			        
#Output		    :	
#			        
#			        
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub utf_validateInput
{
	#variables declaration	
    my ($input , $inputFlag )	= @_;
    my $retvalidateInput		= "1";			#true by default
    my $specialCharCheckFlag	= 1;
    my $specialCharPattern;
    
	#generic special char pattern check
    #for file paths, the / has been not included in the list as that is allowed in the file path
    #if Validation type is F then special char pattern needs to be without a / 
    if ($inputFlag eq 'F')
    {
        $specialCharPattern  = "[\]\[{};:,<>?!\@#\$*%\^()+=_\-]";		#   /  $  @ - [  ]  have been escaped
    }
    else
    {
        $specialCharPattern = "[\]\[{}\/;:,<>?!\@#\$*%\^()+=_\-]";		#   /  $  @ - [  ]  have been escaped
    }

    my $checkPattern ;		#pattern against which the input needs to be checked for...    
    if ($inputFlag eq "I")
    {
        $checkPattern = '/[\d]/';
    }
    else
    {
        if ($inputFlag eq "S")
        {
            $checkPattern = "/[A-Z]/i";
        }
        else
        {
            if ($inputFlag eq "M" )
            {
                $checkPattern = /[0-9A-Z.]/;
            }
        }
    }	
    
    my $patternCheckFlag = ($input =~ /$checkPattern/);
    $patternCheckFlag = 1;
    if ($patternCheckFlag)			#if the input matches the valid pattern,
    {
        if ($specialCharCheckFlag == 1)		#if required to check for Special characters...
        {
            if ($input =~ /$specialCharPattern/)	#the additional check of the input not having any special characters...
            {
                $retvalidateInput = "0"; #Special char PATTERN MATCHED
            }	
        }
    }
    else
    {
        print "\n :$input: doesnt follow the pattern for $inputFlag type check\n";
    }
    
    return $retvalidateInput;
}

#---------------------------------------------------------------------------------
#Method Name	:	utf_getWebServer
#Description	: 	Retrieves the WebServer header information running on a machine
#					This header information contains the web server info and optionally the OS version
#Input		    :	1. MachineIP		        
#Output		    :	1. WebServer string
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub utf_getWebServer
{
	#input arguments
    my ($server) = shift;
	#variables declaration
    my $web_server;
    my $type;
    my $len;
    my $mod_time;
    my $exp_time;   
    #required for debugging the info
    #use LWP::Debug qw(+ -conns);
	eval
	{ 
		($type, $len, $mod_time, $exp_time, $web_server) = LWP::Simple::head( "http://${server}" ) or die 'ERR_SERVER_NOT_FOUND' ;
	};
	if($@)
	{		
		if($@ = ~/ERR_SERVER_NOT_FOUND/)
		{
			$logFilereturn= ilog_displayandLog(ERR_SERVER_NOT_FOUND,1,'INT_ERROR','utf_getWebServer()',ERR_SERVER_HTTP_NOTFOUND,__LINE__);	
			
			if(!($logFilereturn))
			{
				ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
				exit(0); #return FALSE
			}
		}
		return FALSE;
	}	
	else
	{
		return($web_server);
	}
}

#---------------------------------------------------------------------------------
#Method Name	:	ltrim
#Description	: 	Trims the white spaces occuring on the left side of the string
#Input		    :	string
#Output		    :	
#Return Value   :	string
#----------------------------------------------------------------------------------
sub ltrim	# note the name was not changed to preserve ease of use... 
{
    my $strIn = shift;
    $strIn =~ s/^[\s\t\n]+//;
    return $strIn;
}

#-------------------------------------------------------------------------
# Method Name        :        utf_isValidIP
#
# Description        :        Does cosmetic validation only to check if the
#	                          IP is in the right format.
# Input              :        1. IP or IP:port
# Output             :        1.  none
# Return Value       :        boolean - 0 indicates invalid IP.
#-------------------------------------------------------------------------
sub utf_isValidIP
{
	#variables declaration
    my @arrIPparts;
    my $AllZeros = 1;
    
    return 1 if ($_[0] eq "*");             # Allow * for any IP... 
    
    my @arrTemp = split /:/,$_[0];          # Check if port is specified.

    return 0 if (scalar(@arrTemp) > 2);         # There can be only one port.

    if ($arrTemp[0] !~/^\d+\.\d+\.\d+\.\d+$/)  # Check if its n.n.n.n
    {
        return 0 if ($arrTemp[0] ne "*");
    }
    else
    {        
        @arrIPparts = split /\./,$arrTemp[0];        
        foreach(@arrIPparts) {return 0 if ($_ > 255);$AllZeros = 0 if ($_ > 0); }  #check if each n <255        
        return 0 if ($AllZeros);
    }
    
    if (scalar(@arrTemp) > 1)                       #check port is right
    {
        return 0 if ($arrTemp[1] !~/^\d+$/);
        return 0 if ($arrTemp[1] > 65535);
        return 0 if ($arrTemp[1] == 0);        
    }
    return 1;
}

#-------------------------------------------------------------------------
# Method Name        :      utf_isValidPort
#
# Description        :      Does cosmetic validation only to check if the
#                           Port is Valid.
# Input              :      1. port number
#                           2.
# Output             :      1.  none
#                           2.
#                           3.
# Return Value       :      boolean - 0 indicates invalid IP.
#-------------------------------------------------------------------------
sub utf_isValidPort
{
    my $port = shift;
    
    return 0 if ($port !~/^\d+$/);
    return 0 if ($port > 65535);
    return 0 if ($port == 0);

    return 1;
}


#-------------------------------------------------------------------------
# Method Name        :      utf_escapeMetacharacter
#
# Description        :      Escapes metacharacters in a string,ie.,adds a \ prior 
#							to the character
# Input              :      1. string 
#     
# Output             :      1. string with characters escaped
#     
# Return Value       :      none
#-------------------------------------------------------------------------
sub utf_escapeMetacharacter
{
	#input arguments
    my $inputString = shift;

	# include list of metacharacters to be escaped
    my $metacharacters = '@^$%&~`/?.';    

	# substitutes @.. with  \@
    $inputString =~ s/([$metacharacters])/\\$1/g;	

	return ($inputString);
}

#-------------------------------------------------------------------------
#Method Name        :        utf_setCurrentWorkingFolder
#Description        :        Sets the current working folder						 
#Input              :        NA
#Output             :        NA
#-------------------------------------------------------------------------
sub utf_setCurrentWorkingFolder
{
	$glob_workingFolder = cwd;
}

#-------------------------------------------------------------------------
#Method Name        :        utf_getCurrentWorkingFolder
#Description        :        gets the current working folder						 
#Input              :        NA
#Output             :        NA
#Return				:		 returns the current working folder
#-------------------------------------------------------------------------
sub utf_getCurrentWorkingFolder
{
    #local variables declaration
    my $OSType;
    $OSType = $^O; # get the current operating system type
    if($OSType eq 'WINDOWS')
    {
        $glob_workingFolder =~ tr/\//\\/; #change the current directory to windows style
    }

    return $glob_workingFolder;
}

#-------------------------------------------------------------------------
#Method Name        :        utf_getWorkingFolder
#Description        :        gets the full path of the working folder						 
#Input              :        NA
#Output             :        NA
#Return             :        returns the current working folder
#-------------------------------------------------------------------------
sub utf_getWorkingFolder
{
    # get the current working folder
    my $strCurWorkingFolder = &utf_getCurrentWorkingFolder();
    #get session name
    my $strSessionName = &ilog_getSessionName();
    #form the complete working folder
    my $workingFolder = $strCurWorkingFolder . '/' . $strSessionName;
    
    return $workingFolder;
}


#-------------------------------------------------------------------------
#Method Name        :        utf_setCurrentModuleName
#Description        :        Sets the current module name						 
#Input              :        Module name
#Output             :        NA

#-------------------------------------------------------------------------
sub utf_setCurrentModuleName
{
	$glob_moduleName = shift;
}

#-------------------------------------------------------------------------
#Method Name        :        utf_getCurrentModuleName
#Description        :        gets the current module name						 
#Input              :        NA
#Output             :        NA
#Return				:		 returns the current working folder
#-------------------------------------------------------------------------
sub utf_getCurrentModuleName
{
	return $glob_moduleName;
}

#-------------------------------------------------------------------------
#Method Name        :        utf_setCurrentMachine
#Description        :        sets the current machine type to either Source(S), Target(T) or Intermediate(I)
#Input              :        Current Machine Type, i.e either S, T or I
#Output             :        NA
#Return				:		 NA
#-------------------------------------------------------------------------
sub utf_setCurrentMachine
{
	$glob_CurrentMachineType = shift;	
}

#-------------------------------------------------------------------------
#Method Name        :        utf_getCompleteFilePath
#Description        :        gets the absolute path of the input file.
#Input              :        File name of the file which path is needed.
#Output             :        NA
#Return				:		 returns the absolute path of the input file
#-------------------------------------------------------------------------
sub utf_getCompleteFilePath
{	
	return "./". &ilog_getSessionName() . "/". AMW. &ilog_getSessionName(). shift;
}

#-------------------------------------------------------------------------
#
# Method Name	: utf_FileOpen
# Description	: The method is used to open a file in the mode specified
# Input			: Filename	:	 Complete path of file to be opened
#				  FileMode	:	 Read / Write mode
#				  Path type	:	 Absolute / Relative to session folder
#								 PATH_ABS, PATH_REL
#								If the path type is PATH_REL, the file is assumed to be in the session folder
#								If the path type is PATH_ABS, the file name is taken as the absolute one
# OutPut		: FileHandle:	 Handle of the file opened
# Status		: Success/failure depending on the status of the function call.
#-------------------------------------------------------------------------
sub utf_FileOpen
{
	#input arguments
    my $FileName				=		shift;	#Name of file to be opened with the complete path
    my $FileMode				=		shift;	#Mode in which file to be opened
    my $PathType				=		shift;	#type of path

	#local variables declaration
    my $OpenModeName;							
    my $ret = 1;
    my $fhandle = new FileHandle;
    my $logFileReturn;

	eval
	{
		if ($PathType == PATH_REL)
		{
			$FileName = &utf_getCompleteFilePath($FileName);
		}

		if ($FileMode == FILE_READ)
		{
			$OpenModeName = "<$FileName";
		}
		elsif ($FileMode == FILE_WRITE)
		{
			$OpenModeName = ">$FileName";
		}
		elsif (($FileMode == FILE_READ_EX) || ($FileMode == FILE_WRITE_EX))
		{
			$OpenModeName = "+>$FileName";
		}
		elsif (($FileMode == FILE_APPEND))
		{
			$OpenModeName = ">>$FileName";
		}
		
		#command to open file
        open $fhandle, $OpenModeName or die "AAMT_ERR_FILEOPEN_FAILED";
	};

	if($@) 
	{ 
		if ($@ =~ /AAMT_ERR_FILEOPEN_FAILED/ )
		{
			$fhandle = AAMT_ERR_FILEOPEN_FAILED;
			$ret = 0;

			$logFileReturn= ilog_displayandLog( AAMT_ERR_FILEOPEN_FAILED,DEBUG_ONLY,'INT_ERROR',AAMT_ERR_FILEOPEN_FAILED,"$FileName", __LINE__);
		}
	} 
    
	return ($ret,$fhandle);
}

#---------------------------------------------------------------------------------
#Method Name:	 utf_FileWrite
#Purpose	:	 To write data to a new file. It opens the specified file, 
#				 writes the data to it  and then close the file.
#Inputs		  	
#				1.  FileName
#				2.  Content to be written
#				3.	Path type, whether PATH_ABS or PATH_REL
#Outputs
#				1. Boolean
#---------------------------------------------------------------------------------
sub utf_FileWrite
{    
    #local variables declaration
    my $fhandle;
    my $FuncReturn;
    my $logFileReturn;

    #arguments
    my $FileName = shift;	#name of the file
    my $Content = shift;	#content to be written
    my $PathType = shift;	#Path type, absolute or relative

    #open the file in write mode
    ($FuncReturn, $fhandle) = &utf_FileOpen($FileName, FILE_WRITE_EX,$PathType);
    if (!$FuncReturn) 
    { 
        
        $logFileReturn = ilog_displayandLog( $fhandle,1, 'EXT_INFO', '',$fhandle, __LINE__);
        
        if(!($logFileReturn))
        {
            $logFileReturn=ilog_print(ERR_INTERNAL_ERROR_CONSOLE.__LINE__,1);
        }
        return 0;
    }

    #write the content in the file 
    print $fhandle $Content;													

    #close the handle
    close($fhandle);

    return 1;
}

#--------------------------------------------------------------------------------
#Method Name	:	utf_gettimeinfo()
#Description	: 	utility function to get current datetime info
#Input		    :	Nil
#			        
#Output		    :	SessionName
#			        
#			        
#Return Value   :	1. TRUE / FALSE
#---------------------------------------------------------------------------------
sub utf_gettimeinfo()
{
	my $timemode=shift;
	my $sessionTime;
	my $day;
	my $month;
	my $year;
	my $sec;
	my $min;
	my $hour;
	my $tm=localtime;
	my $tempstring ='/';
	my $temptimestring=':';	
	($hour,$min,$sec,$day,$month,$year)=($tm->hour,$tm->min,$tm->sec,$tm->mday,$tm->mon,$tm->year);
	my $sessionDate=($day).$tempstring.($month+1).$tempstring.($year+1900);
	$sessionTime=($hour).$temptimestring.($min).$temptimestring.($sec);
	$sessionTime=$sessionDate.' at '.$sessionTime;
	
	if($timemode eq 0)
    {
        $logFilereturn = ilog_setLogInformation('EXT_INFO', MSG_SESSION_START_TIME ,$sessionTime,'');
        if(!($logFilereturn))
        {
            $logFilereturn=ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
            exit(0);
        }
    }
	else
    {
        $logFilereturn = ilog_setLogInformation('EXT_INFO', MSG_SESSION_END_TIME ,$sessionTime,'');
        if(!($logFilereturn))
        {
            $logFilereturn=ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
            exit(0);
        }		
    }	
	
	return 1;
}

sub utf_DeleteOnExit
{
    push @Unlinkables, shift;   # Marks the given file for deletion
}

sub utf_DisposeFiles
{
    unlink @Unlinkables;        # Delete all files marked for deletion
}
1;
