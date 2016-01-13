#-------------------------------------------------------------------------
# Script Name 	    :	aamt_parse.pm
#
# Description	    : 	Pre-Parses the apache config files and accepts the
#                       user inputs requiered for the migration.   
#                       Also generates Recovery Info.
#-------------------------------------------------------------------------
use strict;
use aamt_constants;
use aamt_informationLog;
use aamt_utilityFunctions;
#-------------------------------------------------------------------------
#        Global variables used by this module
my $strSessionFolder;   # Path at which all files pertaining to the current
# session is stored.
my @arrParseFiles;      # List of files to be parsed by this parser
my @arrSelectedSites;   # List of sites to be migrated selected by user
my %IP_mapping;         # Hash containing the mapping between old ip
# and new ip addresses
my %IP2SiteMapping;		# Hash containing the mapping between ip and
# site names
my $strDirectiveName;	# The current directive being processed
my $strDirectiveValue;	# The value for the current directive
my $isVirtualHost;      # Set to true if the context is a virtual host
my $enableSSL;          # Set to true if site is SSL Enabled
my $DefaultSSL;         # True if default site has SSL Enabled
my $directoryIndex;     # List of default web pages for a site/server
my $strDefaultName;     # Name of Default site
my $nSitesSelected;     # Count of Sites Selected for Migration...
my $strUserDir;         # Location of ~user site files...
# List of directive tags to be skipped ...
my %SkippedDirectives = ("IfDefine","1","Location","1","LocationMatch","1","Limit","1","LimitExcept","1");
my $strSessionName;
my $DEBUG_MODE = 0;

#-------------------------------------------------------------------------
# Method Name       :        pars_FirstPass
#
# Description       :        This method pre-parses the Apache config files 
#							 to retrieve configurable settings...
#
# Input             :        1. path of httpd.conf
#                            
# Output            :        None
#                            
# Return Value      :        boolean
#-------------------------------------------------------------------------
sub pars_FirstPass
{
    my $i = 0;
    my $strSiteRoot;               #   Document root of the current site
    my $strSiteIP;                 #   IP of the current site
    my $strSiteName;               #   Name of the Current site
    my @NameVirtualHostIPs;        #   IPs catering Named virtual host
    my @NameVirtualHosts;          #   List of Named Virtual hosts
    my $strHostHeader;             #   Host header Name for the current site
    my $strDefaultRoot;            #   Document root of the default site  
    my $strDefaultIP;              #   Value for BindAddress 
    my $strPort;                   #   Value for Port Directive
    my @arrListen;                 #   List of Values for Listen Directive
    my $strServerRoot;             #   Apache Server root folder
    
    # default files to be processed
    my $ResourceConfFile; 
    my $AccessConfFile;
    my $bHttpdFile = 1;            #   Set to true if httpd.conf is processed. 
    my $strHttpdPath;              #   Path of the config file being processed.
    my $logFileReturn;                
    my $strIgnoreUntil;            #   Directive Name to be ignored...   
    my $strRecoveryInfo;		    # Info to be written on recovery file...
    my $TempIP;        
    $nSitesSelected = 0;           
    $strUserDir = "public_html";
    
    utf_setCurrentModuleName(MOD_PARS1);    # Set module Name for status logging...
    ui_printBanner();
    
    #**************************************************************	
    # Parse every file avilable in the parse file list.
    # If the entry in the list is a directory then all files
    # in the directory will be processed.
    # We start with the root apache config, and then add more 
    # files in arrParseFiles as they are discovered
    #**************************************************************
    push(@arrParseFiles,shift);
    foreach $strHttpdPath (@arrParseFiles)
    {
        if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Apache config file [strHttpdPath]: $strHttpdPath\n"); }
        pars_OpenConfigFile($strHttpdPath);
        # use best guess for server root initially
        $strServerRoot = "/etc/apache2";

        while (&pars_GetNextDirective()==1)
        {
            #**************************************************************	
            # Skip everything inside non-migratable directive tags
            #**************************************************************	
            if (exists $SkippedDirectives{$strDirectiveName})
            {
                $strIgnoreUntil =  "/".$strDirectiveName;
                while (&pars_GetNextDirective() == 1)
                {
                    last if($strDirectiveName eq $strIgnoreUntil);	                
                }
            }
            #**************************************************************	
            # Process Migratable Directive that require user inputs
            #**************************************************************	
            
            $ResourceConfFile = pars_AbsPath($strServerRoot,ltrim($strDirectiveValue))
                if (lc($strDirectiveName) eq "resourceconfig");
            
            $AccessConfFile = pars_AbsPath($strServerRoot,ltrim($strDirectiveValue))
                if (lc($strDirectiveName) eq "accessconfig");
            
            # Add include File to parse file list
            if ((lc($strDirectiveName) eq "include") or (lc($strDirectiveName) eq "includeoptional"))
            {
                my $localPath = pars_AbsPath($strServerRoot,ltrim($strDirectiveValue));
                for my $op (glob $localPath)
                {
                    push(@arrParseFiles,$op);                    
                }
            }

            push(@NameVirtualHostIPs,ltrim($strDirectiveValue))
                if (lc($strDirectiveName) eq "namevirtualhost");
            
            if (lc($strDirectiveName) eq "virtualhost")
            {
                $enableSSL = 0;
                $isVirtualHost = 1;
                $strSiteIP = ltrim($strDirectiveValue);
            }
            
            if (lc($strDirectiveName) eq "servername")
            {
                $strSiteName = ltrim($strDirectiveValue)
			        if ($isVirtualHost);
                
                $strDefaultName = ltrim($strDirectiveValue) 
			        if (!$isVirtualHost);

                if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Site name to be processed [strSiteName] : $strSiteName\n"); }
                $strHostHeader = $strHostHeader ? $strSiteName." ".$strHostHeader  : $strSiteName ;
            }
            
            if (lc($strDirectiveName) eq "serveralias")
            {
                $strHostHeader .= $strHostHeader? " ". ltrim($strDirectiveValue) :ltrim($strDirectiveValue) 
			        if ($isVirtualHost);             
            }
            if (lc($strDirectiveName) eq "documentroot")
            {
                $strSiteRoot    = pars_unQuote(ltrim($strDirectiveValue))
                    if ($isVirtualHost);
                
                $strDefaultRoot = pars_unQuote(ltrim($strDirectiveValue)) 
                    if (!$isVirtualHost);                
            }
            
            $directoryIndex  = ltrim($strDirectiveValue) 
                if (lc($strDirectiveName) eq "directoryindex");
            
            if (lc($strDirectiveName) eq "sslengine")
            {
                $enableSSL = ($strDirectiveValue =~ /on/i) ? 1 : 0;                 
                $DefaultSSL = $enableSSL if (!$isVirtualHost);
            }
            if (lc($strDirectiveName) eq "/virtualhost")
            {
                $isVirtualHost =0;
                ### adriang: pars_SelectSites($strSiteName,$strSiteIP,$strSiteRoot);
                pars_AddSelectSites($strSiteName,$strSiteIP,$strSiteRoot);
                foreach $TempIP (@NameVirtualHostIPs)
                {
                    push(@NameVirtualHosts,$strHostHeader)
                        if ((ltrim($TempIP) eq "*") || ($strSiteIP eq ltrim($TempIP)) || (index($strSiteIP,ltrim($TempIP)) >= 0) );                    
                }
                
                # reset values..
                $strSiteRoot = ""; 
                $strSiteIP = "";   
                $strSiteName = "";
                $strHostHeader = ""; 
                $enableSSL = 0;
            }                       
            
            $strDefaultIP = ltrim($strDirectiveValue) 
                if (lc($strDirectiveName) eq "bindaddress");
            
            push(@arrListen,ltrim($strDirectiveValue))
                if (lc($strDirectiveName) eq "listen");
            
            $strPort = ltrim($strDirectiveValue) 
                if (lc($strDirectiveName) eq "port");
            $strServerRoot = pars_unQuote(ltrim($strDirectiveValue)) 
                if (lc($strDirectiveName) eq "serverroot");            
        }
        
        #*********************************************************
        # Add Resource config and access config files to parse
        # files list only if httpd.conf is being parsed.
        #*********************************************************
        # ADRIANG: this is where we discover apache2 config files
        # if ($bHttpdFile)
        # {
        #     push(@arrParseFiles,($strServerRoot."/sites-enabled/"));
        # }
        
        $bHttpdFile =0;         # done with httpd.conf
        close(hfileHTTPD);
    }
    
    #*********************************************************
    # Prompt for Default site transfer details
    #*********************************************************    
    ### adriang: pars_SelectSites(DEFAULT_WEB_SITE,"",$strDefaultRoot);
    &pars_AddSelectSites(DEFAULT_WEB_SITE,"",$strDefaultRoot);
    
    #*********************************************************
    # Exit is no site was selected for Migration...
    #*********************************************************
    if ($nSitesSelected == 0)
    {
        $logFileReturn = ilog_displayandLog(ERR_NOTHING2MIGRATE,"",'EXT_ERROR',ERR_NOTHING2MIGRATE,'', __LINE__);
        if(!($logFileReturn))
        {	
	        $logFileReturn=ilog_print(ERR_INTERNAL_ERROR_CONSOLE.__LINE__,1);
        }
        exit;
    }
    # else
    # {
    #     ilog_printf(MSG_SITES_SELECTED,$nSitesSelected);
    # }
    
    #*********************************************************
    # If Listen is not present and Bind Address is given
    # use Bindaddress and Port.
    #*********************************************************
    if ($#arrListen < 0)
    {
        if ($strDefaultIP)
        {
            push(@arrListen,$strDefaultIP);
        }
        push(@arrListen,$strPort) if ($strPort);        
    }
    
    utf_FileWrite(DEFAULT_SITE_FILE,$strDefaultName,PATH_REL);
    utf_DeleteOnExit(AMW . &ilog_getSessionName() . DEFAULT_SITE_FILE);
}

#-------------------------------------------------------------------------
# Method Name       :        pars_SelectSites
# Description       :        The method gets the lists of sites to be 
#                            migrated from the user
# Input             :        Sitename, IP List and Doc root
#
# Output            :        @selected_sites is populated
#
#
# Return Value      :        boolean
#-------------------------------------------------------------------------
sub pars_AddSelectSites
{
    my $strYesOrNo = "";
    my ($strSiteName,$strSiteIP,$strSiteRoot) = @_;
    my $strNewRoot = "";
    my $strIP ="";
    my $strRecoveryInfo;		# Info to be written on recovery file.
    my $promptyn;
    
    #***********************************************************
    # If Site-Name is blank, change it to a appropriate name...
    #***********************************************************
    if (!$strSiteName)
    {
        $strSiteName = DEFAULT_SITE_ON.$strSiteIP;
    }
    # ilog_print(1,"\n\n");
    # ui_printline();
    # ilog_printf(MSG_SITE_DETAILS,$strSiteName);
    # if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Site root to be processed [strSiteRoot] : $strSiteRoot\n"); }
    # ui_printline();
    # ilog_printf(MSG_SOURCE_PATH, $strSiteRoot);
    # $strYesOrNo =" ";
    # while($strYesOrNo!~/^\s*[YynN]\s*$/)
    # {           
    #     ilog_printf(MSG_MIGRATE_SITE,$strSiteName);
    #     chomp($strYesOrNo = <STDIN>);
    #     ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO) 
    #         if ($strYesOrNo!~/^\s*[YynN]\s*$/);
    # }
    # return 0 if ($strYesOrNo=~/^\s*[Nn]\s*$/);   # exit - site was not selected
    
    $strNewRoot = "";
    # mysql databases
    $strYesOrNo =" ";
    # my $mySQL = FALSE;
    # while($strYesOrNo!~/^\s*[YynN]\s*$/)
    # {        
    #     ilog_printf(MSG_MIGRATE_MYSQL,$strSiteName);
    #     chomp($strYesOrNo = <STDIN>);
    #     if ($strYesOrNo!~/^\s*[YynN]\s*$/) 
    #     {
    #         ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO);            
    #     }
    #     elsif ($strYesOrNo=~/^\s*[Yy]\s*$/)
    #     {
    #         $mySQL = TRUE;
    #     }
    # }
    
    #*******************************************************
    # Add a \ if path has just the drive name...
    #*******************************************************
    $strNewRoot =~ s/:$/:\\/;
    $enableSSL = 0;    
    $strRecoveryInfo  .=  "\n\n[$strSiteName]";					
    $strRecoveryInfo  .=  "\nDocumentRoot=$strSiteRoot";
    $strRecoveryInfo  .=  "\nDestinationPath=$strNewRoot";
    $strRecoveryInfo  .=  "\nSiteIP=$strSiteIP";
	$strRecoveryInfo  .=  "\nSSL=".( ($enableSSL) ? "yes" : "no" );
    $strRecoveryInfo  .=  "\nDefault=$directoryIndex";

    # mySQL 
    # $strRecoveryInfo  .=  "\nMySQL=".( ($mySQL) ? "yes" : "no" );
    # ilog_setLogInformation("REC_INFO","",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "";
    ilog_setLogInformation("EXT_INFO","<$strSiteName>",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "$strSiteRoot";
    ilog_setLogInformation("EXT_INFO","DocumentRoot",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "$strNewRoot";
    ilog_setLogInformation("EXT_INFO","DestinationPath",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "$strSiteIP";
    ilog_setLogInformation("EXT_INFO","SiteIP",$strRecoveryInfo,"","",$strSessionName);
	$strRecoveryInfo  =  ( ($enableSSL) ? "yes" : "no" );
    ilog_setLogInformation("EXT_INFO","SSL",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "$directoryIndex";
    ilog_setLogInformation("EXT_INFO","Default Page",$strRecoveryInfo,"","",$strSessionName);
    my @arrIP = split / /,$strSiteIP;
    foreach $strIP (@arrIP)
    {
        # if _default_ is used change it to * <All UnAssigned>
        $strIP =~ s/^_default_/*/;
        
        if (utf_isValidIP($strIP))
        {
            $IP_mapping{$strIP} = $strIP;			  
        }
        else
        {
            $IP_mapping{$strIP} = "";
        }
        if ($IP2SiteMapping{$strIP} eq "")
        {
            $IP2SiteMapping{$strIP} = $strSiteName;
        } 
        else
        {
            $IP2SiteMapping{$strIP} = $strSiteName.","
                .$IP2SiteMapping{$strIP};		
        }  
    }
    # adriang: does this have to be incremented if we don't run this method?
    $nSitesSelected++;
}

#-------------------------------------------------------------------------
# Method Name       :        pars_SelectSites
# Description       :        The method gets the lists of sites to be 
#                            migrated from the user
# Input             :        Sitename, IP List and Doc root
#
# Output            :        @selected_sites is populated
#
#
# Return Value      :        boolean
#-------------------------------------------------------------------------
sub pars_SelectSites
{
    my $strYesOrNo = "";
    my ($strSiteName,$strSiteIP,$strSiteRoot) = @_;
    my $strNewRoot = "";
    my $strIP ="";
    my $strRecoveryInfo;		# Info to be written on recovery file.
    my $promptyn;
    
    #***********************************************************
    # If Site-Name is blank, change it to a appropriate name...
    #***********************************************************
    if (!$strSiteName)
    {
        $strSiteName = DEFAULT_SITE_ON.$strSiteIP;
    }
    ilog_print(1,"\n\n");
    ui_printline();
    ilog_printf(MSG_SITE_DETAILS,$strSiteName);
    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Site root to be processed [strSiteRoot] : $strSiteRoot\n"); }
    ui_printline();
    ilog_printf(MSG_SOURCE_PATH, $strSiteRoot);
    $strYesOrNo =" ";
    while($strYesOrNo!~/^\s*[YynN]\s*$/)
    {           
        ilog_printf(MSG_MIGRATE_SITE,$strSiteName);
        chomp($strYesOrNo = <STDIN>);
        ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO) 
            if ($strYesOrNo!~/^\s*[YynN]\s*$/);
    }
    return 0 if ($strYesOrNo=~/^\s*[Nn]\s*$/);   # exit - site was not selected
    
    $strNewRoot = "";
    # mysql databases
    $strYesOrNo =" ";
    my $mySQL = FALSE;
    while($strYesOrNo!~/^\s*[YynN]\s*$/)
    {        
        ilog_printf(MSG_MIGRATE_MYSQL,$strSiteName);
        chomp($strYesOrNo = <STDIN>);
        if ($strYesOrNo!~/^\s*[YynN]\s*$/) 
        {
            ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO);            
        }
        elsif ($strYesOrNo=~/^\s*[Yy]\s*$/)
        {
            $mySQL = TRUE;
        }
    }
    
    #*******************************************************
    # Add a \ if path has just the drive name...
    #*******************************************************
    $strNewRoot =~ s/:$/:\\/;
    $enableSSL = 0;    
    $strRecoveryInfo  .=  "\n\n[$strSiteName]";					
    $strRecoveryInfo  .=  "\nDocumentRoot=$strSiteRoot";
    $strRecoveryInfo  .=  "\nDestinationPath=$strNewRoot";
    $strRecoveryInfo  .=  "\nSiteIP=$strSiteIP";
	$strRecoveryInfo  .=  "\nSSL=".( ($enableSSL) ? "yes" : "no" );
    $strRecoveryInfo  .=  "\nDefault=$directoryIndex";

    # mySQL 
    $strRecoveryInfo  .=  "\nMySQL=".( ($mySQL) ? "yes" : "no" );
    ilog_setLogInformation("REC_INFO","",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "";
    ilog_setLogInformation("EXT_INFO","<$strSiteName>",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "$strSiteRoot";
    ilog_setLogInformation("EXT_INFO","DocumentRoot",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "$strNewRoot";
    ilog_setLogInformation("EXT_INFO","DestinationPath",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "$strSiteIP";
    ilog_setLogInformation("EXT_INFO","SiteIP",$strRecoveryInfo,"","",$strSessionName);
	$strRecoveryInfo  =  ( ($enableSSL) ? "yes" : "no" );
    ilog_setLogInformation("EXT_INFO","SSL",$strRecoveryInfo,"","",$strSessionName);
    $strRecoveryInfo  =  "$directoryIndex";
    ilog_setLogInformation("EXT_INFO","Default Page",$strRecoveryInfo,"","",$strSessionName);
    my @arrIP = split / /,$strSiteIP;
    foreach $strIP (@arrIP)
    {
        # if _default_ is used change it to * <All UnAssigned>
        $strIP =~ s/^_default_/*/;
        
        if (utf_isValidIP($strIP))
        {
            $IP_mapping{$strIP} = $strIP;			  
        }
        else
        {
            $IP_mapping{$strIP} = "";
        }
        if ($IP2SiteMapping{$strIP} eq "")
        {
            $IP2SiteMapping{$strIP} = $strSiteName;
        } 
        else
        {
            $IP2SiteMapping{$strIP} = $strSiteName.","
                .$IP2SiteMapping{$strIP};		
        }  
    }
    # adriang: does this have to be incremented if we don't run this method?
    $nSitesSelected++;
}

#-------------------------------------------------------------------------
# Method Name        : pars_GetNextDirective.
#
# Description        : The method is used to return the name and value of 
#                      the directives that are migrated by the tool.
#
# Input              : File Handle to a opened httpd.conf file.
#
# OutPut             : 2 scalar variables,one the directive name and the 
#					   other its value.
#
# Status             : Success/failure depending on the status of the 
#					   function call.
#-------------------------------------------------------------------------
sub pars_GetNextDirective
{
    my $strLineContent;
    my @arrTemp;
    my $temp;
    while ($strLineContent = <hfileHTTPD>)
    {
        $strLineContent = pars_chomp($strLineContent);
        $strLineContent =~ s/^\s+//;
        if($strLineContent ne "")
        {
            if($strLineContent !~ /^#/)
            {
                if($strLineContent =~ /</)
                {
                    $strLineContent =~ s/<//;
                    $strLineContent =~ s/>//;
                    $strLineContent =~ s/^\s+//;
                }

                @arrTemp = split / /,$strLineContent;
                $strDirectiveName  = $arrTemp[0];
                $strDirectiveValue = '';
                foreach $temp (@arrTemp)
                {
                    if($temp ne $strDirectiveName)
                    {
                        $strDirectiveValue = 
                            $strDirectiveValue." ".$temp;
                    }
                }

                return 1;
            }
        }
    }

    return 0;
}

#-------------------------------------------------------------------------
# Method Name       :        pars_OpenConfigFile
#
# Description       :        Opens the Apache config file. If the file is 
#							 related information
#
# Input             :        1. path of apache config file..
#                            2.
# Output            :        1.
#                            2.
#                            3.
# Return Value      :        boolean
#-------------------------------------------------------------------------
sub pars_OpenConfigFile
{
    my $strHttpdPath = shift;
    my $ret = 0;
    eval
    {
        #*****************************************************
        #   Try opening the file from session folder.
        #   if not found, go for FTP...
        #*****************************************************
        $ret = open( hfileHTTPD , $strSessionFolder.$strHttpdPath) ;
        return $ret if ($ret);

        #*****************************************************
        #   File was not found. Going to cache.
        #   First check, if its a directory...
        #*****************************************************
        my $strLocalPath = '';
        if (-d $strHttpdPath)
        {
            #*****************************************************
            #   Its a directory. Scan the directory recursively
            #   and add the files to the Parse-files list.
            #   Set the first file in the folder as current file.
            #*****************************************************
            my @dirList = &pars_dirSourceR($strHttpdPath, 0);            
            for (my $i=1; $i <= $#dirList; $i++)
            { 
                push(@arrParseFiles, $dirList[$i]);
            }

            $strLocalPath = $dirList[0];
        }
        else
        {
            $strLocalPath = $strHttpdPath;
        }
        
        #*****************************************************
        #   Cache the config file in the session dir
        #*****************************************************        
        for my $op (glob $strLocalPath)
        {
            my $f = $op;
            $f =~ s/\//_/g;
            $f = $strSessionFolder.$f;
            $ret = File::Copy::copy($op, $f);            
            if (!$ret)
            {
                ilog_print(1,"ERROR: copying: $op TO $f \n");
                die ERR_CRITICAL . ERR_OPENING_CONFIG . " [$strHttpdPath] " ;
            }
            
            # OPEN the FILE
            open hfileHTTPD , $f
                or die ERR_CRITICAL . ERR_OPENING_CONFIG . " [$strHttpdPath] ";
        }
    };
    if($@)
	{
		$ret = 0;
	}
    
    return $ret;
}

############################################################################
# Method Name	:	pars_dirSource
#
# Description	: 	get the folder listing (dir) for the specified folder..
#
# Input		    :	1. Folder to list
#			        
# Output		:	None
#			        
# Return Value  :	A 2d array containing list of FileType, FilePath and FileSize
############################################################################s
sub pars_dirSource
{
    my $SourceDir = shift;
    my @arrReturn = ();
    my @arrTemp;
    my $mtime;
    my $mode;
    for (parse_dir(`ls -l -a $SourceDir`))
    {
        ($arrTemp[1], $arrTemp[0], $arrTemp[2], $mtime, $mode) = @$_;        
        if (($arrTemp[1] eq ".") or ($arrTemp[1] eq ".."))
        {
            next;
        }
        else
        {
            my $f = $SourceDir."/".$arrTemp[1];
            push(@arrReturn, $f);
        }
    }

    for (my $i=0; $i <= $#arrReturn; $i++)
    {
        my $f = $arrReturn[$i];
    }

    return @arrReturn;
}

############################################################################
# Method Name	:   pars_dirSourceR
#
# Description	: 	Get the folder listing (dir) recursively for the specified 
#                   folder..
#
# Input		    :	1. Folder to list
#			        
# Output	    :	None
#			        
# Return Value  :	A 2d array containing list of FileType, FilePath and FileSize
############################################################################
sub pars_dirSourceR
{
    my @dl = &pars_dirSource(shift);
    my $level = shift;
    my @dirList = ();

    for (my $i=0; $i <= $#dl; $i++)
    {
        my $f = $dl[$i];
        if (-d $dl[$i])
        {
            my @dr = &pars_dirSourceR($dl[$i], $level + 1);
            for (my $j=0; $j <= $#dr; $j++)
            {
                $f = $dr[$j];
                push(@dirList, $dr[$j]);
            }
        }
        else
        {
            push(@dirList, $dl[$i]);
        }
    }
    
    return @dirList;
}

#-------------------------------------------------------------------------
# Method Name       :        pars_GetSessionFolder
#
# Description       :        Sets the folder path at which the current
#							 session files are stored.
#
# Input             :        1. None
#                            2.
# Output            :        1.
#                            2.
#                            3.
# Return Value      :        Session Folder Path
#-------------------------------------------------------------------------
sub pars_SetSessionFolder
{
    my $OSType;    
    &utf_setCurrentWorkingFolder;	
	$strSessionName = ilog_getSessionName();	
    $OSType = $^O; # get the current operating system type
	if($OSType eq WINDOWS)
	{
            $strSessionFolder = utf_getCurrentWorkingFolder()."\\".$strSessionName."\\";
	}
    else
    {
        $strSessionFolder = utf_getCurrentWorkingFolder()."/".$strSessionName."/";
    }

    return $strSessionFolder;
}

sub pars_GetSessionFolder
{
	return $strSessionFolder;
}

sub pars_chomp
{
    my $str = shift;
    $str =~ s/\n//;
    $str =~ s/\r//;
    return $str;
}

sub pars_unQuote
{
    my $str = shift;
    $str =~ s/[\"\']+//g;
    return $str;
}

# Form the absolute path from the path and the base
sub pars_AbsPath
{
    my ($strBase,$strPath) = @_;
    
    # if path is already absolute return it right away...
    return $strPath if ($strPath =~ /^\//);    
    # if base path ends with a slash, add both strings and return...     
    return $strBase.$strPath if ($strBase =~ /\/$/);     
    # else add a slash inbetween and retrun...     
    return $strBase."/".$strPath;
}

sub pars_GetRecoveryCode
{
    my $RecStatus;
    my $recFile = &utf_getCurrentWorkingFolder() . "/". &ilog_getSessionName() . "/" . AMW . &ilog_getSessionName() . FILE_RECOVERY;
    open RECOVERY,$recFile or die "Error opening recovery.txt file";
    $RecStatus = <RECOVERY>;
    close RECOVERY;
    chomp($RecStatus);	
    $RecStatus =~ s/\s+//g;     #remove trailing space..
    return $RecStatus;
}

sub pars_SetRecoveryCode
{
    my $RecStatus = shift;
    my $recFile = &utf_getCurrentWorkingFolder() . "/". &ilog_getSessionName() . "/" . AMW . &ilog_getSessionName() . FILE_RECOVERY;
    open RECOVERY,"+<$recFile" or die "Error opening recovery.txt file";
    print RECOVERY $RecStatus. "\n"; 
    close RECOVERY;    
}
1;
