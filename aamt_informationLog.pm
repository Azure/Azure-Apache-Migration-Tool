#----------------------------------------------------------------------------------------------
#Script Name 	    :	aamt_informationLog.pm
#Description	    : 	Package is used to log data supplied by individual methods in 
#						the specified files.		
#-----------------------------------------------------------------------------------------------
# include external packages
use strict;
use aamt_constants;
use IO::File;
use aamt_utilityFunctions;

my $globSessionName;
my $iSpin = 1;
#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_setLogInformation
#Description	: 	Method determines the logCode and accordingly handles the file that needs to 
#Input			:	1. logType		-	EXT_ERROR,INT_ERROR,EXT_INFO,INT_INFO or REC_INFO
#					2. logCode		-	ERR_INTERNAL_ERROR
#					3. logDescription		-	Actual data that needs to be logged into the 
#												specified file
#					4. lineNumber	-	Line number of the method where the error is thrown
#Output			:	NA
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ilog_setLogInformation
{
	my @filenameList;
	my $Data;
	my $fileName;
	my $retOpenFile;
	my $retCloseFile;
	my $retFillData;
	my $retgetFileNames;
	my $retgetDataToPopulate;
	my $retChangeWorkingDirectory;
	my ($FILEHANDLE) = new IO::File;
	# Acquire the parameter values sent to the subroutine
	my ($logType,$logCode,$logDescription,$lineNumber) = @_;
	my $moduleName;
	# Get module name
	$moduleName = utf_getCurrentModuleName();
	if($logType eq 'REC_INFO')
	{
		# reset the moduleName,lineNumber to blank
		$moduleName = "";
		$lineNumber = "";
	}	
	#Get the file names corresponding to the logType
	($retgetFileNames,@filenameList) = &ilog_getFileNames($logType,$globSessionName,@filenameList);
	if ($retgetFileNames)
	{
        foreach $fileName(@filenameList)
		{			
			#Open the file for appending
            ($retOpenFile,$FILEHANDLE) = ilog_OpenFile($fileName,$globSessionName);
            if (!($retOpenFile)) { ilog_printf(ILOG_OPENFILE);return FALSE};

			#Obtain data to be populated 
            #############################################################
            # Do HTML Reporting for STATUS and LOG File
            #############################################################
            if ( ($fileName eq AMW.$globSessionName.FILE_STATUS) or ($fileName eq AMW.$globSessionName.FILE_LOG))
            {
                ($retgetDataToPopulate,$Data) = ilog_getHTML2Populate($fileName,$logCode,$logDescription,$moduleName,$lineNumber);
			    if (!($retgetDataToPopulate)) { ilog_printf(ILOG_GETDATA);return FALSE};
            }
            else
            {
			    ($retgetDataToPopulate,$Data) = ilog_getDataToPopulate($logCode,$logDescription,$moduleName,$lineNumber);
			    if (!($retgetDataToPopulate)) { ilog_printf(ILOG_GETDATA);return FALSE};
            }
            
			$retFillData = ilog_FillData($Data,$FILEHANDLE);
			if (!($retFillData)) { ilog_printf(ILOG_FILLDATA);return FALSE};

			#Close the file after inserting data
            $retCloseFile = ilog_CloseFile($FILEHANDLE);
			if (!($retCloseFile)){  ilog_printf(ILOG_CLOSEFILE);return FALSE};
		}
		return TRUE;
	}
	else
	{
		ilog_printf(ILOG_SETLOGINFO);	
		return FALSE;
	}
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_getFileNames
#Description	: 	Method gets the name of the files to be populated with data
#Input			:	
#Output			:	
#Return Value   :	filenameList Array	
#-----------------------------------------------------------------------------------------------
sub ilog_getFileNames
{
	my @filenameList;
	my $getCompleteFilenameret;
	my ($logType,$globSessionName,@filenameList) = @_;
	# Check for log type and obtain the file names
	if ($logType eq 'EXT_ERROR')
	{	
		@filenameList = (FILE_STATUS,FILE_LOG);
	}
	elsif ($logType eq 'INT_ERROR')
	{	
		@filenameList = (FILE_LOG);	
	}
	elsif ($logType eq 'EXT_INFO')
	{	
		@filenameList = (FILE_STATUS,FILE_LOG);	
	}
	elsif ($logType eq 'INT_INFO')
	{
		@filenameList = (FILE_LOG);	
	}
	elsif ($logType eq 'REC_INFO')
	{	
		@filenameList = (FILE_RECOVERY);
	}	
	elsif ($logType eq 'TASKLIST_INFO')
	{
		@filenameList = (FILE_TASKLIST);
	}
	elsif ($logType eq 'TEMPTASKLIST_INFO')
	{
		@filenameList = (FILE_TASKLIST_TEMP);
	}
	else
	{
		return (FALSE,@filenameList);
		
	}

	# Append the file name with the session variable
	($getCompleteFilenameret,@filenameList) = ilog_getCompleteFilename($globSessionName,@filenameList);
	if (! $getCompleteFilenameret)
	{
		return (FALSE,@filenameList);
	}

	return (TRUE,@filenameList)
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_getCompleteFilename
#Description	: 	Method gets the complete filename concatenated with the AMW and the sessionName
#Input			:
#Output			:	
#Return Value   :	filenameList Array	
#-----------------------------------------------------------------------------------------------
sub ilog_getCompleteFilename
{
	my ($globSessionName,@filenameList) = @_;
	my $fileName;
	foreach $fileName(@filenameList)
	{
		$fileName = AMW.$globSessionName.$fileName;
	}

	return (TRUE,@filenameList);
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_OpenFile
#Description	:    Method opens the file for appending data
#Input			:	   fileName
#				  	
#Output			:	
#Return Value   :	FILEHANDLE	
#-----------------------------------------------------------------------------------------------
sub ilog_OpenFile
{
	my ($fileName,$globSessionName,$fileMode) = @_;
	my ($FILEHANDLE) = new IO::File;
	my $pwd;
	my $filePath;

	# Returns the program folder, where the tool is installed
    $pwd = utf_getCurrentWorkingFolder();
	# form the complete path
    $filePath = "$pwd/$globSessionName/$fileName";
	my $ret = open FILEHANDLE,">>$filePath" or die "$!";
	if ($ret == 0)
	{
		return (0,$FILEHANDLE);
	}
	else
	{
		return (1,$FILEHANDLE);
	}
}

sub ilog_OpenFileWithMode
{
	my ($fileName,$fileMode) = @_;
	my $OpenModeName;
	my ($FILEHANDLE) = new IO::File;
	my $pwd;
	my $filePath;
	#Returns the program folder, where the tool is installed
    $pwd = utf_getCurrentWorkingFolder();
	#form the complete path
    $filePath = "$fileName";
    #set the mode based on the input argument
    if ( $fileMode eq 'r' )
    {
        $OpenModeName = "<$filePath";
    }
    elsif ( $fileMode eq "w" )
    {
        $OpenModeName = ">$filePath";
    }
    elsif ( ($fileMode eq "r+") || ($fileMode eq "w+") )
    {
        $OpenModeName = "+> $filePath";
    }
    elsif ( ($fileMode eq "a") || ($fileMode eq "") )				#to have backward compatability in the function
    {
        $OpenModeName = ">>$filePath";
    }
	my $ret = open FILEHANDLE,$OpenModeName or die "file could not be opened";
	
	if ($ret == 0)
	{
		return (0,$FILEHANDLE);
	}
	else
	{
		return (1,$FILEHANDLE);
	}	
}


#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_getDataToPopulate
#Description	: 	Method collects the data to be populated into the files
#Input			:	
#Output			:	
#Return Value   :	Scalar Data 
#-----------------------------------------------------------------------------------------------
sub ilog_getDataToPopulate
{
	my $Data;
	my ($logCode,$logDescription,$moduleName,$lineNumber)  = @_;
	
    if ($logCode eq "htm_begin") {return (1,"");}

    if ($logCode eq "htm_end"  ) {return (1,"");} 
    
	$Data  = "$logCode\t" if $logCode;
    if ($moduleName eq "")
    {
        $Data = sprintf("%-20s%-20s",$logCode,$logDescription)
    }
    else
    {
        $Data = sprintf("%-10s%-20s%-20s%-20s",$lineNumber,$moduleName,$logCode,$logDescription);
    }

    return (1,$Data);
}


#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_getHTML2Populate
#Description	: 	Method collects the data to be populated into the files
#Input			:	
#Output			:	
#Return Value   :	Scalar Data 
#-----------------------------------------------------------------------------------------------
sub ilog_getHTML2Populate
{
	my $Data;
	my ($fileName,$logCode,$logDescription,$moduleName,$lineNumber)  = @_;
    # Format Status File...
    if ($fileName eq AMW.$globSessionName.FILE_STATUS)
    {
        return (1,HTM_STATUS_BEGIN) if ($logCode eq "htm_begin");
        return (1,HTM_STATUS_END  ) if ($logCode eq "htm_end"  ); 
        
        if ($logCode =~ /^<.*>$/)
        {
            $logCode =~ s /<(.*)>/$1/gi;
            $Data = HTM_TABLE_END."<H2>$logCode</H2>".HTM_STATUS_TABLE;
        }
        else
        {
            $Data = "<TR><TD>$logCode &nbsp;</TD><TD>$logDescription &nbsp;</TD></TR>\n";
        }
    }
    
    # Format Log File...
    if ($fileName eq AMW.$globSessionName.FILE_LOG)
    {
        return (1,HTM_LOG_BEGIN) if ($logCode eq "htm_begin");
        return (1,HTM_LOG_END  ) if ($logCode eq "htm_end"  ); 
        
        $Data = "<TR><TD>$lineNumber &nbsp;</TD><TD>$moduleName &nbsp;</TD><TD>$logCode &nbsp;</TD><TD>$logDescription &nbsp;</TD></TR>\n";
    }

    return (1,$Data);
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_FillData
#Description	: 	Method fills up the data into the files
#Input	
#Output		:	
#Return Value   :	boolean	
#----------------------------------------------------------	-------------------------------------
sub ilog_FillData
{
	my ($Data,$FILEHANDLE)= @_;
	print FILEHANDLE "$Data\n" or return 0;
	return 1;
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_CloseFile
#Description	: 	Method closes the file handle after data is populated
#Input	
#Output		:	
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ilog_CloseFile
{
	my ($FILEHANDLE) = @_;
	close FILEHANDLE;
	return 1;
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_print
#Description	: 	Method to write data to the console
#Input			:	1.	Flag (reserved)
#					2.	String to be displayed on the console
#Output			:	
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ilog_print
{
	my ($displayFlag,@displayData,) = @_;
    my $dataLen = 0;
    my $nCount = 0;
    my @arrPrint = ("|","/","-","\\");
    
    my $tmp = "                                                                              ";

    return TRUE if ($displayFlag == DEBUG_ONLY); 
    $| = 1;
    if ($displayFlag == OVERWRITE)
    {
        $displayData[0] .= $tmp;
        $displayData[0] = "\r".substr($displayData[0],0, 75);
        
        $iSpin++;
        $displayData[0] .= " ".$arrPrint[$iSpin % 4];        
        print @displayData;
    }
    else
    {
        print @displayData;
    }

	$| = 0;
    return TRUE;
}

#-----------------------------------------------------------------------------------------------
# Method Name	:	ilog_printf
#
# Description	: 	Method to write parameterized data to the console.
#                   Paramters are denoted by a number enclosed by two % symbols
#
# Input			:	1.	String to be displayed on the console
#                   2.  Set of parameters for the formating if any
# Output		:	
#
# Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ilog_printf
{
    my $val;
    my @tmp = split /%/,$_[0];
    foreach $val (@tmp)
    {
        if ($val =~ /^\d+$/) { print $_[$val];}
        else { print $val;}                      
    }
    return TRUE;
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_setSessionName
#Description	: 	To set the Session Name
#Input			:	Session name
#Output			:	
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ilog_setSessionName
{
	my($sessionName) = @_;
	$globSessionName = $sessionName;

}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_getSessionName
#Description	: 	To get the Session Name
#Input			:	Na
#Output			:	
#Return Value   :	Session Name
#-----------------------------------------------------------------------------------------------
sub ilog_getSessionName
{
    return $globSessionName;
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ilog_displayAndLog
#Description	: 	Method to display data on the console as well log information
#					in the respoective files
#Input			:	1.	String to be displayed on the console
#					2.	Flag (reserved)
#				:	3. logType		-	EXT_ERROR,INT_ERROR,EXT_INFO,INT_INFO or REC_INFO
#					4. logCode		-	ERR_INTERNAL_ERROR
#					5. logDescription		-	Actual data that needs to be logged into the 
#												specified file
#					6. lineNumber	-	Line number of the method where the error is thrown
#Output			:	
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ilog_displayandLog
{
	#Acquire the parameter values sent to the subroutine
	my ($displayData,$displayFlag,$logType,$logCode,$logDescription,$lineNumber) = @_;
    if ($logCode eq "")		
    { 
        $logDescription = $displayData ;
    }

	if(!ilog_print($displayFlag,$displayData))
    {return FALSE;}

	# call the set log information to have the data written into the log file
	if(!ilog_setLogInformation($logType,$logCode,$logDescription,$lineNumber))
    {return FALSE;}

	return TRUE;				
}

sub ilog_EndLine
{
    my $strLine = join("",@_);  #   Join Strings...   
    $strLine =~ s/^\n//;        #   Remove \n at start
    $strLine =~ s/\n$//;        #   Remove \n at end
    return "\n".$strLine;
}
1;
