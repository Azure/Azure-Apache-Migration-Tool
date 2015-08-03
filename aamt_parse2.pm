#######################################################################################################################
#
# Method Name   : pars_Generate2D
#
# Description   : The method is used to populate a 2 dimensional array 
#                 the name and value of the directives that are migrated by the tool. 
#
# Input         : Httpd.conf
#
# OutPut        : Creation of a 2 dimensional array enumerating the site configuration information read from apache config
#
# Status        : Success/failure depending on the status of the function call.
#
#######################################################################################################################
use strict;
use xml::doc;
use aamt_utilityFunctions;
use JSON;
use Digest::MD5 qw(md5_hex);
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use XML::SAX;
# use XML::LibXML;
use MIME::Base64;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Find::Rule;
use File::Find;
use File::Basename;
use Cwd 'abs_path';
use File::Path;
my $DEBUG_MODE = 1;

#----------------------------------------------------------------------------------------------------------------------
#                                          Global variables used by this module
#----------------------------------------------------------------------------------------------------------------------
my $SITE_URL = 'https://migrate4.azurewebsites.net';
my @siteIndex;                  # To store the string used for display
my @array;                      # To store Site related directive settings.
my @arrayDir;                   # To store Directory related directive settings.
my @files;                      # To store File related directive settings.
my $directiveName;              # To store the Directive Name encountered when read from httpd.conf file.
my $directiveValue;             # To store the Directive Value encountered when read from httpd.conf.
my $configFile;                 # To store the name of the file which has the Apache configuration settings.
my $ResourceFile;               # To store the name of the file which has the site details selected for migration
my $lineContent;                # To store the individual line content read from httpd.conf
my @Tmp;                    
my $temp;
my $rowCount = 0;               # To store the number of rows encountered by the array enumerating site information.
my $columnCount = 0;            # To store the number of columns encountered by the array enumerating site information.
my $rowDirCount = -1;           # To store the number of rows encountered by the array enumerating folder information.  
my $filecount = -1;             # To store the number of rows encountered by the array enumerating files information.   
my $maxColumn = 54;             # To store the number of Columns : Equivalent to the number of directives migrated.
my $defaultUserdir = 0;         # To store the default User directory path. 
my $destinationPath;            # To store the destination selected on the target machine.
my $defaultPath;
my $i = 0;                      
my $flag = 0;
my $filepos;
my $dirMatch = 0;
my $fileMatch = 0;
my $siteName;
my $portValue;
my $ipAddress;
my $aclFlag = 0;
my $userFlag = 0;
my @includeFileName;
my @includeFilePointer;
my $errorFlag = 1;
my $resourceFlag = 1;
my $accessFlag = 1;
my @aliasDir;
my $aliasDirInd = -1;
my @scriptaliasDir;
my $scriptaliasDirInd = -1;
my %ServerBinding;              # ServerBiniding String for each site
my $mimeTypes = ""; 
my $mimeFlag = 1;
my @errorDocument;
my $errorDocumentCount = 0;
my $virtUserdir = 0;

#----------------------------------------------------------------------------------------------------------------------
$siteIndex[0]  = 'SITENAME';
$siteIndex[1]  = 'DIRECTORY';
$siteIndex[2]  = 'FILES';
$siteIndex[3]  = 'KEEPALIVE';
$siteIndex[4]  = 'KEEPALIVETIMEOUT';
$siteIndex[5]  = 'LISTEN';
$siteIndex[6]  = 'LISTENBACKLOG';
$siteIndex[7]  = 'MAXCLIENTS';
$siteIndex[8]  = 'NAMEVIRTUALHOST';
$siteIndex[9]  = 'OPTIONS';
$siteIndex[10] = 'ORDER';
$siteIndex[11] = 'PORT';
$siteIndex[12] = 'RESOURCECONFIG';
$siteIndex[13] = 'SCRIPTALIAS';
$siteIndex[14] = 'SCRIPTALIASMATCH';
$siteIndex[15] = 'SERVERALIAS';
$siteIndex[16] = 'SERVERNAME';  
$siteIndex[17] = 'SERVERROOT';
$siteIndex[18] = 'TIMEOUT';
$siteIndex[19] = 'USERDIR';   
$siteIndex[20] = 'VIRTUALHOST';
$siteIndex[21] = 'ACCESSCONFIG';
$siteIndex[22] = 'ADDENCODING';
$siteIndex[23] = 'ADDTYPE';
$siteIndex[24] = 'ALIAS';
$siteIndex[25] = 'ALIASMATCH';
$siteIndex[26] = 'AUTHGROUPFILE';
$siteIndex[27] = 'AUTHNAME';
$siteIndex[28] = 'AUTHTYPE';
$siteIndex[29] = 'AUTHUSERFILE';        
$siteIndex[30] = 'BINDADDRESS';
$siteIndex[31] = 'DEFAULTTYPE';
$siteIndex[32] = 'DENY';
$siteIndex[33] = 'DIRECTORYMATCH';
$siteIndex[34] = 'DIRECTORYINDEX';
$siteIndex[35] = 'DOCUMENTROOT';
$siteIndex[36] = 'ERRORDOCUMENT';
$siteIndex[37] = 'ERRORLOG';
$siteIndex[38] = 'EXPIRESACTIVE';
$siteIndex[39] = 'EXPIRESDEFAULT';
$siteIndex[40] = 'EXPIRESBYTYPE';
$siteIndex[41] = 'FILESMATCH';
$siteIndex[42] = 'HEADER'; 
$siteIndex[43] = 'HOSTNAMELOOKUPS';
$siteIndex[44] = 'IDENTITYCHECK';
$siteIndex[45] = 'IFMODULE';    
$siteIndex[46] = 'ALLOWOVERRIDE';
$siteIndex[47] = 'SSLENGINE';
$siteIndex[48] = 'SSLCERTIFICATEFILE';
$siteIndex[49] = 'SSLCERTIFICATEKEYFILE';  
$siteIndex[50] = 'USERDIRENABLED';
$siteIndex[51] = 'USERDIRDISABLED';
$siteIndex[52] = 'ACCESSFILENAME';
$siteIndex[53] = 'DESTINATIONPATH';
$siteIndex[54] = 'DIRBITSET';   
$siteIndex[55] = 'USERENABLED'; 
$siteIndex[56] = 'USERDISABLED';
$siteIndex[57] = 'TASKLIST';
$siteIndex[58] = 'XML'; 

######################################################################################
#Sub        : pars_GetDirlistinght
#Purpose    : Used to get a complete recuresive listing of the input Document root
#Inputs     : DocumentRoot      
#Outputs    : Execution of the command ls -lRa
#######################################################################################
sub pars_GetDirlistinght
{
    my $DocumentRoot = shift;
    return `ls -lRa $DocumentRoot 2>/dev/null`;
}

sub pars_CreateReadinessReport
{
    my $value;
    my $cnt = 0;
    my $i;
    my $j;
    my $logFilereturn;
    my @rSites;
    my $rComputername = `hostname`;
    $rComputername =~ s/\n//g;
    my $login = getlogin || getpwuid($<) || "Kilroy";
    my $guid = &genGUID($rComputername.$login);
    my %rServer = ();
    my %rServers = ();
    my %rServers2 = ();
    my $json_text;
    my $start = 0;
    my $osVersion = `uname -v`;
    $osVersion =~ s/\n//g;
    $osVersion = 'LX: ' . $osVersion;
    $osVersion = substr($osVersion, 0, 50);
    $array[0][PUBLISH] = &pars_AskSelectSites($array[0][SITENAME], $array[0][DOCUMENTROOT]);
    if ($array[0][PUBLISH])
    {
        $start = 0;
    }
    else
    {
        $start = 1;
    }
    my $sIndex = 0;
    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: starting checking sites for selection"); }
    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: rowCount: $rowCount"); }
    for ($i = $start; $i <= $rowCount; $i++)
    {
        my $mySiteName = $array[$i][SITENAME];
        if ($i != 0)
        {
            $array[$i][PUBLISH] = &pars_AskSelectSites($array[$i][SITENAME], $array[$i][DOCUMENTROOT]);
            if ( !$array[$i][PUBLISH] )
            {
                # if we are not publishing the site, go to the next one
                next;
            }
        }

        my %rSite = ();
        my @defaultDocs;
        my @bindings;        
        my @databases;
        my %database;
        $rSite{"AppPoolName"} = "DefaultLinuxAppPool";
        $rSite{"ServerName"} = $rComputername;
        $rSite{"SiteName"} = $mySiteName;

        # size of the site
        my $size;
        find(sub{ -f and ( $size += -s ) }, $array[$i][DOCUMENTROOT] );
        $size = sprintf("%.02f",$size / 1024 / 1024);
        $rSite{"SizeInMb"} = $size;

        # if (&pars_siteHasDb($mySiteName))
        # populates $array global variable
        &pars_siteHasValidFrameworkDb($i);
        if ($array[$i][MYSQL])
        {
            (my $dbName, my $dbUser, my $dbPassword, my $dbHost) = &ReadDbSettingsForFramework($array[$i][FRAMEWORK], $array[$i][CONFIGFILE]);

            $database{"ConnectionStringName"} = "MySQLConnection";
            $database{"ProviderName"} = "MySql.Data.MySqlClient";
            # size of the database
            if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: MYSQL SIZE:\nmysql -N -B -h $dbHost -u $dbUser -p'$dbPassword' $dbName -e 'select dbsize from (SELECT table_schema, sum( data_length + index_length ) / 1024 / 1024 dbsize FROM information_schema.TABLES GROUP BY table_schema) as s where table_schema=$dbName;'"); }
            my $sizeInMb = `mysql -N -B -h $dbHost -u $dbUser -p'$dbPassword' $dbName -e 'select dbsize from (SELECT table_schema, sum( data_length + index_length ) / 1024 / 1024 "dbsize" FROM information_schema.TABLES GROUP BY table_schema) as s where table_schema="$dbName";'`;
            $sizeInMb =~ s/\n//g;
            $database{"SizeInMb"} = "$sizeInMb";
            $databases[0] = \%database;
            $rSite{"Databases"} = \@databases;
        }
        
        $defaultDocs[0] = $array[$i][DIRECTORYINDEX];        
        $rSite{"DefaultDocuments"} = \@defaultDocs;

        my %binding;
        $binding{"Port"} = $array[$i][PORT];
        $binding{"CustomServerIP"} = "false";
        $binding{"CustomHostName"} = "true";
        $binding{"Name"} = $array[$i][PORT];        
        # check SSL/HTTPS
        if (($array[$i][SSLENGINE] ne "" && $array[$i][SSLENGINE] ne "off") || $array[$i][SSLCERTIFICATEFILE] ne "")
        {
            # Corresponds to IP SSL, however it may be SNI SSL
            $binding{"Protocol"} = "2";
        }
        else
        {
            $binding{"Protocol"} = "0";
        }

        $bindings[0] = \%binding;
        
        $rSite{"Bindings"} = \@bindings;
        $rSites[$sIndex] = \%rSite;
        $json_text = encode_json ( \%rSite );
        if ($DEBUG_MODE) { ilog_print(1,"\nsite JSON:\n$json_text\n"); }
        $sIndex++;
    }
    
    $json_text = encode_json ( \@rSites );
    my %appPool = ("Name"=>"DefaultLinuxAppPool","Enable32BitOn64"=>"false","IsClassicMode"=>"false","NetFxVersion"=>"4");
    my @appPools = ();
    $appPools[0] = \%appPool;
    $rServer{"AppPools"} = \@appPools;
    $rServer{"Sites"} = \@rSites;
    $rServer{"Name"} = $rComputername;
    $rServer{"AzureMigrationID"} = $guid;
    $rServer{"OsVersion"} = $osVersion;
    $json_text = encode_json ( \%rServer );

    $rServers{$rComputername} = \%rServer;
    $rServers2{"Servers"} = \%rServers;
    # Log the 2 dimensional array content to Status and Log files.    
    $json_text = encode_json ( \%rServers2 );
    my $baseAddress = $SITE_URL .'/api/compat2/'.$guid;
    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Uploading the JSON Readiness report to $baseAddress:\n $json_text\n"); }
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new("PUT", $baseAddress);
    $req->header( 'Content-Type' => 'application/json' );
    $req->content( $json_text );

    my $publishSuccess = FALSE;
    while (!$publishSuccess)
    {
        my $res = $ua->request($req);
        my $rContent = $res->content;
        my $rCode = $res->code;
        if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Readiness report response code: $rCode\n"); }
        if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Readiness report result\n: $rContent\n"); }

        if ($rCode !~ /^\s*2[0-9]*/)
        {
            ilog_print(1,"\n\nPublishing failed with response code: $rCode\n");            
            my $strYesOrNo ="";
            while($strYesOrNo!~/^\s*[YynN]\s*$/)
            {
                ilog_printf(1, "    Would you like to retry uploading the readiness report? (Y/N):");
                chomp($strYesOrNo = <STDIN>);
                ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO)
                    if ($strYesOrNo!~/^\s*[YynN]\s*$/);
                $publishSuccess = $strYesOrNo =~ /^\s*[Nn]\s*$/;
            }
        }
        else
        {
            $publishSuccess = TRUE;
        }            
    }

    ilog_print(1,"\nReadiness report uploaded, to continue navigate to:\n ${SITE_URL}/results/index/$guid\n\nCreate site and databases and then download and save the publish settings file to this computer.");
}

sub pars_UploadPublishSettingsAllSites
{
    my @tmpArray;
    my $recoveryFile = $ResourceFile;
    eval
    {
        open RECOVERYHANDLE ,$recoveryFile or die 'ERR_FILE_OPEN';
    };
    if($@)
    {
        if($@=~/ERR_FILE_OPEN/)
        {   
            # log error and exit tool
            ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_OPEN,__LINE__);       
            return FALSE;
        }
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_OPEN,'');
    }

    ilog_print(1,"\n\n");
    ui_printline();
    ilog_printf(1,"Please enter the location of the publish settings: \n");
    ui_printline();
    my $strPublishSettings =" ";
    my $fileFound = FALSE;
    while(!$fileFound)
    {
        ilog_printf(1, "    Please enter the location of the publish settings: ");
        chomp($strPublishSettings = <STDIN>);
        eval
        {
            open PUBLISH_HANDLE ,$strPublishSettings or die 'ERR_FILE_OPEN';
        };
        if($@ && $@=~/ERR_FILE_OPEN/)
        {
            $fileFound = FALSE;
        }
        else
        {
            $fileFound = TRUE;
            last;
        }

        ilog_print(0,ERR_INVALID_INPUT." Please enter a valid path for the publish settings\n")
            if (!$fileFound);
        close PUBLISH_HANDLE;        
    }
    
    # while ($lineContent = <RECOVERYHANDLE>)
    # {
    #     # [SiteName] is the format
    #     if($lineContent =~ /^\[/)
    #     {
    #         $lineContent =~ s/\[//;
    #         $lineContent =~ s/\]//;
    #         $lineContent =~ s/^\s+//;
    #         $lineContent =~ s/\s+$//;
    #         my $siteName = $lineContent;
    #         # my $mySQL = FALSE;
    #         my $documentRoot = '';
    #         while ($lineContent = <RECOVERYHANDLE> and $lineContent !~ /^\[/)
    #         {
    #             # if($lineContent =~ /^MySQL/)
    #             # {                   
    #             #     if ($lineContent =~ 'yes')
    #             #     {
    #             #         $mySQL = TRUE;
    #             #     }
    #             # }
    #             if($lineContent =~ /^DocumentRoot/)
    #             {
    #                 @tmpArray = split /=/,$lineContent;
    #                 $documentRoot = $tmpArray[1];
    #                 chomp($documentRoot);
    #             }
    #         }
            
    #         if ($lineContent =~ /^\[/)
    #         {
    #             # place the same line back onto the filehandle
    #             seek(RECOVERYHANDLE, -length($lineContent), 1); 
    #         }
            
    #         # look up the array indice corresponding to the site name in the global site array
    #         my $sIndex = 0;            
    #         for ($sIndex = 0; $sIndex < @array; $sIndex++)
    #         {
    #             if ($array[$sIndex][SITENAME] eq $siteName)
    #             {
    #                 last;
    #             }
    #         }
    #         # what to do if $sIndex > @array size??

    #         &pars_UploadPublishSettings($siteName, $documentRoot, $strPublishSettings, 
    #                                     $array[$sIndex][MYSQL], $array[$sIndex][FRAMEWORK], $array[$sIndex][CONFIGFILE]);
    #     }        
    # }

    for ($i = 0; $i <= $rowCount; $i++)
    {
        if ($array[$i][PUBLISH])
        {
            &pars_UploadPublishSettings($array[$i][SITENAME], $array[$i][DOCUMENTROOT], $strPublishSettings, 
                                        $array[$i][MYSQL], $array[$i][FRAMEWORK], $array[$i][CONFIGFILE]);
        }
    }

    eval
    {
        close RECOVERYHANDLE or die 'ERR_FILE_CLOSE';
    };

    if($@)
    {
        if($@=~/ERR_FILE_CLOSE/)
        {   
            ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_CLOSE,__LINE__);      
        }        
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_CLOSE,'');
    }

    ilog_print(1,"\nThanks for using the Apache to Azure App Service Migration Tool! \n");
    return 0; 
}

sub pars_UploadPublishSettings
{
    my $strSiteName = shift;
    my $documentRoot = shift;
    my $strPublishSettings = shift;
    my $mySQL = shift;
    my $framework = shift;
    my $configFile = shift;
    my $strYesOrNo = "";
    
    ilog_print(1,"\n\n");
    ui_printline();
    ilog_printf(1,"[ $strSiteName ] - Site Publishing \n");
    ui_printline();
    $strYesOrNo =" ";
    while($strYesOrNo!~/^\s*[YynN]\s*$/)
    {
        ilog_printf(1, "    Do you want to publish the site [$strSiteName]? (Y/N):");
        chomp($strYesOrNo = <STDIN>);
        ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO)
            if ($strYesOrNo!~/^\s*[YynN]\s*$/);
    }

    return 0 if ($strYesOrNo=~/^\s*[Nn]\s*$/);   # exit - site was not selected
    &pars_PublishSite($strSiteName, $documentRoot, $strPublishSettings, $mySQL, $framework, $configFile);
}

# TODO: RE-FACTOR THIS INTO EVERYWHERE
# sub ReadDbSettingsForFramework
# {
#     my $framework = shift;
#     my $configFile = shift;

#     my $dbName;
#     my $dbUser;
#     my $dbPassword;
#     my $dbHost;

#     my $strCurWorkingFolder = &utf_getCurrentWorkingFolder();
#     #get session name
#     my $strSessionName = &ilog_getSessionName();
#     #form the complete working folder
#     my $workingFolder = $strCurWorkingFolder . '/' . $strSessionName;

#     if ($framework eq WORDPRESS)
#     {
#         `php read_wp_settings.php "$configFile" "$workingFolder/config-out.txt";`;        
#     }
#     elsif ($framework eq DRUPAL)
#     {
#         `php read_drupal_settings.php "$configFile" "$workingFolder/config-out.txt";`;        
#     }
#     elsif ($framework eq JOOMLA)
#     {
#         `php read_joomla_settings.php "$configFile" "$workingFolder/config-out.txt";`;        
#     }
#     else
#     {
#         # we have a bug...
#         ilog_print(1,"\nERROR: Unrecognized framework: $framework\n");
#         return 0;
#     }

#     open my $configFile, '<', "$workingFolder/config-out.txt" or die "Can't read config-out.txt: $!";
#     while (my $line = <$configFile>)
#     {
#         my @tempSplit = split('=', $line);
#         my $tempValue = @tempSplit[1];
#         chomp($tempValue);
#         if ($line =~ /DB_NAME/)
#         {
#             $dbName = $tempValue;
#         }
#         if ($line =~ /DB_USER/)
#         {
#             $dbUser = $tempValue;
#         }
#         if ($line =~ /DB_PASSWORD/)
#         {
#             $dbPassword = $tempValue;
#         }
#         if ($line =~ /DB_HOST/)
#         {
#             $dbHost = $tempValue;
#         }
#         # if ($line =~ /WP_SITEURL/)
#         # {
#         #     $wpSiteurl = $tempValue;
#         # }
#         if ($line =~ /INCLUDED_FILES/)
#         {
#             @files = split /;/,$tempValue;
#         }
#     }
    
#     return ($dbName, $dbUser, $dbPassword, $dbHost);
# }

sub pars_PublishSite
{
    my $strSiteName = shift;
    my $documentRoot = shift;
    my $rComputername = `hostname`;
    my $strPublishSettings = shift;
    my $mySQL = shift;
    my $framework = shift;
    my $configFile = shift;

    $rComputername =~ s/\n//g;
    my $publishSuccess = FALSE;
    my $strYesOrNo =" ";
    # get the current working folder
    my $strCurWorkingFolder = &utf_getCurrentWorkingFolder();
    #get session name
    my $strSessionName = &ilog_getSessionName();
    #form the complete working folder
    my $workingFolder = $strCurWorkingFolder . '/' . $strSessionName;
    my $publishUrl;
    my $destinationAppUrl;
    my $userName;
    my $userPWD;
    my $mySqlConnectionString;
    while (!$publishSuccess)
    {
        my $xml = XML::Simple->new;
        my $data = $xml->XMLin($strPublishSettings, ForceArray => ['publishProfile']);
        for my $entry (@{$data->{publishProfile}})
        {
            my $key = $entry->{originalsitename};
            if ($key eq $rComputername.":".$strSiteName)
            {
                $publishUrl = $entry->{publishUrl};
                $userName = $entry->{userName};
                $userPWD = $entry->{userPWD};
                $destinationAppUrl = $entry->{destinationAppUrl};
                my $dbs = $entry->{databases};
                if ($dbs)
                {
                    $mySqlConnectionString = $dbs->{add}->{connectionString};                    
                }
                
                if ($DEBUG_MODE) { print "\nDEBUG: site [$strSiteName] located in publishsettings\npublishUrl: $publishUrl\n userName: $userName\n userPWD: $userPWD\nMySQL: $mySQL\n"; }
                last;
            }
        }
        
        my $rCode = &deployToSite($publishUrl, $documentRoot, $userName, $userPWD, TRUE);
        if ($rCode !~ /^\s*2[0-9]*/)
        {
            ilog_print(1,"\n\nPublishing failed with response code: $rCode\n");            
            $strYesOrNo =" ";
            while($strYesOrNo!~/^\s*[YynN]\s*$/)
            {
                ilog_printf(1, "    Would you like to retry publishing the site [$strSiteName]? (Y/N):");
                chomp($strYesOrNo = <STDIN>);
                ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO)
                    if ($strYesOrNo!~/^\s*[YynN]\s*$/);
            }
            
            $publishSuccess = $strYesOrNo =~ /^\s*[Nn]\s*$/;
        }
        else
        {
            $publishSuccess = TRUE;
            &updateTrackingStatus($strSiteName, FALSE);
        }
    }

    # Remote database variables
    my $rServer;
    my $rUsername;
    my $rPassword;
    my $rDatabase;
    for my $section (split(';', $mySqlConnectionString))
    {
        my @tempSplit = split('=', $section);
        if ($tempSplit[0] =~ /uid/i || $tempSplit[0] =~ /user/i)
        {
            $rUsername = $tempSplit[1];
        }
        
        if ($tempSplit[0] =~ /pwd/i || $tempSplit[0] =~ /password/i)
        {
            $rPassword = $tempSplit[1];
        }
        
        if ($tempSplit[0] =~ /server/i || $tempSplit[0] =~ /data source/i)
        {
            $rServer = $tempSplit[1];
        }

        if ($tempSplit[0] =~ /database/i)
        {
            $rDatabase = $tempSplit[1];
        }
    }

    $publishSuccess = FALSE;
    while (!$publishSuccess)
    {
        if ($mySQL)
        {
            # local settings read from config file
            my $dbName;
            my $dbUser;
            my $dbPassword;
            my $dbHost;
            my $wpSiteurl;
            # read the config file of the framework
            my $readCommand = "";
            my $lineMatch;
            my $lineNotMatch = "";
            my $settingsLine;
            if ($framework eq WORDPRESS)
            {
                my $wpsubdir = $configFile;
                my $documentRoot2 = quotemeta($documentRoot);
                $wpsubdir =~ s/$documentRoot2//g;
                $wpsubdir =~ s/wp-config.php//g;
                `php read_wp_settings.php "$configFile" "$workingFolder/config-out.txt";`;
                $lineMatch = qr/define.*'DB_NAME'|define.*'DB_USER'|define.*'DB_PASSWORD'|define.*'DB_HOST'|define\s*\(\s*'WP_CONTENT_DIR'/;
                $lineNotMatch = qr/define\s*\(\s*'WP_CONTENT_DIR',\s*ABSPATH\s*.\s*'wp-content'\s*\)/;
                $settingsLine = "define('DB_NAME', '$rDatabase');\ndefine('DB_USER', '$rUsername');\ndefine('DB_PASSWORD', '$rPassword');"
                    . "\ndefine('DB_HOST', '$rServer');\ndefine('WP_HOME','${destinationAppUrl}${wpsubdir}'); \ndefine('WP_SITEURL','${destinationAppUrl}${wpsubdir}');\n";
            }
            elsif ($framework eq DRUPAL)
            {
                `php read_drupal_settings.php "$configFile" "$workingFolder/config-out.txt";`;
                # TODO: improve drupal detection logic
                $lineMatch = qr/databases.*'default'.*'default'/;
                $settingsLine = "\$databases['default']['default']=array('driver'=>'mysql','database' =>'$rDatabase','username'=>'$rUsername','password'=>'$rPassword','host'=>'$rServer','port' => '','prefix' => '');\n";
            }
            elsif ($framework eq JOOMLA)
            {
                `php read_joomla_settings.php "$configFile" "$workingFolder/config-out.txt";`;
                $settingsLine = "public \$db = '$rDatabase';\npublic \$user = '$rUsername';\npublic \$password = '$rPassword';\npublic \$host = '$rServer';\n";
                $lineMatch = qr/\$db\s*=|\$user\s*=|\$password\s*=|\$host\s*=/
            }
            else
            {
                # we have a bug...
                ilog_print(1,"\nERROR: Unrecognized framework: $framework\n");
                return 0;
            }

            open my $configFile, '<', "$workingFolder/config-out.txt" or die "Can't read config-out.txt: $!";
            while (my $line = <$configFile>)
            {
                my @tempSplit = split('=', $line);
                my $tempValue = @tempSplit[1];
                chomp($tempValue);
                if ($line =~ /DB_NAME/)
                {
                    $dbName = $tempValue;
                }
                if ($line =~ /DB_USER/)
                {
                    $dbUser = $tempValue;
                }
                if ($line =~ /DB_PASSWORD/)
                {
                    $dbPassword = $tempValue;
                }
                if ($line =~ /DB_HOST/)
                {
                    $dbHost = $tempValue;
                }
                if ($line =~ /WP_SITEURL/)
                {
                    $wpSiteurl = $tempValue;
                }
                if ($line =~ /INCLUDED_FILES/)
                {
                    @files = split /;/,$tempValue;
                }
            }
            
            # ilog_printf(1, "\n    $framework site detected, would you like to automatically change the config file for [$strSiteName]? (Y/N):");
            # my $strYesOrNo = '';

            # while($strYesOrNo !~ /^\s*[YynN]\s*$/)
            # {
            # chomp($strYesOrNo = <STDIN>);
            # if ($strYesOrNo!~/^\s*[YynN]\s*$/)
            # {
            #     ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO);
            # }
            # elsif ($strYesOrNo=~/^\s*[Nn]\s*$/)
            # {
            #     last;
            # }
            # START MUNGING
            rmtree(["$workingFolder/wwwroot"]);
            mkdir "$workingFolder/wwwroot";
            my @filesToCopy;
            # this relocates files to be in the correct layout in the working folder
            # the relocated files now end with _copy
            &getConfigFiles($documentRoot, $lineMatch, $lineNotMatch, $workingFolder, \@files);
            @files = File::Find::Rule->file()
                ->name("*_copy")
                ->in("$workingFolder/wwwroot");
            for my $phpFile (@files)
            {
                my $settingsInserted = FALSE;
                open my $fh, '<', $phpFile or die "Failed to open $_: $!";
                my $outFile = $phpFile;
                $outFile =~ s/_copy//g;
                open my $out, '>', $outFile or die "Can't write to $outFile file: $!";

                # my $openBracket = FALSE;
                # while (my $line = <$fh>)
                # {
                #     if ($line =~ /databases\['default'\]\['default'\]/)
                #     {
                #         if (!$settingsInserted)
                #         {
                #             print $out $settingsLine;                                        
                #             $settingsInserted = TRUE;
                #         }

                #         $openBracket = TRUE;
                #     }
                
                #     if ($openBracket)
                #     {
                #         print $out "// COMMENTED OUT BY AZURE APP SERVICE MIGRATION TOOL: $line";
                #     }
                #     else
                #     {
                #         print $out $line;
                #     }

                #     if ($openBracket && $line =~ ';')
                #     {
                #         $openBracket = FALSE;
                #     }
                # }

                my $openBracket = FALSE;
                while (my $line = <$fh>)
                {
                    if ($line =~ $lineMatch && ($lineNotMatch eq "" || $line !~ $lineNotMatch))
                    {
                        if (!$settingsInserted)
                        {
                            print $out $settingsLine;
                            $settingsInserted = TRUE;
                            print $out "// COMMENTED OUT BY AZURE APP SERVICE MIGRATION TOOL: $line";
                        }
                        
                        $openBracket = TRUE;                            
                    }

                    if ($openBracket)
                    {
                        print $out "// COMMENTED OUT BY AZURE APP SERVICE MIGRATION TOOL: $line";
                    }
                    else
                    {
                        print $out $line;
                    }
                    
                    if ($openBracket && $line =~ ';')
                    {
                        $openBracket = FALSE;
                    }
                }

                close $fh;
                close $out;
                if (!$settingsInserted)
                {
                    # delete the file
                    unlink $outFile;
                }
                
                # delete the _copy file
                unlink $phpFile;
            }
            
            @files = File::Find::Rule->file()
                ->name("*.php")
                ->extras({ follow => 1 })
                ->in("$workingFolder/wwwroot");
            if (@files > 0)
            {
                &deployToSite($publishUrl, "$workingFolder/wwwroot", $userName, $userPWD, TRUE);
            }                
            my $returnCode = -1;
            my $database;
            my $password;
            # DUMP MYSQL
            my $retries = 0;
            while($returnCode != 0 && $retries < 5)
            {
                ilog_print(1,"\nBacking up database on: $dbHost...\n");
                if ($DEBUG_MODE) { ilog_print(1,"\nmysqldump --single-transaction -h $dbHost -u $dbUser -p'$dbPassword' $dbName > $workingFolder/mysqldump.sql\n"); }
                `mysqldump --single-transaction -h $dbHost -u $dbUser -p'$dbPassword' $dbName > $workingFolder/mysqldump.sql`;

                $returnCode = $?;
                $retries++;
                if ($returnCode != 0 && $retries < 5)
                {
                    ilog_print(1,"\nreturncode: $returnCode\n");
                    sleep 1;
                }
            }

            # RESTORE SQL
            ilog_print(1,"\nMoving database...\n");
            `mysql -u $rUsername -h $rServer -p'$rPassword' $rDatabase < $workingFolder/mysqldump.sql`;
            $returnCode = $?;
            if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: returncode: $returnCode\n"); }
            if ($returnCode != 0)
            {
                ilog_print(1,"\n\nPublishing failed with return code: $returnCode\n");                
                $strYesOrNo =" ";
                while($strYesOrNo!~/^\s*[YynN]\s*$/)
                {
                    ilog_printf(1, "    Would you like to retry publishing the database for site [$strSiteName]? (Y/N):");
                    chomp($strYesOrNo = <STDIN>);
                    ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO)
                        if ($strYesOrNo!~/^\s*[YynN]\s*$/);
                }
                
                $publishSuccess = $strYesOrNo =~ /^\s*[Nn]\s*$/;
            }
            else
            {
                $publishSuccess = TRUE;
                &updateTrackingStatus($strSiteName, TRUE);
            }
        }
        else 
        {
            # No database to publish
            $publishSuccess = TRUE;
        }
    }
}

sub getConfigFiles
{
    my $documentRoot = $_[0];
    my $lineMatch = $_[1];
    my $lineNotMatch = $_[2];
    my $workingFolder = $_[3];
    my @files = @{$_[4]};    
    for my $phpFile (@files)
    {
        open my $fh, '<', $phpFile or die "Failed to open $_: $!";
        my $filecopied = FALSE;
        while (my $line = <$fh>)
        {
            if ($line =~ $lineMatch && ($lineNotMatch eq "" || $line !~ $lineNotMatch) && !$filecopied)
            {
                # resolve symlinks
                my $documentRoot2 = quotemeta($documentRoot);
                # if the file is not under the document root, move it so it is.
                if ($phpFile !~ /$documentRoot2/)
                {
                    my $baseFile = basename($phpFile);
                    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Relocating phpFile: $phpFile (basename: $baseFile | documentRoot: $documentRoot)\n"); }
                    # if it is not under documentRoot, try to locate it under document root.
                    my @docrootfiles = File::Find::Rule->file()
                        ->name($baseFile)
                        ->extras({ follow => 1 })
                        ->in($documentRoot);
                    
                    if (@docrootfiles > 0)
                    {
                        my $file0 = $docrootfiles[0];                                                
                        $phpFile = $file0;
                    }
                    # BUGBUG: what if there is more than one file under the document root?
                    # BUGBUG: what if it cannot be located under the document root?
                }

                my $newName = $phpFile;
                $newName =~ s/$documentRoot2//g;
                $newName =~ s/^\///g;
                my $abPath = abs_path($phpFile);
                my $dest = "$workingFolder/wwwroot/${newName}_copy";
                my $destdirname  = dirname($dest);
                if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Copying phpFile: From: $abPath | To: $dest\n"); }
                if (! -d $destdirname)
                {
                    my $dirs = eval { mkpath($destdirname) };
                    die "Failed to create $destdirname: $@\n" unless $dirs;
                }

                File::Copy::copy($abPath, $dest) or die "Failed to copy $abPath: $!\n";
                $filecopied = TRUE;
            }
        }
    }
}

sub updateTrackingStatus
{
    my $strSiteName = shift;
    my $dbStatus = shift;
    # Update tracking status
    # DB status API
    # https://www.movemetothecloud.net + /api/dbmigration/{0}/sitename/{1}/
    # 0 = Migration ID, 1 = server + _x-colon_ +  sitename
    my $rComputername = `hostname`;
    $rComputername =~ s/\n//g;
    my $login = getlogin || getpwuid($<) || "Kilroy";
    my $guid = &genGUID($rComputername.$login);
    my $statusType = 'sitemigration';
    if ($dbStatus)
    {
        $statusType = 'dbmigration';
    }

    my $escapedName = "${rComputername}:${strSiteName}";
    $escapedName =~ s/:/_x-colon_/g;
    $escapedName =~ s/\*/_x-ast_/g;
    $escapedName =~ s/!/_x-bang_/g;
    use URI;
    my $uri = URI->new( "${SITE_URL}/api/${statusType}/${guid}/sitename/${escapedName}/" );
    my $baseAddress = $uri;
    # PUT at URL
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new("PUT", $baseAddress);
    $req->header( 'Content-Type' => 'application/json' );
    $req->header( 'Content-Length' => '0' );                
    my $res = $ua->request($req);
    my $rContent = $res->content;
    my $rCode = $res->code;
    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Update status response code: $rCode\n"); }
    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Update status result\n: $rContent\n"); }    
}

# Returns HTTP response code
sub deployToSite
{
    my $publishUrl = shift;
    my $itemToAdd = shift;
    my $userName = shift;
    my $userPWD = shift;
    my $isDirectory = shift;

    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: Deploying file to site: (publishUrl: $publishUrl | itemToAdd: $itemToAdd | userName: $userName | userPWD: $userPWD | isDirectory: $isDirectory)\n"); }
    # zip up folder
    # Create a Zip file    
    my $zip = Archive::Zip->new();
    if ($isDirectory)
    {        
        # Add a directory
        # NOTE: Archive::Zip addTree does not follow sym links so we have to modify it a bit
        $zip->addTree($itemToAdd, '');
        my @subdirs = File::Find::Rule->extras({ follow => 1 })->directory->in( $itemToAdd );
        foreach my $subdir (@subdirs)
        {
            if (-l $subdir)
            {
                my $relSubdir = $subdir;
                my $itemToAdd2 = quotemeta $itemToAdd;
                $relSubdir =~ s/$itemToAdd//g;
                $relSubdir =~ s/^\///g; # remove initial /
                my $abpath = abs_path($subdir);
                $zip->addTree($abpath, $relSubdir);
            }
        }
    }
    else
    {
        # split the path to get the filename and directory name                
        my $filename = basename($itemToAdd);
        ilog_print(1,"Adding filename to Zip: $filename || itemToAdd: $itemToAdd");
        # Add a file
        $zip->addFile($itemToAdd, $filename);
    }

    my $strCurWorkingFolder = &utf_getCurrentWorkingFolder();
    my $strSessionName = &ilog_getSessionName();
    my $workingFolder = $strCurWorkingFolder . '/' . $strSessionName;
    my $zipLocation = "$workingFolder/site-content.zip";
    if ( $zip->writeToFileNamed($zipLocation) != AZ_OK ) 
    {
        die "ZIP write error when writing $itemToAdd to $zipLocation";
    }
    
    my $ua = LWP::UserAgent->new;
    my $publishUrlFull = "https://".$publishUrl."/api/zip/site/wwwroot/";
    my $filesize = -s $zipLocation;
    open my $fileZip, $zipLocation or die "UNABLE TO OPEN $zipLocation";

    my $req = HTTP::Request->new("PUT", $publishUrlFull);
    $req->content_type('application/octet-stream');
    $req->content_length($filesize);
    $req->authorization_basic($userName, $userPWD);
    ilog_print(1,"Publishing site...");
    my $barWidth = 100;    
    my $chunksize = 65536;
    if ($filesize < $chunksize)
    {
        $filesize = $chunksize;
    }

    my $nChunks = $filesize / $chunksize;
    my $chunkWidth = $barWidth / $nChunks;
    ilog_print(1,"\n");
    my $nChunk = 0;
    my $readFunc = sub {        
        my $nBar = int($nChunk * $chunkWidth + 0.5);
        if ($nBar > $barWidth)
        {
            $nBar = $barWidth;
        }
        
        ilog_print(1,"[" . "=" x $nBar . " " x ($barWidth - $nBar) . "]\r");
        $nChunk++;
        read($fileZip, my $buf, $chunksize);
        return $buf;
    };

    $req->content( $readFunc );
    my $res = $ua->request($req);
    my $rContent = $res->content;
    my $rCode = $res->code;    
    ilog_print(1,"\n");
    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: content upload response code: $rCode\n"); }
    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: content upload result: $rContent\n"); }
    ilog_print(1,"\n$itemToAdd published with response code: $rCode\nTo site: $publishUrl");
    close $fileZip;
    return $rCode;
}

# Generate a GUID given a string
sub genGUID 
{
    my $seed = shift;
    my $md5 = uc md5_hex ($seed);
    my @octets = $md5 =~ /(.{2})/g;
    substr $octets[6], 0, 1, '4'; # GUID Version 4
    substr $octets[8], 0, 1, '8'; # draft-leach-uuids-guids-01.txt GUID variant 
    my $GUID = "{@octets[0..3]-@octets[4..5]-@octets[6..7]-@octets[8..9]-@octets[10..15]}";
    $GUID =~ s/ //g;
    $GUID =~ s/(\{|\})//g;
    return $GUID;
}

sub pars_GetFileFromSource
{
    #input arguments
    my ($strSourceFileName, $strTargetFileName,$ignoreErr) = @_;
    #local variables declaration
    my $retGet = 0;
    $retGet = File::Copy::copy($strSourceFileName,$strTargetFileName);
    if (!$retGet ) #failure 
    {
        ilog_displayandLog(1, "FILE TRANSFER FAILED: source: $strSourceFileName , target: $strTargetFileName")  
            if (!$ignoreErr);
        return $retGet;
    }
    else #success
    {
        return $retGet;
    }
}

## original
sub pars_Generate2D
{   
    utf_setCurrentModuleName('PARSER');
    ilog_print(1,"\n\nParsing Apache conf file(s)... ");
    ($configFile,$ResourceFile) = @_;

    eval
    {
        open CONFIGHANDLE ,$configFile or die 'ERR_FILE_OPEN';
        binmode(CONFIGHANDLE);
        pars_ReadServerBindings($ResourceFile);        
    };

    if($@)
    {
        if($@=~/ERR_FILE_OPEN/)
        {
            # log error and exit tool           
            ilog_setLogInformation('INT_ERROR',$configFile,ERR_FILE_OPEN,__LINE__);     
            return FALSE;                                                           
        }   
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$configFile,MSG_FILE_OPEN,'');
    }

    # Fill the Server Config array initially with the documented default values.
    $array[0][SITENAME] = "Default Web Site";
    $array[0][KEEPALIVE] = "on";
    $array[0][KEEPALIVETIMEOUT] = 15;
    $array[0][LISTENBACKLOG] = 511;
    $array[0][MAXCLIENTS] = 256;
    $array[0][PORT] = 80;
    $array[0][RESOURCECONFIG] = "conf/srm.conf";
    $array[0][SERVERROOT] = "/usr/local/apache/";
    $array[0][USERDIR] = "public_html";
    $array[0][ACCESSCONFIG] = "conf/access.conf";
    $array[0][ACCESSFILENAME] = ".htaccess";
    $array[0][BINDADDRESS] = "*";
    $array[0][DEFAULTTYPE] = "text/plain";
    if (-e ("/usr/local/apache/htdocs"))
    {
        # old style apache
        $array[0][DOCUMENTROOT] = "/usr/local/apache/htdocs";
    }
    else
    {
        $array[0][DOCUMENTROOT] = "/var/www";
    }

    $array[0][HOSTNAMELOOKUPS] = "off";
    $array[0][IDENTITYCHECK] = "off";
    $array[0][DIRECTORYINDEX] = "index.html";
    $array[0][ERRORLOG] = "logs/error_log"; 
    $array[0][SSLENGINE] = "off";
    $array[0][USERENABLED] = 1;
    $array[0][USERDISABLED] = 1;
    $array[0][OPTIONS] = "All";
    # Get the path of the default site
    &pars_defaultsitePath();
    $array[0][DESTINATIONPATH] = $defaultPath;
    $array[0][DESTINATIONPATH] =~ s/\\$//;
    while (&pars_getNextDirective() == 1)
    {
        if($directiveName eq "VirtualHost")
        {
            my @splitPorts = split(':', $directiveValue);
            $portValue = $splitPorts[1];
            my $serverName = "EMPTY";
            my $lineContent;
            my $temp = $directiveValue;
            my $filepos;    
            $filepos = tell CONFIGHANDLE;           
            eval
            {
                open VIRTUALHOSTPTR ,$configFile   or die 'ERR_FILE_OPEN';
                binmode(VIRTUALHOSTPTR);
                
            };

            if($@)
            {
                if($@=~/ERR_FILE_OPEN/)
                {
                    # log error and exit tool                   
                    ilog_setLogInformation('INT_ERROR',$configFile,ERR_FILE_OPEN,__LINE__);     
                    return FALSE;                                                           
                }   
            }
            else
            {
                seek VIRTUALHOSTPTR ,$filepos, 0;
                ilog_setLogInformation('INT_INFO',$configFile,MSG_FILE_OPEN,'');
            }
            
            while ($lineContent = <VIRTUALHOSTPTR>) 
            {
                chomp($lineContent);
                $lineContent =~ s/^\s+//;
                if($lineContent ne "")
                {
                    if($lineContent !~ /^#/)
                    {                       
                        @Tmp = split / /,$lineContent;
                        $directiveName  = $Tmp[0]; 
                        $directiveValue = '';
                        foreach $temp (@Tmp) 
                        {
                            if($temp ne $directiveName)
                            {
                                $directiveValue = $directiveValue ." " . $temp;
                            }
                        }

                        $directiveValue =~ s/^\s+//m;
                        $directiveValue =~ s/\s+$//m;
                        $directiveValue =~ s/^"//;
                        $directiveValue =~ s/"$//;
                        chomp($directiveValue);
                        chomp($directiveName);
                        if($directiveName =~ "</VirtualHost>")
                        {
                            last;
                        }

                        if($directiveName eq "ServerName")
                        {
                            $serverName = $directiveValue;
                        }
                    }
                }
            }

            if($serverName eq "EMPTY")  
            {
                $serverName = "Site On $temp";
            }

            eval
            {
                close VIRTUALHOSTPTR or die 'ERR_FILE_CLOSE';
            };

            if($@)
            {
                if($@=~/ERR_FILE_CLOSE/)
                {
                    # log 'file close error' and continue
                    ilog_setLogInformation('INT_ERROR',$configFile,ERR_FILE_CLOSE,__LINE__);
                }   
            }
            else
            {
                ilog_setLogInformation('INT_INFO',$configFile,MSG_FILE_CLOSE,'');
            }

            $siteName = $serverName;
            # ADRIANG: CHANGE SITE SELECTED FLOW:
            # if(&pars_siteSelected($serverName))
            # {
                if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: processing selected site: $serverName\n"); }
                &pars_setVirtualhost();             
            # }
            # else
            # {
            #     while ($lineContent = <CONFIGHANDLE>)
            #     {
            #         chomp($lineContent);
            #         $lineContent =~ s/^\s+//;
            #         $lineContent =~ s/\s+$//;
            #         if($lineContent =~ /^<\/VirtualHost>/)
            #         {
            #             last;
            #         }
            #     }
            # }
        }
        else
        {           
            # Populate the Default site settings in the 2D array
            &pars_setDefaultsite();
        }
    }

    if($errorFlag)
    {
        $array[0][ERRORLOG] = $array[0][SERVERROOT] . $array[0][ERRORLOG];
    }

    if($resourceFlag)
    {
        $array[0][RESOURCECONFIG] = $array[0][SERVERROOT] . $array[0][RESOURCECONFIG];
    }

    if($accessFlag)
    {
        $array[0][ACCESSCONFIG] = $array[0][SERVERROOT] . $array[0][ACCESSCONFIG];
    }

    if($mimeFlag)
    {
        if (-e ($array[0][SERVERROOT]."conf/mime.types"))
        {
            # old style apache location
            $mimeTypes = pars_GetMimeTypes($array[0][SERVERROOT]."conf/mime.types");
        }
        elsif (-e ($array[0][SERVERROOT]."mods-enabled/mime.conf"))
        {
            $mimeTypes = pars_GetMimeTypes($array[0][SERVERROOT]."mods-enabled/mime.conf");
        }
        else
        {
            $mimeTypes = pars_GetMimeTypes("/etc/mime.types");
        }
    }

    my $start = 0;
    if(&pars_siteSelected("Default Web Site"))
    {
        $start = 0;
    }
    else
    {
        $start = 1;
    }
    
    &pars_IPSelected();
    chomp($ipAddress);
    $array[0][LISTEN] = $ipAddress;
    # Start processing for Htaccess directive
    &pars_setHtaccess();
    my $o = 0;
    my $p = 0;
    my $continue = 1;    
    # directory parsing, is this needed?
    # for($p = $start;$p <=$rowCount; $p++)
    # {
    #     $continue = 1;
    #     for($o = 0; $o <= $rowDirCount; $o++)
    #     {   
    #         if($array[$p][SITENAME] eq $arrayDir[$o][SITENAME])
    #         {
    #             if($array[$p][DOCUMENTROOT] eq $arrayDir[$o][DIRECTORY])
    #             {
    #                 $continue = 0;
    #                 $o = $rowDirCount;
    #                 $o++;
    #             }
    #         }                   
    #     }

    #     if($continue)
    #     {
    #         ++$rowDirCount;
    #         $arrayDir[$rowDirCount][SITENAME] = $array[$p][SITENAME];
    #         $arrayDir[$rowDirCount][DESTINATIONPATH] = $array[$p][DESTINATIONPATH];
    #         $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\\/\//g;
    #         $arrayDir[$rowDirCount][DIRECTORY] = $array[$p][DOCUMENTROOT];
    #         $arrayDir[$rowDirCount][DOCUMENTROOT] = $array[$p][DOCUMENTROOT];
    #         $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "Off";
    #         $arrayDir[$rowDirCount][IDENTITYCHECK] = "Off";
    #         $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
    #         $arrayDir[$rowDirCount][ACCESSFILENAME] = $array[$p][ACCESSFILENAME];
    #         $arrayDir[$rowDirCount][DEFAULTTYPE] = "text/plain";
    #         $continue = 1;  
    #     }
    # }
    # Start processing for Userdir directive
    # &pars_setUserdir();
    # Generate The Local user file to be used by the work items target module to create local users on the target box.
    #&pars_createLocaluserFile();
    # Create the Config.XML reading appropriate values from the 2d array. configxml
    # &pars_createXML();
    ## Generate The Task List file to be used by the work items source module for File transfer.
    # &pars_createTasklistFile();
    # Display the 2-Dimensional array corresponding to the site content.
    # &pars_printArraysite();
    # Display the 2-Dimensional array corresponding to the Directory content.
    # &pars_printArraydir();    
    # if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: GEN2D last index of array is: $#array"); }
    # this has the side effect of calling pars_siteHasValidFrameworkDb
    # which populates the global variable $array MYSQL, FRAMEWORK, and CONFIGFILE entries
    &pars_CreateReadinessReport();
    &pars_UploadPublishSettingsAllSites();
    return 1;
}

sub pars_common2d
{
    # To ignore the IfDefine directive.
    if($directiveName eq "IfDefine")
    {
        while (&pars_getNextDirective() == 1)
        {
            if($directiveName eq "/IfDefine")
            {
                last;
            }
        }
    }
    
    # To ignore the Location directive.
    if($directiveName eq "Location")
    {
        while (&pars_getNextDirective() == 1)
        {
            if($directiveName eq "/Location")
            {
                last;
            }
        }
    }
    
    # To ignore the LocationMatch directive.
    if($directiveName eq "LocationMatch")
    {
        while (&pars_getNextDirective() == 1)
        {
            if($directiveName eq "/LocationMatch")
            {
                last;
            }
        }
    }
    
    # To ignore the Limit directive.
    if($directiveName eq "Limit")
    {
        while (&pars_getNextDirective() == 1)
        {
            if($directiveName eq "/Limit")
            {
                last;
            }
        }
    }
    
    # To ignore the LimitExcept directive.
    if($directiveName eq "LimitExcept")
    {
        while (&pars_getNextDirective() == 1)
        {
            if($directiveName eq "/LimitExcept")
            {
                last;
            }
        }
    }
    
    if($directiveName eq "AccessConfig")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if($directiveValue =~ /^\//)
        {
            $array[$rowCount][ACCESSCONFIG] = $directiveValue;
            $accessFlag = 0;
        }
        else
        {
            if($array[$rowCount][SERVERROOT] =~ /\/$/)
            {
                $array[$rowCount][ACCESSCONFIG] = $array[$rowCount][SERVERROOT] . $directiveValue;
                $accessFlag = 0;
            }
            else
            {
                
                $array[$rowCount][ACCESSCONFIG] = $array[$rowCount][SERVERROOT] . "/" .$directiveValue;
                $accessFlag = 0;
            }
        }
        if($array[$rowCount][ACCESSCONFIG] eq "/dev/null")
        {                
            #Ignore this directive.
        }
        else
        {
            my $includeFilename = $array[$rowCount][ACCESSCONFIG];
            $includeFilename =~ s/\//_/g;
            $filepos = tell CONFIGHANDLE;
            push(@includeFilePointer,$filepos);
            push(@includeFileName,$configFile);
            $flag = 1;
            my $temp = &pars_GetSessionFolder() . $includeFilename;
            eval
            {
                close CONFIGHANDLE or die 'ERR_FILE_CLOSE';
                
            };
            if($@)
            {
                if($@=~/ERR_FILE_CLOSE/)
                {
                    # log 'file close error' and continue                       
                    ilog_setLogInformation('INT_ERROR',$configFile,ERR_FILE_CLOSE,__LINE__);                        
                }                    
            }
            else
            {
                ilog_setLogInformation('INT_INFO',$configFile,MSG_FILE_CLOSE,'');
            }
            eval
            {
                open CONFIGHANDLE ,$temp or die 'ERR_FILE_OPEN';                    
            };
            if($@)  
            {
                if($@=~/ERR_FILE_OPEN/)
                {   
                    # log error and exit tool                       
                    ilog_setLogInformation('INT_ERROR',$temp,ERR_FILE_OPEN,__LINE__);       
                    return FALSE;                        
                }
            }
            else
            {
                ilog_setLogInformation('INT_INFO',$temp,MSG_FILE_OPEN,'');
            }
        }
    }
    
    if($directiveName eq "ResourceConfig")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if($directiveValue =~ /^\//)
        {
            $array[$rowCount][RESOURCECONFIG] = $directiveValue;
            $resourceFlag = 0;
        }
        else
        {
            if($array[$rowCount][SERVERROOT] =~ /\/$/)
            {
                $array[$rowCount][RESOURCECONFIG] = $array[$rowCount][SERVERROOT] . $directiveValue;
                $resourceFlag = 0;
            }
            else
            {                   
                $array[$rowCount][RESOURCECONFIG] = $array[$rowCount][SERVERROOT] . "/" .$directiveValue;
                $resourceFlag = 0;
            }
        }
        if($array[$rowCount][RESOURCECONFIG] eq "/dev/null")
        {                
            #Ignore this directive.
        }
        else
        {
            my $includeFilename = $array[$rowCount][RESOURCECONFIG];
            $includeFilename =~ s/\//_/g;
            $filepos = tell CONFIGHANDLE;
            push(@includeFilePointer,$filepos);
            push(@includeFileName,$configFile);
            $flag = 1;
            my $temp = &pars_GetSessionFolder() . $includeFilename;
            eval
            {
                close CONFIGHANDLE or die 'ERR_FILE_CLOSE';                 
            };
            if($@)
            {
                if($@=~/ERR_FILE_CLOSE/)
                {
                    # log 'file close error' and continue                       
                    ilog_setLogInformation('INT_ERROR',$configFile,ERR_FILE_CLOSE,__LINE__);                        
                }                    
            }
            else
            {
                ilog_setLogInformation('INT_INFO',$configFile,MSG_FILE_CLOSE,'');
            }
            eval
            {
                open CONFIGHANDLE ,$temp or die 'ERR_FILE_OPEN';
                
            };
            if($@)  
            {
                if($@=~/ERR_FILE_OPEN/)
                {   
                    # log error and exit tool                       
                    ilog_setLogInformation('INT_ERROR',$temp,ERR_FILE_OPEN,__LINE__);       
                    return FALSE;                        
                }
            }
            else
            {
                ilog_setLogInformation('INT_INFO',$temp,MSG_FILE_OPEN,'');
            }
        }
    }
    
    if($directiveName eq "ScriptAlias")
    {
        #Equivalent IIS tag => Not applicable
        my @tempt;
        my $temp;
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if($directiveValue !~ /\"/)
        {                
            @tempt = split / /,$directiveValue;
            $tempt[0] =~ s/^\s+//;
            $tempt[0] =~ s/\s+$//;
            $tempt[1] =~ s/^\s+//;
            $tempt[1] =~ s/\s+$//;
            $array[$rowCount][SCRIPTALIAS] = $array[$rowCount][SCRIPTALIAS] . $tempt[0] . TASKLIST_DELIM . $tempt[1] . TASKLIST_DELIM;                
        }
        else
        {                
            @tempt = split /\"/,$directiveValue;    
            $tempt[0] =~ s/^\s+//;
            $tempt[0] =~ s/\s+$//;
            $tempt[1] =~ s/^\s+//;
            $tempt[1] =~ s/\s+$//;
            $array[$rowCount][SCRIPTALIAS] = $array[$rowCount][SCRIPTALIAS] . $tempt[0] . TASKLIST_DELIM . $tempt[1] . TASKLIST_DELIM;                
        }
        $temp = $tempt[0];
        $temp =~ s/^\///;
        $temp =~ s/\/$//;
        if(pars_ValidateAliasName($temp))
        {
            ++$scriptaliasDirInd;
            $scriptaliasDir[$scriptaliasDirInd][0] = $array[$rowCount][SITENAME]; 
            $scriptaliasDir[$scriptaliasDirInd][1] = $tempt[1];
            $scriptaliasDir[$scriptaliasDirInd][1] =~ s/\/$//;
            $scriptaliasDir[$scriptaliasDirInd][2] = 1;
            $scriptaliasDir[$scriptaliasDirInd][3] = $tempt[0];
        }
        else
        {   
            ilog_setLogInformation('INT_ERROR',,ERR_VIRTUAL_LINK,__LINE__);
        }
    }
    if($directiveName eq "ScriptAliasMatch")
    {
        #Equivalent IIS tag => Not applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $directiveValue =~ s/"//g;
        $array[$rowCount][SCRIPTALIASMATCH] = $array[$rowCount][SCRIPTALIASMATCH] . $directiveValue . " ";
    }
    
    if($directiveName eq "AccessFileName")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][ACCESSFILENAME] = $directiveValue;
    }
    if($directiveName eq "AddEncoding")
    {
        #Equivalent IIS tag => MimeMap
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][ADDENCODING] = $array[$rowCount][ADDENCODING] . $directiveValue . "|";
    }
    if($directiveName eq "AddType")
    {
        #Equivalent IIS tag => MimeMap
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][ADDTYPE] = $array[$rowCount][ADDTYPE] . $directiveValue . "|";
    }
    if($directiveName eq "Alias")
    {
        #Equivalent IIS tag => Not Applicable
        my @tempt;  
        my $temp;
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if($directiveValue !~ /\"/)
        {                
            @tempt = split / /,$directiveValue;
            $tempt[0] =~ s/^\s+//;
            $tempt[0] =~ s/\s+$//;
            $tempt[1] =~ s/^\s+//;
            $tempt[1] =~ s/\s+$//;
            $array[$rowCount][ALIAS] = $array[$rowCount][ALIAS] . $tempt[0] . TASKLIST_DELIM . $tempt[1] . TASKLIST_DELIM;              
        }
        else
        {                
            @tempt = split /\"/,$directiveValue;    
            $tempt[0] =~ s/^\s+//;
            $tempt[0] =~ s/\s+$//;
            $tempt[1] =~ s/^\s+//;
            $tempt[1] =~ s/\s+$//;
            $array[$rowCount][ALIAS] = $array[$rowCount][ALIAS] . $tempt[0] . TASKLIST_DELIM . $tempt[1] . TASKLIST_DELIM;              
        }
    
        $temp = $tempt[0];
        $temp =~ s/^\///;
        $temp =~ s/\/$//;            
        if(pars_ValidateAliasName($temp))
        {
            ++$aliasDirInd;
            $aliasDir[$aliasDirInd][0] = $array[$rowCount][SITENAME]; 
            $aliasDir[$aliasDirInd][1] = $tempt[1];
            $aliasDir[$aliasDirInd][1] =~ s/\/$//;
            $aliasDir[$aliasDirInd][2] = 1;
            $aliasDir[$aliasDirInd][3] = $tempt[0];
        }
        else
        {   
            ilog_setLogInformation('INT_ERROR',,ERR_VIRTUAL_LINK,__LINE__);
        }
    }
    if($directiveName eq "AliasMatch")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $directiveValue =~ s/"//g;
        $array[$rowCount][ALIASMATCH] = $array[$rowCount][ALIASMATCH] . $directiveValue . " ";
        
    }
    if($directiveName eq "DefaultType")
    {
        #Equivalent IIS tag => MimeMap
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        
        my $temp = $directiveValue . " " . ".*";
        $array[$rowCount][ADDTYPE] = $array[$rowCount][ADDTYPE] . $temp . "|";            
    }
    if($directiveName eq "DirectoryIndex")
    {
        #Equivalent IIS tag => EnableDirBrowsing;
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][DIRECTORYINDEX] = $directiveValue;
        $array[$rowCount][DIRECTORYINDEX] =~ s/ /,/g;
    }
    if($directiveName eq "DocumentRoot")
    {
        #Equivalent IIS tag => Path
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][DOCUMENTROOT] = $directiveValue;
    }
    if($directiveName eq "ErrorDocument")
    {
        #Equivalent IIS tag => HttpErrors
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][ERRORDOCUMENT] = $array[$rowCount][ERRORDOCUMENT] . $directiveValue . " ";
    }
    if($directiveName eq "ErrorLog")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if($directiveValue =~ /^\|/)
        {               
            # The Error Logging for this Site is performed by an external program
            # So ignore this Directive.                
        }
        else
        {
            #Equivalent IIS tag => Not applicable
            if($directiveValue =~ /^\//)
            {
                # The Error Log path is an absolute so can be used directly.
                $array[$rowCount][ERRORLOG] = $directiveValue;
                $errorFlag = 0;
            }
            else
            {
                # The Error Log is relative so have to append the Server root to get an absolute path.                    
                if($array[0][SERVERROOT] =~ /\/$/)
                {
                    $array[$rowCount][ERRORLOG] = $array[$rowCount][SERVERROOT] . $directiveValue;
                    $errorFlag = 0;
                }
                else
                {
                    $array[$rowCount][ERRORLOG] = $array[$rowCount][SERVERROOT] . "/" .$directiveValue;
                    $errorFlag = 0;
                }
            }
        }
    }
    if($directiveName eq "ExpiresActive")
    {
        #Equivalent IIS tag => HttpExpires
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][EXPIRESACTIVE] = $directiveValue;
    }
    if($directiveName eq "Header")
    {
        #Equivalent IIS tag => HttpCustomHeaders
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $directiveValue =~ s/"//g;
        if($directiveValue =~ /^set/)
        {
            $array[$rowCount][HEADER] = $array[$rowCount][HEADER] . $directiveValue . "|" ;
        }            
    }
    if($directiveName eq "HostnameLookups")
    {
        #Equivalent IIS tag => EnableReverseDNS
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][HOSTNAMELOOKUPS] = $directiveValue;
    }
    if($directiveName eq "IdentityCheck")
    {
        #Equivalent IIS tag => LogExtFileUserName
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][IDENTITYCHECK] = $directiveValue;
    }
    if($directiveName eq "SSLEngine")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[$rowCount][SSLENGINE] = $directiveValue;
    }
    if($directiveName eq "SSLCertificateFile")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if($directiveValue =~ /^\//)
        {
            $array[$rowCount][SSLCERTIFICATEFILE] = $directiveValue;
        }
        else
        {
            
            $array[$rowCount][SSLCERTIFICATEFILE] = $array[$rowCount][SERVERROOT] . $directiveValue;
        }
    }
    if($directiveName eq "SSLCertificateKeyFile")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if($directiveValue =~ /^\//)
        {
            $array[$rowCount][SSLCERTIFICATEKEYFILE] = $directiveValue;
        }
        else
        {               
            $array[$rowCount][SSLCERTIFICATEKEYFILE] = $array[$rowCount][SERVERROOT] . $directiveValue;
        }
    }
    if($directiveName eq "UserDir")
    {           
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if (!$virtUserdir)
        {
            my @directiveValuetemp; 
            if($directiveValue =~ /^enabled/)
            {                   
                @directiveValuetemp = split / /,$directiveValue;
                foreach $temp(@directiveValuetemp)
                {
                    if($temp eq "enabled")
                    {
                        $array[$rowCount][USERENABLED] = 0;
                    }
                    else
                    {
                        $array[$rowCount][USERDIRENABLED] = $array[$rowCount][USERDIRENABLED] . " " . $temp;
                    }
                }
            }
            elsif($directiveValue =~ /^disabled/)
            {
                @directiveValuetemp = split / /,$directiveValue;
                foreach $temp(@directiveValuetemp)
                {
                    if($temp eq "disabled")
                    {
                        $array[$rowCount][USERDISABLED] = 0;
                    }
                    else
                    {
                        $array[$rowCount][USERDIRDISABLED] = $array[$rowCount][USERDIRDISABLED] . " " . $temp;
                    }
                }
            }
            else
            {
                $array[$rowCount][USERDIR] = $directiveValue;
                ++$virtUserdir;
            }
        }
        else
        {
            my @directiveValuetemp; 
            if($directiveValue =~ /^enabled/)
            {                   
                @directiveValuetemp = split / /,$directiveValue;
                foreach $temp(@directiveValuetemp)
                {
                    if($temp eq "enabled")
                    {
                        $array[$rowCount][USERENABLED] = 0;
                    }
                    else
                    {
                        $array[$rowCount][USERDIRENABLED] = $array[$rowCount][USERDIRENABLED] . " " . $temp;
                    }
                }
                ++$virtUserdir;
            }
            elsif($directiveValue =~ /^disabled/)
            {
                @directiveValuetemp = split / /,$directiveValue;
                
                foreach $temp(@directiveValuetemp)
                {
                    if($temp eq "disabled")
                    {
                        $array[$rowCount][USERDISABLED] = 0;
                    }
                    else
                    {
                        $array[$rowCount][USERDIRDISABLED] = $array[$rowCount][USERDIRDISABLED] . " " . $temp;
                    }
                }
                ++$virtUserdir;
            }
            else
            {
                $array[$rowCount][USERDIR] = $array[$rowCount][USERDIR] . " " . $directiveValue;    
                ++$virtUserdir;
            }
        }
    }
    if($directiveName eq "Directory")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if($directiveValue =~ /^~/)
        {
            $dirMatch = 1;
            my @temp;
            @temp = split / /,$directiveValue;
            $directiveName = "DirectoryMatch";
            $directiveValue = $temp[1];
            
            chomp($directiveValue);
            $directiveValue =~ s/"//g;
            $directiveValue =~ s/^\s+//;
            $directiveValue =~ s/\s+$//;
        }
        elsif($directiveValue =~ /\*/)
        {
            $dirMatch = 1;
            $directiveName = "DirectoryMatch";
            chomp($directiveValue);
            $directiveValue =~ s/"//g;
            $directiveValue =~ s/^\s+//;
            $directiveValue =~ s/\s+$//;
        }
        else
        {
            if($directiveValue ne "/")
            {
                if($directiveValue =~ /^\//)
                {
                    ++$rowDirCount;
                    $arrayDir[$rowDirCount][SERVERROOT] = "/usr/local/apache/";
                    $arrayDir[$rowDirCount][SITENAME] = $array[$rowCount][SITENAME];
                    $arrayDir[$rowDirCount][DIRECTORY] = $directiveValue;
                    $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "Off";
                    $arrayDir[$rowDirCount][IDENTITYCHECK] = "Off";
                    $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
                    $arrayDir[$rowDirCount][ACCESSFILENAME] = $array[$rowCount][ACCESSFILENAME];
                    $arrayDir[$rowDirCount][DESTINATIONPATH] = $array[$rowCount][DESTINATIONPATH];
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\\/\//g;
                    $arrayDir[$rowDirCount][DOCUMENTROOT] = $array[$rowCount][DOCUMENTROOT];                
                    if (index($arrayDir[$rowDirCount][DIRECTORY],$array[$rowCount][DOCUMENTROOT]) != 0) 
                    {
                        $arrayDir[$rowDirCount][TASKLIST]  = 1;
                        $arrayDir[$rowDirCount][DESTINATIONPATH] = $arrayDir[$rowDirCount][DESTINATIONPATH] . $arrayDir[$rowDirCount][DIRECTORY];                            
                    }
                    else
                    {                            
                        my $temp;
                        $temp = pars_getRelativePath($arrayDir[$rowDirCount][DIRECTORY],$array[$rowCount][DOCUMENTROOT]);
                        $arrayDir[$rowDirCount][DESTINATIONPATH] = $arrayDir[$rowDirCount][DESTINATIONPATH] . $temp; 
                    }
                    if($arrayDir[$rowDirCount][DESTINATIONPATH] =~ /\/$/)
                    {
                        $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\/$//;
                    }                        
                    
                    while (&pars_getNextDirective() == 1)
                    {
                        if($directiveName eq "/Directory")
                        {
                            last;
                        }
    
                        # list of directives that are migrated by the tool but can't appear in the DIRECTORY context                            
                        # KeepAlive
                        # KeepAliveTimeout
                        # Listen
                        # ListenBacklog
                        # MaxClients
                        # NameVirtualHost
                        # Port
                        # ResourceConfig 
                        # ScriptAlias 
                        # ScriptAliasMatch
                        # ServerAlias 
                        # ServerName
                        # ServerRoot 
                        # TimeOut
                        # UserDir
                        # VirtualHost
                        # AcccessConfig
                        # AccessFileName
                        # Alias 
                        # AliasMatch
                        # BindAddess
                        # DirectoryMatch
                        # DocumentRoot
                        # ErrorLog
                        # Files
                        # FileMatch
                        # Header
                        if($directiveName eq "Options")
                        {
                            #Equivalent IIS tag => AccessExecute
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][OPTIONS] = $arrayDir[$rowDirCount][OPTIONS] . $directiveValue . " ";
                        }
                        if($directiveName eq "Order")
                        {
                            #Equivalent IIS tag => Not applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][ORDER] = $directiveValue;
                        }
                        if($directiveName eq "AddEncoding")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][ADDENCODING] = $arrayDir[$rowDirCount][ADDENCODING] . $directiveValue . "|";
                        }
                        if($directiveName eq "AddType")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][ADDTYPE] = $arrayDir[$rowDirCount][ADDTYPE] . $directiveValue . "|";
                        }
                        if($directiveName eq "AuthName")
                        {
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][AUTHNAME] = $directiveValue;
                        }
                        if($directiveName eq "AuthType")
                        {
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][AUTHTYPE] = $directiveValue;
                        }
                        if($directiveName eq "AuthUserFile")
                        {
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            if($directiveValue =~ /^\//)
                            {
                                $arrayDir[$rowDirCount][AUTHUSERFILE] = $directiveValue;
                            }
                            else
                            {
                                
                                $arrayDir[$rowDirCount][AUTHUSERFILE] = $arrayDir[$rowDirCount][SERVERROOT] . $directiveValue;
                            }
                        }
                        if($directiveName eq "AuthGroupFile")
                        {
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            if($directiveValue =~ /^\//)
                            {
                                $arrayDir[$rowDirCount][AUTHGROUPFILE] = $directiveValue;
                            }
                            else
                            {
                                
                                $arrayDir[$rowDirCount][AUTHGROUPFILE] = $arrayDir[$rowDirCount][SERVERROOT] . $directiveValue;
                            }
                        }
                        if($directiveName eq "DefaultType")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            my $temp = $directiveValue . " " . ".*";
                            $arrayDir[$rowDirCount][ADDTYPE] = $arrayDir[$rowDirCount][ADDTYPE] . $temp . "|";
                        }
                        if($directiveName eq "Deny")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][DENY] = $directiveValue;
                        }
                        
                        if($directiveName eq "DirectoryIndex")
                        {
                            #Equivalent IIS tag => EnableDirBrowsing;
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][DIRECTORYINDEX] = $directiveValue;
                            $arrayDir[$rowDirCount][DIRECTORYINDEX] =~ s/ /,/g;
                        }
                        if($directiveName eq "ErrorDocument")
                        {
                            #Equivalent IIS tag => HttpErrors
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][ERRORDOCUMENT] = $arrayDir[$rowDirCount][ERRORDOCUMENT] . $directiveValue . " ";
                        }
                        if($directiveName eq "ExpiresActive")
                        {
                            #Equivalent IIS tag => HttpExpires
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][EXPIRESACTIVE] = $directiveValue;
                        }
                        if($directiveName eq "HostnameLookups")
                        {
                            #Equivalent IIS tag => EnableReverseDNS
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = $directiveValue;
                        }
                        if($directiveName eq "IdentityCheck")
                        {
                            #Equivalent IIS tag => LogExtFileUserName
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][IDENTITYCHECK] = $directiveValue;
                        }
                        if($directiveName eq "AllowOverride")
                        {
                            #Equivalent IIS tag => Not Applicable.
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][ALLOWOVERRIDE] = $directiveValue;
                        }
                        if($directiveName eq "Header")
                        {
                            #Equivalent IIS tag => HttpCustomHeaders
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $directiveValue =~ s/"//g;
                            if($directiveValue =~ /^set/)
                            {
                                
                                $arrayDir[$rowDirCount][HEADER] = $arrayDir[$rowDirCount][HEADER] . $directiveValue . "|" ;
                            }
                        }
                        if($directiveName eq "Files")
                        {
                            my @fileTmp;
                            my $Dcide = 1;
                            if($arrayDir[$rowDirCount][ALLOWOVERRIDE] eq "All")
                            {                                
                                @fileTmp = ftp_checkFilePresence($arrayDir[$rowDirCount][DIRECTORY]);
                                foreach(@fileTmp)
                                {
                                    if($_ =~ /^total/)
                                    {                                            
                                        #Dont do anything                                            
                                    }
                                    elsif($_ =~ /^d/)
                                    {                                            
                                        #Dont do anything                                            
                                    }
                                    elsif($_ eq "")
                                    {                                            
                                        #Dont do anything                                            
                                    }
                                    else
                                    {
                                        my $fileName = pars_FileNameSet($_);
                                        if($fileName eq $arrayDir[$rowDirCount][ACCESSFILENAME])
                                        {
                                            $Dcide = 0;
                                            last;           
                                        }                                            
                                    }                                        
                                }
                            }
                            
                            if($Dcide)
                            {
                                
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                my $numPass;
                                $numPass  = 1;
                                if($directiveValue =~ /^~/)
                                {
                                    $fileMatch = 1;
                                    my @temp;
                                    @temp = split / /,$directiveValue;
                                    $directiveName = "FilesMatch";
                                    $directiveValue = $temp[1];
                                    
                                    chomp($directiveValue);
                                    $directiveValue =~ s/"//g;
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;                                        
                                }
                                else
                                {
                                    my @file;
                                    my $fileList;
                                    my @fileEntire;
                                    my $temp;
                                    my $counter = 0;
                                    my @Listing;
                                    my $singleEntry;
                                    my @fileEntire;
                                    my @filePath;
                                    my $singleEntry;
                                    my $count = 0;
                                    my $files;
                                    my @tempArray;
                                    @Listing = pars_GetDirlistinght("$arrayDir[$rowDirCount][DIRECTORY]");
                                    my $rootDir;
                                    $rootDir = $arrayDir[$rowDirCount][DIRECTORY];
                                    
                                    foreach $singleEntry (@Listing)
                                    {                                            
                                        if($singleEntry =~ /:$/)
                                        {
                                            #Dont do anything
                                            $singleEntry =~ s/:$//;
                                            $rootDir = $singleEntry;
                                            chomp($rootDir);                                                
                                        }
                                        elsif($singleEntry =~ /^total/)
                                        {                                                
                                            #Dont do anything                                               
                                        }
                                        elsif($singleEntry =~ /^d/)
                                        {                                                
                                            #Dont do anything                                               
                                        }
                                        elsif($singleEntry eq "")
                                        {                                                
                                            #Dont do anything                                               
                                        }
                                        else
                                        {
                                            $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                            $filePath[$count] = $rootDir;
                                            $count++;
                                        }
                                    }
                                    my $indI = 0;
                                    my $dirValue = $directiveValue;
                                    foreach $temp (@fileEntire)
                                    {
                                        $directiveValue =~ s/"//g;
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        
                                        if($temp eq $dirValue)
                                        {
                                            if($numPass)
                                            {
                                                $files = $temp;
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                ++$filecount;
                                                $files[$filecount][SITENAME] = $array[$rowCount][SITENAME];
                                                $files[$filecount][DOCUMENTROOT] = $array[$rowCount][DOCUMENTROOT];
                                                $files[$filecount][FILESMATCH] = $files;
                                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                                $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                                $files[$filecount][IDENTITYCHECK] = "Off";
                                                $files[$filecount][ALLOWOVERRIDE] = "All";
                                                while (&pars_getNextDirective() == 1)
                                                {
                                                    if($directiveName eq "/Files")
                                                    {
                                                        last;
                                                    }
                                                    if($directiveName eq "Options")
                                                    {
                                                        #Equivalent IIS tag => AccessExecute
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                                    }
                                                    if($directiveName eq "Order")
                                                    {
                                                        #Equivalent IIS tag => Not applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ORDER] = $directiveValue;
                                                    }
                                                    if($directiveName eq "AddEncoding")
                                                    {
                                                        #Equivalent IIS tag => MimeMap
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                                    }
                                                    if($directiveName eq "AddType")
                                                    {
                                                        #Equivalent IIS tag => MimeMap
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                                    }
                                                    if($directiveName eq "AuthName")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][AUTHNAME] = $directiveValue;
                                                    }
                                                    if($directiveName eq "AuthType")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][AUTHTYPE] = $directiveValue;
                                                    }
                                                    if($directiveName eq "AuthUserFile")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        if($directiveValue =~ /^\//)
                                                        {
                                                            $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                                        }
                                                        else
                                                        {                                                                
                                                            $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                                        }                                                            
                                                    }
                                                    if($directiveName eq "AuthGroupFile")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        if($directiveValue =~ /^\//)
                                                        {
                                                            $files[$filecount][AUTHGROUPFILE] = $directiveValue;                                                                
                                                        }
                                                        else
                                                        {                                                                
                                                            $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                                        }
                                                    }
                                                    if($directiveName eq "DefaultType")
                                                    {
                                                        #Equivalent IIS tag => MimeMap
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        
                                                        my $temp = $directiveValue . " " . ".*";
                                                        $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                                    }
                                                    if($directiveName eq "Deny")
                                                    {
                                                        #Equivalent IIS tag => MimeMap
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][DENY] = $directiveValue;
                                                    }
                                                    if($directiveName eq "DirectoryIndex")
                                                    {
                                                        #Equivalent IIS tag => EnableDirBrowsing;
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                                        $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                                    }
                                                    if($directiveName eq "ErrorDocument")
                                                    {
                                                        #Equivalent IIS tag => HttpErrors
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                                    }
                                                    if($directiveName eq "ExpiresActive")
                                                    {
                                                        #Equivalent IIS tag => HttpExpires
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                    }
                                                    if($directiveName eq "HostnameLookups")
                                                    {
                                                        #Equivalent IIS tag => EnableReverseDNS
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                                    }
                                                    if($directiveName eq "IdentityCheck")
                                                    {
                                                        #Equivalent IIS tag => LogExtFileUserName
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                                    }
                                                    if($directiveName eq "AllowOverride")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable.
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                                    }
                                                }
                                                $numPass = 0;
                                            }
                                            else
                                            {
                                                my $kk = 0;
                                                my $jj = 0;
                                                ++$filecount;
                                                
                                                for($kk = 0; $kk < $maxColumn;$kk++)
                                                {
                                                    $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                                }
                                                
                                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                            }
                                        }
                                        $indI++;
                                    }
                                }
                            }
                        }
                        if($directiveName eq "FilesMatch")
                        {
                            my @file;
                            my $fileList;
                            my @fileEntire;
                            my $temp;
                            my $counter = 0;
                            my @Listing;
                            my $singleEntry;
                            my @fileEntire;
                            my @filePath;
                            my $singleEntry;
                            my $count = 0;
                            my $files;
                            my @tempArray;
                            my $numPass = 1;
                            my $Dcide = 1;
                            my @fileTmp;
                            if($arrayDir[$rowDirCount][ALLOWOVERRIDE] eq "All")
                            {
                                @fileTmp = ftp_checkFilePresence($arrayDir[$rowDirCount][DIRECTORY]);
                                foreach(@fileTmp)
                                {
                                    if($_ =~ /^total/)
                                    {                                            
                                        #Dont do anything                                            
                                    }
                                    elsif($_ =~ /^d/)
                                    {                                            
                                        #Dont do anything                                            
                                    }
                                    elsif($_ eq "")
                                    {                                            
                                        #Dont do anything                                            
                                    }
                                    else
                                    {
                                        my $fileName = pars_FileNameSet($_);
                                        if($fileName eq $arrayDir[$rowDirCount][ACCESSFILENAME])
                                        {
                                            $Dcide = 0;
                                            last;
                                        }                                            
                                    }                                        
                                }
                            }
                            
                            if($Dcide)
                            {
                                @Listing = pars_GetDirlistinght("$arrayDir[$rowDirCount][DIRECTORY]");
                                my $rootDir;
                                $rootDir = $arrayDir[$rowDirCount][DIRECTORY];
                                foreach $singleEntry (@Listing)
                                {
                                    
                                    if($singleEntry =~ /:$/)
                                    {
                                        #Dont do anything
                                        $singleEntry =~ s/:$//;
                                        $rootDir = $singleEntry;
                                        chomp($rootDir);
                                        
                                    }
                                    elsif($singleEntry =~ /^total/)
                                    {                                            
                                        #Dont do anything                                           
                                    }
                                    elsif($singleEntry =~ /^d/)
                                    {                                            
                                        #Dont do anything                                           
                                    }
                                    elsif($singleEntry eq "")
                                    {                                            
                                        #Dont do anything                                           
                                    }
                                    else
                                    {
                                        $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                        $filePath[$count] = $rootDir;
                                        $count++;
                                    }
                                }
                                my $indI = 0;
                                my $dirValue = $directiveValue;
                                foreach $temp (@fileEntire)
                                {                                        
                                    $directiveValue =~ s/"//g;
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    
                                    if($temp =~ /$dirValue/)
                                    {
                                        if($numPass)
                                        {   
                                            $files = $temp;
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            ++$filecount;
                                            $files[$filecount][SITENAME] = $array[$rowCount][SITENAME];
                                            $files[$filecount][DOCUMENTROOT] = $array[$rowCount][DOCUMENTROOT];
                                            $files[$filecount][FILESMATCH] = $files;
                                            $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                            $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                            $files[$filecount][IDENTITYCHECK] = "Off";
                                            $files[$filecount][ALLOWOVERRIDE] = "All";
                                            while (&pars_getNextDirective() == 1)
                                            {
                                                if($directiveName eq "/FilesMatch")
                                                {
                                                    last;
                                                }
                                                if($fileMatch)
                                                {
                                                    if($directiveName eq "/Files")
                                                    {
                                                        
                                                        $fileMatch = 0;
                                                        last;
                                                    }
                                                }
                                                if($directiveName eq "Options")
                                                {
                                                    #Equivalent IIS tag => AccessExecute
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                                }
                                                if($directiveName eq "Order")
                                                {
                                                    #Equivalent IIS tag => Not applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ORDER] = $directiveValue;
                                                }
                                                if($directiveName eq "AddEncoding")
                                                {
                                                    #Equivalent IIS tag => MimeMap
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                                }
                                                if($directiveName eq "AddType")
                                                {
                                                    #Equivalent IIS tag => MimeMap
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                                }
                                                if($directiveName eq "AuthName")
                                                {
                                                    #Equivalent IIS tag => Not Applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][AUTHNAME] = $directiveValue;
                                                }
                                                if($directiveName eq "AuthType")
                                                {
                                                    #Equivalent IIS tag => Not Applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][AUTHTYPE] = $directiveValue;
                                                }
                                                if($directiveName eq "AuthUserFile")
                                                {
                                                    #Equivalent IIS tag => Not Applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    if($directiveValue =~ /^\//)
                                                    {
                                                        $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                                    }
                                                    else
                                                    {
                                                        
                                                        $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                                    }
                                                    
                                                }
                                                if($directiveName eq "AuthGroupFile")
                                                {
                                                    #Equivalent IIS tag => Not Applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    if($directiveValue =~ /^\//)
                                                    {
                                                        $files[$filecount][AUTHGROUPFILE] = $directiveValue;
                                                        
                                                    }
                                                    else
                                                    {
                                                        
                                                        $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                                    }
                                                }
                                                if($directiveName eq "DefaultType")
                                                {
                                                    #Equivalent IIS tag => MimeMap
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    
                                                    my $temp = $directiveValue . " " . ".*";
                                                    $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                                }
                                                if($directiveName eq "Deny")
                                                {
                                                    #Equivalent IIS tag => MimeMap
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][DENY] = $directiveValue;
                                                }
                                                if($directiveName eq "DirectoryIndex")
                                                {
                                                    #Equivalent IIS tag => EnableDirBrowsing;
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                                    $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                                }
                                                if($directiveName eq "ErrorDocument")
                                                {
                                                    #Equivalent IIS tag => HttpErrors
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                                }
                                                if($directiveName eq "ExpiresActive")
                                                {
                                                    #Equivalent IIS tag => HttpExpires
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                }
                                                if($directiveName eq "HostnameLookups")
                                                {
                                                    #Equivalent IIS tag => EnableReverseDNS
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                                }
                                                if($directiveName eq "IdentityCheck")
                                                {
                                                    #Equivalent IIS tag => LogExtFileUserName
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                                }
                                                if($directiveName eq "AllowOverride")
                                                {
                                                    #Equivalent IIS tag => Not Applicable.
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                                }
                                            }
                                            $numPass = 0;
                                        }
                                        else
                                        {
                                            my $kk = 0;
                                            my $jj = 0;
                                            ++$filecount;
                                            
                                            for($kk = 0; $kk < $maxColumn;$kk++)
                                            {
                                                $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                            }
                                            
                                            $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                            $files[$filecount][FILESMATCH] = $temp;
                                        }
                                    }
                                    $indI++;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if($directiveName eq "DirectoryMatch")
    {
        if($directiveValue =~ /^\//)
        {
            my $dirList;
            my @dir;
            my $temp;
            my $counter = 0;
            my @dirEntire;
            my @Listing;
            my $singleEntry;
            my $count = 0;
            my $filesName = "";
            my $filesMatchName = "";
            #the variable $test_dir below should be populted with the list of directory names
            @Listing = `ls -lRa "/" 2>/dev/null`;
            foreach $singleEntry (@Listing)
            {
                if($singleEntry =~ /:$/)
                {
                    $singleEntry =~ s/://;
                    $dirEntire[$count] = $singleEntry;
                    $count++;
                }
                elsif($singleEntry =~ /^total/)
                {                       
                    #Dont do anything
                }
                elsif($singleEntry =~ /^d/)
                {                       
                    #Dont do anything                        
                }
                elsif($singleEntry eq "")
                {                       
                    #Dont do anything                        
                }                    
            }
            foreach $temp (@dirEntire)
            {
                $directiveValue =~ s/"//g;
                $directiveValue =~ s/^\s+//;
                $directiveValue =~ s/\s+$//;
                
                if($temp =~ /$directiveValue/)
                {
                    chomp($temp);                       
                    $dir[$counter] = $temp;
                    $counter++;
                }
            }
            if($#dir >= 0)
            {
                $temp = $dir[0];                            
                
                $directiveValue =~ s/^\s+//;
                $directiveValue =~ s/\s+$//;
                ++$rowDirCount;
                $arrayDir[$rowDirCount][SERVERROOT] = "/usr/local/apache/";
                $arrayDir[$rowDirCount][SITENAME] = $array[$rowCount][SITENAME];
                $arrayDir[$rowDirCount][DIRECTORY] = $temp;
                $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "Off";
                $arrayDir[$rowDirCount][IDENTITYCHECK] = "Off";
                $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
                $arrayDir[$rowDirCount][DESTINATIONPATH] = $array[$rowCount][DESTINATIONPATH];
                $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\\/\//g;
                
                if(index($arrayDir[$rowDirCount][DIRECTORY],$array[$rowCount][DOCUMENTROOT]) != 0)  
                {
                    $arrayDir[$rowDirCount][TASKLIST]  = 1;
                    $arrayDir[$rowDirCount][DESTINATIONPATH] = $arrayDir[$rowDirCount][DESTINATIONPATH] . $arrayDir[$rowDirCount][DIRECTORY]; 
                }
                else
                {
                    my $temp;
                    $temp = pars_getRelativePath($arrayDir[$rowDirCount][DIRECTORY],$array[$rowCount][DOCUMENTROOT]);
                    $arrayDir[$rowDirCount][DESTINATIONPATH] = $arrayDir[$rowDirCount][DESTINATIONPATH] . $temp; 
                    
                }
                if($arrayDir[$rowDirCount][DESTINATIONPATH] =~ /\/$/)
                {
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\/$//;
                }
                
                while (&pars_getNextDirective() == 1)
                {
                    if($directiveName eq "/DirectoryMatch")
                    {
                        last;
                    }
                    if($dirMatch)
                    {
                        if($directiveName eq "/Directory")
                        {
                            
                            $dirMatch = 0;
                            last;
                        }
                    }
                    if($directiveName eq "Options")
                    {
                        #Equivalent IIS tag => AccessExecute
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][OPTIONS] = $arrayDir[$rowDirCount][OPTIONS] . $directiveValue . " ";
                    }
                    if($directiveName eq "Order")
                    {
                        #Equivalent IIS tag => Not applicable
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][ORDER] = $directiveValue;
                    }
                    if($directiveName eq "AddEncoding")
                    {
                        #Equivalent IIS tag => MimeMap
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][ADDENCODING] = $arrayDir[$rowDirCount][ADDENCODING] . $directiveValue . "|";
                    }
                    if($directiveName eq "AddType")
                    {
                        #Equivalent IIS tag => MimeMap
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][ADDTYPE] = $arrayDir[$rowDirCount][ADDTYPE] . $directiveValue . "|";
                    }
                    if($directiveName eq "AuthName")
                    {
                        #Equivalent IIS tag => Not Applicable
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][AUTHNAME] = $directiveValue;
                    }
                    if($directiveName eq "AuthType")
                    {
                        #Equivalent IIS tag => Not Applicable
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][AUTHTYPE] = $directiveValue;
                    }
                    if($directiveName eq "AuthUserFile")
                    {
                        #Equivalent IIS tag => Not Applicable
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        if($directiveValue =~ /^\//)
                        {
                            $arrayDir[$rowDirCount][AUTHUSERFILE] = $directiveValue;                                
                        }
                        else
                        {                                
                            $arrayDir[$rowDirCount][AUTHUSERFILE] = $arrayDir[$rowDirCount][SERVERROOT] . $directiveValue;
                        }
                    }
                    if($directiveName eq "AuthGroupFile")
                    {
                        #Equivalent IIS tag => Not Applicable
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        if($directiveValue =~ /^\//)
                        {
                            $arrayDir[$rowDirCount][AUTHGROUPFILE] = $directiveValue;
                            
                        }
                        else
                        {
                            
                            $arrayDir[$rowDirCount][AUTHGROUPFILE] = $arrayDir[$rowDirCount][SERVERROOT] . $directiveValue;
                        }
                    }
                    if($directiveName eq "DefaultType")
                    {
                        #Equivalent IIS tag => MimeMap
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        
                        my $temp = $directiveValue . " " . ".*";
                        $arrayDir[$rowDirCount][ADDTYPE] = $arrayDir[$rowDirCount][ADDTYPE] . $temp . "|";
                    }
                    if($directiveName eq "Deny")
                    {
                        #Equivalent IIS tag => MimeMap
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][DENY] = $directiveValue;
                    }
                    if($directiveName eq "DirectoryIndex")
                    {
                        #Equivalent IIS tag => EnableDirBrowsing;
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][DIRECTORYINDEX] = $directiveValue;
                        $arrayDir[$rowDirCount][DIRECTORYINDEX] =~ s/ /,/g;
                    }
                    if($directiveName eq "ErrorDocument")
                    {
                        #Equivalent IIS tag => HttpErrors
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][ERRORDOCUMENT] = $arrayDir[$rowDirCount][ERRORDOCUMENT] . $directiveValue . " ";
                    }
                    if($directiveName eq "ExpiresActive")
                    {
                        #Equivalent IIS tag => HttpExpires
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][EXPIRESACTIVE] = $directiveValue;
                    }
                    if($directiveName eq "HostnameLookups")
                    {
                        #Equivalent IIS tag => EnableReverseDNS
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = $directiveValue;
                    }
                    if($directiveName eq "IdentityCheck")
                    {
                        #Equivalent IIS tag => LogExtFileUserName
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][IDENTITYCHECK] = $directiveValue;
                    }
                    if($directiveName eq "AllowOverride")
                    {
                        #Equivalent IIS tag => Not Applicable.
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $arrayDir[$rowDirCount][ALLOWOVERRIDE] = $directiveValue;
                    }
                    if($directiveName eq "Header")
                    {
                        #Equivalent IIS tag => HttpCustomHeaders
                        
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        $directiveValue =~ s/"//g;
                        if($directiveValue =~ /^set/)
                        {
                            $arrayDir[$rowDirCount][HEADER] = $arrayDir[$rowDirCount][HEADER] . $directiveValue . "|" ;
                        }
                    }
                    if($directiveName eq "Files")
                    {
                        $filesName = $directiveValue;
    
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
    
                        my $numPass;
                        $numPass  = 1;
                        if($directiveValue =~ /^~/)
                        {
                            $fileMatch = 1;
                            my @temp;
                            @temp = split / /,$directiveValue;
                            $directiveName = "FilesMatch";
                            $directiveValue = $temp[1];
                            
                            chomp($directiveValue);
                            $directiveValue =~ s/"//g;
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;                                
                        }
                        else
                        {
                            my @file;
                            my $fileList;
                            my @fileEntire;
                            my $temp;
                            my $counter = 0;
                            my @Listing;
                            my $singleEntry;
                            my @fileEntire;
                            my @filePath;
                            my $singleEntry;
                            my $count = 0;
                            my $files;
                            my @tempArray;
                            
                            @Listing = pars_GetDirlistinght("$arrayDir[$rowDirCount][DIRECTORY]");
                            my $rootDir;
                            $rootDir = $arrayDir[$rowDirCount][DIRECTORY];
                            
                            foreach $singleEntry (@Listing)
                            {
                                
                                if($singleEntry =~ /:$/)
                                {
                                    #Dont do anything
                                    $singleEntry =~ s/:$//;
                                    $rootDir = $singleEntry;
                                    chomp($rootDir);
                                    
                                }
                                elsif($singleEntry =~ /^total/)
                                {                                        
                                    #Dont do anything                                       
                                }
                                elsif($singleEntry =~ /^d/)
                                {                                        
                                    #Dont do anything                                       
                                }
                                elsif($singleEntry eq "")
                                {                                        
                                    #Dont do anything                                       
                                }
                                else
                                {
                                    $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                    $filePath[$count] = $rootDir;
                                    $count++;
                                }
                            }
                            my $indI = 0;
                            my $dirValue = $directiveValue;
                            foreach $temp (@fileEntire)
                            {
                                $directiveValue =~ s/"//g;
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                
                                if($temp eq $dirValue)
                                {
                                    if($numPass)
                                    {
                                        $files = $temp;
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        ++$filecount;
                                        $files[$filecount][SITENAME] =  $array[$rowCount][SITENAME];
                                        $files[$filecount][DOCUMENTROOT] =  $array[$rowCount][DOCUMENTROOT];
                                        $files[$filecount][FILESMATCH] = $files;
                                        $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                        $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                        $files[$filecount][IDENTITYCHECK] = "Off";
                                        $files[$filecount][ALLOWOVERRIDE] = "All";
                                        while (&pars_getNextDirective() == 1)
                                        {
                                            if($directiveName eq "/Files")
                                            {
                                                last;
                                            }
                                            if($directiveName eq "Options")
                                            {
                                                #Equivalent IIS tag => AccessExecute
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                            }
                                            if($directiveName eq "Order")
                                            {
                                                #Equivalent IIS tag => Not applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ORDER] = $directiveValue;
                                            }
                                            if($directiveName eq "AddEncoding")
                                            {
                                                #Equivalent IIS tag => MimeMap
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                            }
                                            if($directiveName eq "AddType")
                                            {
                                                #Equivalent IIS tag => MimeMap
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                            }
                                            if($directiveName eq "AuthName")
                                            {
                                                #Equivalent IIS tag => Not Applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][AUTHNAME] = $directiveValue;
                                            }
                                            if($directiveName eq "AuthType")
                                            {
                                                #Equivalent IIS tag => Not Applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][AUTHTYPE] = $directiveValue;
                                            }
                                            if($directiveName eq "AuthUserFile")
                                            {
                                                #Equivalent IIS tag => Not Applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                if($directiveValue =~ /^\//)
                                                {
                                                    $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                                }
                                                else
                                                {
                                                    
                                                    $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                                }
                                                
                                            }
                                            if($directiveName eq "AuthGroupFile")
                                            {
                                                #Equivalent IIS tag => Not Applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                if($directiveValue =~ /^\//)
                                                {
                                                    $files[$filecount][AUTHGROUPFILE] = $directiveValue;
                                                    
                                                }
                                                else
                                                {
                                                    
                                                    $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                                }
                                            }
                                            if($directiveName eq "DefaultType")
                                            {
                                                #Equivalent IIS tag => MimeMap
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                
                                                my $temp = $directiveValue . " " . ".*";
                                                $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                            }
                                            if($directiveName eq "Deny")
                                            {
                                                #Equivalent IIS tag => MimeMap
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][DENY] = $directiveValue;
                                            }
                                            if($directiveName eq "DirectoryIndex")
                                            {
                                                #Equivalent IIS tag => EnableDirBrowsing;
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                                $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                            }
                                            if($directiveName eq "ErrorDocument")
                                            {
                                                #Equivalent IIS tag => HttpErrors
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                            }
                                            if($directiveName eq "ExpiresActive")
                                            {
                                                #Equivalent IIS tag => HttpExpires
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                            }
                                            if($directiveName eq "HostnameLookups")
                                            {
                                                #Equivalent IIS tag => EnableReverseDNS
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                            }
                                            if($directiveName eq "IdentityCheck")
                                            {
                                                #Equivalent IIS tag => LogExtFileUserName
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                            }
                                            if($directiveName eq "AllowOverride")
                                            {
                                                #Equivalent IIS tag => Not Applicable.
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                            }
                                        }
                                        $numPass = 0;
                                    }
                                    else
                                    {
                                        my $kk = 0;
                                        my $jj = 0;
                                        ++$filecount;
                                        
                                        for($kk = 0; $kk < $maxColumn;$kk++)
                                        {
                                            $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                        }
                                        
                                        $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                    }
                                }
                                $indI++;
                            }
                        }
                    }
                    if($directiveName eq "FilesMatch")
                    {
                        my @file;
                        my $fileList;
                        my @fileEntire;
                        my $temp;
                        my $counter = 0;
                        my @Listing;
                        my $singleEntry;
                        my @fileEntire;
                        my @filePath;
                        my $singleEntry;
                        my $count = 0;
                        my $files;
                        my @tempArray;
                        my $numPass = 1;
                        $filesMatchName = $directiveValue;
                        
                        @Listing = pars_GetDirlistinght("$arrayDir[$rowDirCount][DIRECTORY]");
                        my $rootDir;
                        $rootDir = $arrayDir[$rowDirCount][DIRECTORY];
                        foreach $singleEntry (@Listing)
                        {
                            
                            if($singleEntry =~ /:$/)
                            {
                                #Dont do anything
                                $singleEntry =~ s/:$//;
                                $rootDir = $singleEntry;
                                chomp($rootDir);
                                
                            }
                            elsif($singleEntry =~ /^total/)
                            {                                    
                                #Dont do anything                                    
                            }
                            elsif($singleEntry =~ /^d/)
                            {                                   
                                #Dont do anything                                    
                            }
                            elsif($singleEntry eq "")
                            {                                   
                                #Dont do anything                                    
                            }
                            else
                            {
                                $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                $filePath[$count] = $rootDir;
                                $count++;
                            }
                        }
                        my $indI = 0;
                        my $dirValue = $directiveValue;
                        foreach $temp (@fileEntire)
                        {
                            
                            $directiveValue =~ s/"//g;
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            
                            if($temp =~ /$dirValue/)
                            {
                                if($numPass)
                                {   
                                    $files = $temp;
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    ++$filecount;
                                    $files[$filecount][SITENAME] =  $array[$rowCount][SITENAME];
                                    $files[$filecount][DOCUMENTROOT] =  $array[$rowCount][DOCUMENTROOT];
                                    $files[$filecount][FILESMATCH] = $files;
                                    $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                    $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                    $files[$filecount][IDENTITYCHECK] = "Off";
                                    $files[$filecount][ALLOWOVERRIDE] = "All";
                                    while (&pars_getNextDirective() == 1)
                                    {
                                        if($directiveName eq "/FilesMatch")
                                        {
                                            last;
                                        }
                                        if($fileMatch)
                                        {
                                            if($directiveName eq "/Files")
                                            {
                                                
                                                $fileMatch = 0;
                                                last;
                                            }
                                        }
                                        if($directiveName eq "Options")
                                        {
                                            #Equivalent IIS tag => AccessExecute
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                        }
                                        if($directiveName eq "Order")
                                        {
                                            #Equivalent IIS tag => Not applicable
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][ORDER] = $directiveValue;
                                        }
                                        if($directiveName eq "AddEncoding")
                                        {
                                            #Equivalent IIS tag => MimeMap
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                        }
                                        if($directiveName eq "AddType")
                                        {
                                            #Equivalent IIS tag => MimeMap
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                        }
                                        if($directiveName eq "AuthName")
                                        {
                                            #Equivalent IIS tag => Not Applicable
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][AUTHNAME] = $directiveValue;
                                        }
                                        if($directiveName eq "AuthType")
                                        {
                                            #Equivalent IIS tag => Not Applicable
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][AUTHTYPE] = $directiveValue;
                                        }
                                        if($directiveName eq "AuthUserFile")
                                        {
                                            #Equivalent IIS tag => Not Applicable
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            if($directiveValue =~ /^\//)
                                            {
                                                $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                            }
                                            else
                                            {
                                                
                                                $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                            }
                                            
                                        }
                                        if($directiveName eq "AuthGroupFile")
                                        {
                                            #Equivalent IIS tag => Not Applicable
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            if($directiveValue =~ /^\//)
                                            {
                                                $files[$filecount][AUTHGROUPFILE] = $directiveValue;                                                    
                                            }
                                            else
                                            {                                                    
                                                $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                            }
                                        }
                                        if($directiveName eq "DefaultType")
                                        {
                                            #Equivalent IIS tag => MimeMap
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            
                                            my $temp = $directiveValue . " " . ".*";
                                            $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                        }
                                        if($directiveName eq "Deny")
                                        {
                                            #Equivalent IIS tag => MimeMap
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][DENY] = $directiveValue;
                                        }
                                        if($directiveName eq "DirectoryIndex")
                                        {
                                            #Equivalent IIS tag => EnableDirBrowsing;
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                            $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                        }
                                        if($directiveName eq "ErrorDocument")
                                        {
                                            #Equivalent IIS tag => HttpErrors
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                        }
                                        if($directiveName eq "ExpiresActive")
                                        {
                                            #Equivalent IIS tag => HttpExpires
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                        }
                                        if($directiveName eq "HostnameLookups")
                                        {
                                            #Equivalent IIS tag => EnableReverseDNS
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                        }
                                        if($directiveName eq "IdentityCheck")
                                        {
                                            #Equivalent IIS tag => LogExtFileUserName
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                        }
                                        if($directiveName eq "AllowOverride")
                                        {
                                            #Equivalent IIS tag => Not Applicable.
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                        }
                                    }
                                    $numPass = 0;
                                }
                                else
                                {
                                    my $kk = 0;
                                    my $jj = 0;
                                    ++$filecount;
                                    
                                    for($kk = 0; $kk < $maxColumn;$kk++)
                                    {
                                        $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                    }
                                    
                                    $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                    $files[$filecount][FILESMATCH] = $temp;
                                }
                            }
                            $indI++;
                        }
                    }
                }
            }
            my $folderCount = $rowDirCount;
            
            foreach $temp (@dir)
            {
                next if($temp eq $dir[0]);
                $directiveValue =~ s/^\s+//;
                $directiveValue =~ s/\s+$//;
                ++$rowDirCount;
                my $j;
                for($j = 0;$j < $maxColumn; $j++)
                {
                    $arrayDir[$rowDirCount][$j] = $arrayDir[($rowDirCount-1)][$j];
                }
                $arrayDir[$rowDirCount][DIRECTORY] = $temp;
                $arrayDir[$rowDirCount][DESTINATIONPATH] = $array[$rowCount][DESTINATIONPATH];
                if(index($arrayDir[$rowDirCount][DIRECTORY],$array[$rowCount][DOCUMENTROOT]) != 0)  
                {
                    $arrayDir[$rowDirCount][TASKLIST]  = 1;
                    $arrayDir[$rowDirCount][DESTINATIONPATH] = $arrayDir[$rowDirCount][DESTINATIONPATH] . $arrayDir[$rowDirCount][DIRECTORY]; 
                }
                else
                {
                    my $temp;
                    $temp = pars_getRelativePath($arrayDir[$rowDirCount][DIRECTORY],$array[$rowCount][DOCUMENTROOT]);
                    $arrayDir[$rowDirCount][DESTINATIONPATH] = $arrayDir[$rowDirCount][DESTINATIONPATH] . $temp; 
                    
                }
            }
            my $jkl;
            for($jkl = ($folderCount+1); $jkl <= $rowDirCount; $jkl++)
            {
                if($filesName ne "")
                {
                    $directiveValue = $filesName;
                    $directiveValue =~ s/^\s+//;
                    $directiveValue =~ s/\s+$//;
                    my @file;
                    my $fileList;
                    my @fileEntire;
                    my $temp;
                    my $counter = 0;
                    my @Listing;
                    my $singleEntry;
                    my @fileEntire;
                    my @filePath;
                    my $singleEntry;
                    my $count = 0;
                    my $files;
                    my @tempArray;
                    
                    @Listing = pars_GetDirlistinght("$arrayDir[$jkl][DIRECTORY]");
                    my $rootDir;
                    $rootDir = $arrayDir[$jkl][DIRECTORY];
                    
                    foreach $singleEntry (@Listing)
                    {
                        
                        if($singleEntry =~ /:$/)
                        {
                            #Dont do anything
                            $singleEntry =~ s/:$//;
                            $rootDir = $singleEntry;
                            chomp($rootDir);
                            
                        }
                        elsif($singleEntry =~ /^total/)
                        {                                
                            #Dont do anything                                
                        }
                        elsif($singleEntry =~ /^d/)
                        {                                
                            #Dont do anything                                
                        }
                        elsif($singleEntry eq "")
                        {                                
                            #Dont do anything                                
                        }
                        else
                        {
                            $fileEntire[$count] = pars_FileNameSet($singleEntry);
                            $filePath[$count] = $rootDir;
                            $count++;
                        }
                    }
                    my $dirValue = $directiveValue;
                    my $numPass = 1;
                    my $indI = 0;
                    foreach $temp (@fileEntire)
                    {
                        $directiveValue =~ s/"//g;
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        
                        if($temp eq $dirValue)
                        {
                            if($numPass)
                            {
                                $files = $temp;
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                ++$filecount;
                                $files[$filecount][SITENAME] = $array[$rowCount][SITENAME];
                                $files[$filecount][DOCUMENTROOT] = $array[$rowCount][DOCUMENTROOT];
                                $files[$filecount][FILESMATCH] = $files;
                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                $files[$filecount][IDENTITYCHECK] = "Off";
                                $files[$filecount][ALLOWOVERRIDE] = "All";
                                $numPass = 0;
                                my $kk = 0;
                                my $jj = 0;
                                
                                for($kk = 0; $kk < $maxColumn;$kk++)
                                {
                                    $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                }
                                
                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                            }
                            else
                            {
                                my $kk = 0;
                                my $jj = 0;
                                ++$filecount;
                                
                                for($kk = 0; $kk < $maxColumn;$kk++)
                                {
                                    $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                }
                                
                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                            }
                        }
                        $indI++;
                    }
                }
                if($filesMatchName ne "")
                {
                    $directiveValue = $filesName;
                    $directiveValue =~ s/^\s+//;
                    $directiveValue =~ s/\s+$//;
                    my @file;
                    my $fileList;
                    my @fileEntire;
                    my $temp;
                    my $counter = 0;
                    my @Listing;
                    my $singleEntry;
                    my @fileEntire;
                    my @filePath;
                    my $singleEntry;
                    my $count = 0;
                    my $files;
                    my @tempArray;
                    
                    @Listing = pars_GetDirlistinght("$arrayDir[$jkl][DIRECTORY]");
                    my $rootDir;
                    $rootDir = $arrayDir[$jkl][DIRECTORY];
                    
                    foreach $singleEntry (@Listing)
                    {
                        
                        if($singleEntry =~ /:$/)
                        {
                            #Dont do anything
                            $singleEntry =~ s/:$//;
                            $rootDir = $singleEntry;
                            chomp($rootDir);
                            
                        }
                        elsif($singleEntry =~ /^total/)
                        {                                
                            #Dont do anything                                
                        }
                        elsif($singleEntry =~ /^d/)
                        {                                
                            #Dont do anything                                
                        }
                        elsif($singleEntry eq "")
                        {                                
                            #Dont do anything                                
                        }
                        else
                        {
                            $fileEntire[$count] = pars_FileNameSet($singleEntry);
                            $filePath[$count] = $rootDir;
                            $count++;
                        }
                    }
                    my $dirValue = $directiveValue;
                    my $numPass = 1;
                    my $indI = 0;
                    foreach $temp (@fileEntire)
                    {
                        $directiveValue =~ s/"//g;
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        
                        if($temp =~ /$dirValue/)
                        {
                            if($numPass)
                            {
                                $files = $temp;
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                ++$filecount;
                                $files[$filecount][SITENAME] = $array[$rowCount][SITENAME];
                                $files[$filecount][DOCUMENTROOT] = $array[$rowCount][DOCUMENTROOT];
                                $files[$filecount][FILESMATCH] = $files;
                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                $files[$filecount][IDENTITYCHECK] = "Off";
                                $files[$filecount][ALLOWOVERRIDE] = "All";
                                $numPass = 0;
                                my $kk = 0;
                                my $jj = 0;
                                
                                for($kk = 0; $kk < $maxColumn;$kk++)
                                {
                                    $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                }
                                
                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                            }
                            else
                            {
                                my $kk = 0;
                                my $jj = 0;
                                ++$filecount;
                                
                                for($kk = 0; $kk < $maxColumn;$kk++)
                                {
                                    $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                }
                                
                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                            }
                        }
                        $indI++;
                    }
                }
            }
        }   
    }
    if($directiveName eq "Files")
    {
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        my $numPass;
        $numPass = 1;
        if($directiveValue =~ /^~/)
        {
            $fileMatch = 1;
            my @temp;
            @temp = split / /,$directiveValue;
            $directiveName = "FilesMatch";
            $directiveValue = $temp[1];
            
            chomp($directiveValue);
            $directiveValue =~ s/"//g;
            $directiveValue =~ s/^\s+//;
            $directiveValue =~ s/\s+$//;
        }
        else
        {
            my @file;
            my $fileList;
            my @fileEntire;
            my $temp;
            my $counter = 0;
            my @Listing;
            my $singleEntry;
            my @fileEntire;
            my @filePath;
            my $singleEntry;
            my $count = 0;
            my $files;
            my @tempArray;
            
            @Listing = pars_GetDirlistinght("$array[$rowCount][DOCUMENTROOT]");
            my $rootDir;
            $rootDir = $array[$rowCount][DOCUMENTROOT];
            foreach $singleEntry (@Listing)
            {
                
                if($singleEntry =~ /:$/)
                {
                    #Dont do anything                        
                    $singleEntry =~ s/:$//;
                    $rootDir = $singleEntry;
                    chomp($rootDir);
                }
                elsif($singleEntry =~ /^total/)
                {                        
                    #Dont do anything                        
                }
                elsif($singleEntry =~ /^d/)
                {                       
                    #Dont do anything                        
                }
                elsif($singleEntry eq "")
                {                       
                    #Dont do anything                        
                }
                else
                {
                    
                    $fileEntire[$count] = pars_FileNameSet($singleEntry);
                    $filePath[$count] = $rootDir;
                    $count++;
                }
            }
            my $indI = 0;
            my $dirValue = $directiveValue;
            foreach $temp (@fileEntire)
            {
                $directiveValue =~ s/"//g;
                $directiveValue =~ s/^\s+//;
                $directiveValue =~ s/\s+$//;
                
                if($temp eq $dirValue)
                {
                    if($numPass)
                    {
                        $files = $temp;
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        ++$filecount;
                        $files[$filecount][SITENAME] = $array[$rowCount][SITENAME];
                        $files[$filecount][DOCUMENTROOT] = $array[$rowCount][DOCUMENTROOT];
                        $files[$filecount][FILESMATCH] = $files;
                        $files[$filecount][DIRECTORY] =  $filePath[$indI];
                        $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                        $files[$filecount][IDENTITYCHECK] = "Off";
                        $files[$filecount][ALLOWOVERRIDE] = "All";
                        
                        while (&pars_getNextDirective() == 1)
                        {
                            if($directiveName eq "/Files")
                            {
                                last;
                            }
                            if($directiveName eq "Options")
                            {
                                #Equivalent IIS tag => AccessExecute
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                            }
                            if($directiveName eq "Order")
                            {
                                #Equivalent IIS tag => Not applicable
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][ORDER] = $directiveValue;
                            }
                            if($directiveName eq "AddEncoding")
                            {
                                #Equivalent IIS tag => MimeMap
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                            }
                            if($directiveName eq "AddType")
                            {
                                #Equivalent IIS tag => MimeMap
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                            }
                            if($directiveName eq "AuthName")
                            {
                                #Equivalent IIS tag => Not Applicable
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][AUTHNAME] = $directiveValue;
                            }
                            if($directiveName eq "AuthType")
                            {
                                #Equivalent IIS tag => Not Applicable
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][AUTHTYPE] = $directiveValue;
                            }
                            if($directiveName eq "AuthUserFile")
                            {
                                #Equivalent IIS tag => Not Applicable
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                if($directiveValue =~ /^\//)
                                {
                                    $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                }
                                else
                                {                                        
                                    $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                }                                    
                            }
                            if($directiveName eq "AuthGroupFile")
                            {
                                #Equivalent IIS tag => Not Applicable
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                if($directiveValue =~ /^\//)
                                {
                                    $files[$filecount][AUTHGROUPFILE] = $directiveValue;                                        
                                }
                                else
                                {                                        
                                    $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                }
                            }
                            if($directiveName eq "DefaultType")
                            {
                                #Equivalent IIS tag => MimeMap
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                
                                my $temp = $directiveValue . " " . ".*";
                                $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                            }
                            if($directiveName eq "Deny")
                            {
                                #Equivalent IIS tag => MimeMap
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][DENY] = $directiveValue;
                            }
                            if($directiveName eq "DirectoryIndex")
                            {
                                #Equivalent IIS tag => EnableDirBrowsing;
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                            }
                            if($directiveName eq "ErrorDocument")
                            {
                                #Equivalent IIS tag => HttpErrors
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                            }
                            if($directiveName eq "ExpiresActive")
                            {
                                #Equivalent IIS tag => HttpExpires
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                            }
                            if($directiveName eq "HostnameLookups")
                            {
                                #Equivalent IIS tag => EnableReverseDNS
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                            }
                            if($directiveName eq "IdentityCheck")
                            {
                                #Equivalent IIS tag => LogExtFileUserName
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][IDENTITYCHECK] = $directiveValue;
                            }
                            if($directiveName eq "AllowOverride")
                            {
                                #Equivalent IIS tag => Not Applicable.
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                            }
                            if($directiveName eq "Header")
                            {
                                #Equivalent IIS tag => HttpCustomHeaders
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $directiveValue =~ s/"//g;
                                if($directiveValue =~ /^set/)
                                {
                                    $files[$filecount][HEADER] = $files[$filecount][HEADER] . $directiveValue . "|" ;
                                }
                            }
                            if($directiveName eq "ExpiresActive")
                            {       
                                #Equivalent IIS tag => HttpExpires
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                            }
                        }
                        
                        $numPass = 0;   
                    }
                    else
                    {
                        my $kk = 0;
                        my $jj = 0;
                        ++$filecount;
                        
                        for($kk = 0; $kk < $maxColumn;$kk++)
                        {
                            $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                        }
                        
                        $files[$filecount][DIRECTORY] =  $filePath[$indI];
                    }
                }
                $indI++;
            }
        }
    }
    if($directiveName eq "FilesMatch")
    {
        my @file;
        my $fileList;
        my @fileEntire;
        my $temp;
        my $counter = 0;
        my @Listing;
        my $singleEntry;
        my @fileEntire;
        my @filePath;
        my $singleEntry;
        my $count = 0;
        my $files;
        my @tempArray;
        my $numPass = 1;
        
        @Listing = pars_GetDirlistinght("$array[$rowCount][DOCUMENTROOT]");
        my $rootDir;
        $rootDir = $array[$rowCount][DOCUMENTROOT];
        foreach $singleEntry (@Listing)
        {
            
            if($singleEntry =~ /:$/)
            {
                #Dont do anything
                $singleEntry =~ s/:$//;
                $rootDir = $singleEntry;
                chomp($rootDir);
                
            }
            elsif($singleEntry =~ /^total/)
            {                    
                #Dont do anything                    
            }
            elsif($singleEntry =~ /^d/)
            {
                #Dont do anything                    
            }
            elsif($singleEntry eq "")
            {                   
                #Dont do anything                    
            }
            else
            {
                $fileEntire[$count] = pars_FileNameSet($singleEntry);
                $filePath[$count] = $rootDir;
                $count++;
            }
        }
        my $indI = 0;
        my $dirValue = $directiveValue;
        foreach $temp (@fileEntire)
        {
            $directiveValue =~ s/"//g;
            $directiveValue =~ s/^\s+//;
            $directiveValue =~ s/\s+$//;        
            if($temp =~ /$dirValue/)
            {
                if($numPass)
                {
                    $files = $temp;
                    $directiveValue =~ s/^\s+//;
                    $directiveValue =~ s/\s+$//;
                    ++$filecount;
                    $files[$filecount][SITENAME] = $array[$rowCount][SITENAME];
                    $files[$filecount][DOCUMENTROOT] = $array[$rowCount][DOCUMENTROOT];
                    $files[$filecount][FILESMATCH] = $files;
                    $files[$filecount][DIRECTORY] =  $filePath[$indI];
                    $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                    $files[$filecount][IDENTITYCHECK] = "Off";
                    $files[$filecount][ALLOWOVERRIDE] = "All";
                    while (&pars_getNextDirective() == 1)
                    {
                        if($directiveName eq "/FilesMatch")
                        {
                            last;
                        }
                        if($fileMatch)
                        {
                            if($directiveName eq "/Files")
                            {
                                
                                $fileMatch = 0;
                                last;
                            }
                        }
                        if($directiveName eq "Options")
                        {
                            #Equivalent IIS tag => AccessExecute
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                        }
                        if($directiveName eq "Order")
                        {
                            #Equivalent IIS tag => Not applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][ORDER] = $directiveValue;
                        }
                        if($directiveName eq "AddEncoding")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                        }
                        if($directiveName eq "AddType")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                        }
                        if($directiveName eq "AuthName")
                        {
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][AUTHNAME] = $directiveValue;
                        }
                        if($directiveName eq "AuthType")
                        {
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][AUTHTYPE] = $directiveValue;
                        }
                        if($directiveName eq "AuthUserFile")
                        {
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            if($directiveValue =~ /^\//)
                            {
                                $files[$filecount][AUTHUSERFILE] = $directiveValue;
                            }
                            else
                            {                                    
                                $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                            }                                
                        }
                        if($directiveName eq "AuthGroupFile")
                        {
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            if($directiveValue =~ /^\//)
                            {
                                $files[$filecount][AUTHGROUPFILE] = $directiveValue;                                    
                            }
                            else
                            {                                    
                                $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                            }
                        }
                        if($directiveName eq "DefaultType")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            
                            my $temp = $directiveValue . " " . ".*";
                            $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                        }
                        if($directiveName eq "Deny")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][DENY] = $directiveValue;
                        }
                        if($directiveName eq "DirectoryIndex")
                        {
                            #Equivalent IIS tag => EnableDirBrowsing;
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                            $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                        }
                        if($directiveName eq "ErrorDocument")
                        {
                            #Equivalent IIS tag => HttpErrors
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                        }
                        if($directiveName eq "ExpiresActive")
                        {
                            #Equivalent IIS tag => HttpExpires
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                        }
                        if($directiveName eq "HostnameLookups")
                        {
                            #Equivalent IIS tag => EnableReverseDNS
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                        }
                        if($directiveName eq "IdentityCheck")
                        {
                            #Equivalent IIS tag => LogExtFileUserName
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][IDENTITYCHECK] = $directiveValue;
                        }
                        if($directiveName eq "AllowOverride")
                        {
                            #Equivalent IIS tag => Not Applicable.
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                        }
                        if($directiveName eq "Header")
                        {
                            #Equivalent IIS tag => HttpCustomHeaders
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $directiveValue =~ s/"//g;
                            if($directiveValue =~ /^set/)
                            {
                                $files[$filecount][HEADER] = $files[$filecount][HEADER] . $directiveValue . "|" ;
                            }
                        }
                        if($directiveName eq "ExpiresActive")
                        {   
                            #Equivalent IIS tag => HttpExpires
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                        }
                    }
                    $numPass = 0;
                }
                else
                {
                    my $kk = 0;
                    my $jj = 0;
                    ++$filecount;
                    
                    for($kk = 0; $kk < $maxColumn;$kk++)
                    {
                        $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                    }
                    
                    $files[$filecount][DIRECTORY] =  $filePath[$indI];
                    $files[$filecount][FILESMATCH] = $temp;
                }
            }
            $indI++;
        }
    }    
}

#######################################################################################################################
#
# Method Name   : pars_setDefaultsite
#
# Description   : Populate the 2D array with the Default site related directive values 
#   
# Input         : None
#
# OutPut        : None
#
# Status        : None
# 
#######################################################################################################################
sub pars_setDefaultsite
{
    # $defaultUserdir -> virtUserdir
    # Parse for Include directive
    if($directiveName eq "Include")
    {
        if($directiveValue =~ /^\//)
        {           
            my $includeFilename = $directiveValue;
            $filepos = tell CONFIGHANDLE;
            $includeFilename =~ s/\//_/g;
            push(@includeFilePointer,$filepos);
            push(@includeFileName,$configFile);
            $flag = 1;          
            $configFile = &pars_GetSessionFolder() . $includeFilename;
            eval
            {
                close CONFIGHANDLE or die 'ERR_FILE_CLOSE';
            };
    
            if($@)
            {
                if($@=~/ERR_FILE_CLOSE/)
                {
                    # log 'file close error' and continue                   
                    ilog_setLogInformation('INT_ERROR',$configFile,ERR_FILE_CLOSE,__LINE__);
                }   
            }
            else
            {
                ilog_setLogInformation('INT_INFO',$configFile,MSG_FILE_CLOSE,'');
            }
            
            eval
            {               
                open CONFIGHANDLE ,$configFile or die 'ERR_FILE_OPEN';
            };
            if($@)  
            {
                if($@=~/ERR_FILE_OPEN/)
                {
                    # log error and exit tool                   
                    ilog_setLogInformation('INT_ERROR',$temp,ERR_FILE_OPEN,__LINE__);
                    return FALSE;                                                           
                }
            }
            else
            {
                ilog_setLogInformation('INT_INFO',$temp,MSG_FILE_OPEN,'');
            }
        }
        else
        {
            if($array[0][SERVERROOT] =~ /\/$/)
            {
                my $includeFilename = $array[0][SERVERROOT] . $directiveValue;
                $includeFilename =~ s/\//_/g;   
                $filepos = tell CONFIGHANDLE;
                push(@includeFilePointer,$filepos);
                push(@includeFileName,$configFile);
                $configFile = &pars_GetSessionFolder() . $includeFilename;
                $flag = 1;
                eval
                {
                    close CONFIGHANDLE or die 'ERR_FILE_CLOSE';
                    
                };
                if($@)
                {
                    if($@=~/ERR_FILE_CLOSE/)
                    {
                        # log 'file close error' and continue                       
                        ilog_setLogInformation('INT_ERROR',$configFile,ERR_FILE_CLOSE,__LINE__);
                    }   
                }
                else
                {
                    ilog_setLogInformation('INT_INFO',$configFile,MSG_FILE_CLOSE,'');
                }
                
                eval
                {               
                    open CONFIGHANDLE ,$configFile or die 'ERR_FILE_OPEN';
                };
                if($@)  
                {
                    if($@=~/ERR_FILE_OPEN/)
                    {   
                        # log error and exit tool                       
                        ilog_setLogInformation('INT_ERROR',$temp,ERR_FILE_OPEN,__LINE__);       
                        return FALSE;                                                           
                    }
                }
                else
                {
                    ilog_setLogInformation('INT_INFO',$temp,MSG_FILE_OPEN,'');
                }                   
            }
            else
            {
                my $includeFilename = $array[0][SERVERROOT] . "/" . $directiveValue;
                $includeFilename =~ s/\//_/g;
                $filepos = tell CONFIGHANDLE;
                push(@includeFilePointer,$filepos);
                push(@includeFileName,$configFile);
                $flag = 1;
                $configFile = &pars_GetSessionFolder() . $includeFilename;
                eval
                {
                    close CONFIGHANDLE or die 'ERR_FILE_CLOSE';                 
                };
                if($@)
                {
                    if($@=~/ERR_FILE_CLOSE/)
                    {
                        # log 'file close error' and continue                       
                        ilog_setLogInformation('INT_ERROR',$configFile,ERR_FILE_CLOSE,__LINE__);
                    }   
                }
                else
                {
                    ilog_setLogInformation('INT_INFO',$configFile,MSG_FILE_CLOSE,'');
                }
                eval
                {               
                    open CONFIGHANDLE ,$configFile or die 'ERR_FILE_OPEN';
                };
                if($@)  
                {
                    if($@=~/ERR_FILE_OPEN/)
                    {   
                        # log error and exit tool                       
                        ilog_setLogInformation('INT_ERROR',$temp,ERR_FILE_OPEN,__LINE__);       
                        return FALSE;                                                           
                    }
                }
                else
                {
                    ilog_setLogInformation('INT_INFO',$temp,MSG_FILE_OPEN,'');
                }                               
            }
        }
    }
    
    if($directiveName eq "TypesConfig")
    {
        $mimeFlag = 0;
        if($directiveValue =~ /^\//)
        {       
            $mimeTypes = pars_GetMimeTypes($directiveValue);
        }
        else
        {           
            my $fileName = $array[0][SERVERROOT].$directiveValue;
            $mimeTypes = pars_GetMimeTypes($fileName);
        }
    }
    
    #Server Config related directives are stored here in the 2D array.
    if($directiveName eq "KeepAlive")
    {
        #Equivalent IIS  tag => AllowKeepAlive, MaxConnections
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[0][KEEPALIVE] = $directiveValue;
    }
    if($directiveName eq "KeepAliveTimeout")
    {
        #Equivalent IIS tag => Connection Timeout
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[0][KEEPALIVETIMEOUT] = $directiveValue;
    }
    if($directiveName eq "ListenBacklog")
    {
        #Equivalent IIS tag => ServerListenBacklog
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[0][LISTENBACKLOG] = $directiveValue;
    }
    if($directiveName eq "MaxClients")
    {
        #Equivalent IIS tag => MaxConnections
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[0][MAXCLIENTS] = $directiveValue;
    }
    if($directiveName eq "NameVirtualHost")
    {
        #Equivalent IIS tag => ServerBindings
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[0][NAMEVIRTUALHOST] = $array[0][NAMEVIRTUALHOST] . $directiveValue . " ";
    }
    if($directiveName eq "Options")
    {
        #Equivalent IIS tag => AccessExecute
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[0][OPTIONS] = $directiveValue;
    }
    if($directiveName eq "Port")
    {
        #Equivalent IIS tag => ServerBindings
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[0][PORT] = $directiveValue;
    }
    
    if($directiveName eq "ServerName")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        $array[0][SERVERNAME] = $directiveValue;
    }
    if($directiveName eq "ServerRoot")
    {
        #Equivalent IIS tag => Not Applicable
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        if($directiveValue =~ /\/$/)
        {
            $array[0][SERVERROOT] = $directiveValue;
        }
        else
        {
            $array[0][SERVERROOT] = $directiveValue . "/";
        }
    }
    if($directiveName eq "BindAddress")
    {
        #Equivalent IIS tag => ServerBindings
        $directiveValue =~ s/^\s+//;
        $directiveValue =~ s/\s+$//;
        
        $array[0][BINDADDRESS] = $directiveValue;
        
    }

    # PARSE COMMON
    my $backupRowCount = $rowCount;
    $rowCount = 0;
    pars_common2d();
    $rowCount = $backupRowCount;
}

#######################################################################################################################
#
# Method Name   : pars_setVirtualhost
#
# Description   : Populate the 2D array with the Virtual host related directive values 
#
# Input         : None
#
# OutPut        : None
#
# Status        : None
# 
#
#######################################################################################################################
sub pars_setVirtualhost
{
    #Virtual host related directives are stored here in the 2D array.
    $columnCount = 0;
    ++$rowCount;
    $directiveValue =~ s/^\s+//;
    $directiveValue =~ s/\s+$//;
    $array[$rowCount][$columnCount] = $directiveValue;
    $array[$rowCount][DESTINATIONPATH] = $destinationPath;
    $array[$rowCount][DESTINATIONPATH] =~ s/\\$//;
    #Fill the array initially with default vales
    $array[$rowCount][SITENAME] = $siteName; 
    $array[$rowCount][PORT] = $portValue;
    $array[$rowCount][RESOURCECONFIG] = "conf/srm.conf";
    $array[$rowCount][SERVERROOT] = $array[0][SERVERROOT];
    $array[$rowCount][USERDIR] = "public_html";
    $directiveValue =~ s/^\s+//;
    $directiveValue =~ s/\s+$//;
    $array[0][VIRTUALHOST] = $array[0][VIRTUALHOST] . $directiveValue . " ";
    $array[$rowCount][ACCESSCONFIG] = "conf/access.conf";
    $array[$rowCount][ACCESSFILENAME] = ".htaccess";
    $array[$rowCount][DEFAULTTYPE] = "text/plain";
    if (-e ("/usr/local/apache/htdocs"))
    {
        # old style apache
        $array[0][DOCUMENTROOT] = "/usr/local/apache/htdocs";
    }
    else
    {
        $array[0][DOCUMENTROOT] = "/var/www";
    }

    $array[$rowCount][HOSTNAMELOOKUPS] = "off";
    $array[$rowCount][IDENTITYCHECK] = "off";
    $array[$rowCount][DIRECTORYINDEX] = "index.html";
    $array[$rowCount][ERRORLOG] = "logs/error_log"; 
    $array[$rowCount][SSLENGINE] = "off";
    $array[$rowCount][KEEPALIVE] = $array[0][KEEPALIVE];
    $array[$rowCount][KEEPALIVETIMEOUT] = $array[0][KEEPALIVETIMEOUT];
    $array[$rowCount][LISTENBACKLOG] = $array[0][LISTENBACKLOG];
    $array[$rowCount][MAXCLIENTS] = $array[0][MAXCLIENTS];
    $array[$rowCount][USERENABLED] = 1;
    $array[$rowCount][USERDISABLED] = 1;
    $array[$rowCount][OPTIONS] = "All";
    
    # my $virtUserdir = 0;
    my $errorFlag = 1;
    my $accessFlag = 1;
    my $resourceFlag = 1;
    while (&pars_getNextDirective() == 1)
    {
        if($directiveName eq "/VirtualHost")
        {
            last;
        }
        
        if($directiveName eq "ServerAlias")
        {
            #Equivalent IIS tag => ServerBindings
            $directiveValue =~ s/^\s+//;
            $directiveValue =~ s/\s+$//;
            $array[$rowCount][SERVERALIAS] = $directiveValue;
        }
        
        if($directiveName eq "ServerName")
        {
            #Equivalent IIS tag => Not Applicable
            $directiveValue =~ s/^\s+//;
            $directiveValue =~ s/\s+$//;
            $array[$rowCount][SERVERNAME] = $directiveValue;
        }
        
        if($directiveName eq "Options")
        {
            #Equivalent IIS tag => AccessExecute
            $directiveValue =~ s/^\s+//;
            $directiveValue =~ s/\s+$//;
            $array[$rowCount][OPTIONS] = $directiveValue;
        }

        pars_common2d();   
    }
    
    if($errorFlag)
    {
        $array[$rowCount][ERRORLOG] = $array[$rowCount][SERVERROOT] . $array[$rowCount][ERRORLOG];
    }
    if($resourceFlag)
    {
        $array[$rowCount][RESOURCECONFIG] = $array[$rowCount][SERVERROOT] . $array[$rowCount][RESOURCECONFIG];      
    }
    if($accessFlag)
    {
        $array[$rowCount][ACCESSCONFIG] = $array[$rowCount][SERVERROOT] . $array[$rowCount][ACCESSCONFIG];
    }
}

#######################################################################################################################
#
# Method Name   : pars_directoryFound
#
# Description   : The function is used to determine whether the .htaccess has a corresponding <Directory> tag.
#
# Input         : None.
#
# OutPut        : 
#                 0 if Directory is not found
#
#                 Row Index if the entry found
#
# Status        : 
#
#######################################################################################################################
sub pars_directoryFound
{
    my $directoryTofind = shift;
    my $sitename          = shift;  
    
    for($i = 0;$i <= $rowDirCount; $i++)
    {
        
        if($arrayDir[$i][DIRECTORY] eq $directoryTofind)
        {
            if($arrayDir[$i][SITENAME] eq $sitename)
            {
                return (1,$i);
            }
        }
    }

    return (0,0);
}

#######################################################################################################################
#
# Method Name   : pars_printArraysite
#
# Description   : The function is used to print the array content wrt the site configuration 
#
# Input         : None
#
# OutPut        : None
#
# Status        : None
#
#######################################################################################################################
sub pars_printArraysite
{
    my $value;
    my $cnt = 0;
    my $i;
    my $j;
    my $logFilereturn;
    print "\n--------------------------------------------------------------------------\n";
    for($i = 0;$i <= $rowCount; $i++)
    {
        for($j = 0;$j < 59; $j++)
        {
            print $siteIndex[$j] , "  =  ", $array[$i][$j], "\n"; 
        }
        <STDIN>;
        print "\n";
    } 
    #   Log the 2 dimensional array content to Status and Log files.    
    for($i = 0;$i <= $rowCount; $i++)
    {
        my $logFilereturn;
        $logFilereturn = ilog_setLogInformation('INT_INFO',"","$siteIndex[0] => $array[$i][0]",'');
        if(!($logFilereturn))
        {
            exit(0);            
        }
        for($j = 1;$j < $maxColumn; $j++)
        {
            $logFilereturn= ilog_setLogInformation('INT_INFO',"","$siteIndex[$j] => $array[$i][$j]",'');
            if(!($logFilereturn))
            {               
                exit(0);                
            }
        }
        $logFilereturn = ilog_setLogInformation('INT_INFO',"","-------------------------------------------------------------------------------------------------------------------------");
    } 
    return 1;
}

#######################################################################################################################
#
# Method Name   : pars_printArraydir
#
# Description   : The function is used to print the array content wrt the per directory configuration 
#
# Input         : None
#
# OutPut        : None
#
# Status        : None
#
#######################################################################################################################
sub pars_printArraydir
{
    my $value;
    my $cnt  = 0;
    my $i;
    my $j;
    print "Directory Array\n";
    print "===============\n";
    <STDIN>;
    print "\n--------------------------------------------------------------------------\n";
    for($i = 0; $i <= $rowDirCount; $i++)
    {
        for($j = 0; $j < 59; $j++)
        {
            print $siteIndex[$j] , "  =  ", $arrayDir[$i][$j], "\n"; 
        }
        <STDIN>;
        print "\n";
    } 
}

#######################################################################################################################
#
# Method Name   : pars_IPSelected
#
# Description   : This function is used to determine whether the particular site found in httpd.conf is selected for 
#                 migration by the tool user
#
# Input         : Site name as found in HTTPD.conf
#
# OutPut        : 
#                 1 if the sitename is found
#                 0 if the sitename is NOT found    
#
# Status        : None
#
#######################################################################################################################
sub pars_IPSelected
{    
    my @tmpArray;
    my $recoveryFile = $ResourceFile;
    eval
    {
        open RECOVERYHANDLE ,$recoveryFile or die 'ERR_FILE_OPEN';
    };
    if($@)
    {
        if($@=~/ERR_FILE_OPEN/)
        {   
            # log error and exit tool           
            ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_OPEN,__LINE__);       
            return FALSE;            
        }        
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_OPEN,'');
    }
    while ($lineContent = <RECOVERYHANDLE>) 
    {
        
        if($lineContent =~ /^\[/)
        {
            $lineContent =~ s/\[//;
            $lineContent =~ s/\]//;
            $lineContent =~ s/^\s+//;
            $lineContent =~ s/\s+$//;
            if($lineContent =~ /^LISTEN/)
            {
                $lineContent = <RECOVERYHANDLE>;
                @tmpArray = split /=/, $lineContent;
                $ipAddress = $tmpArray[1];
                eval
                {
                    close RECOVERYHANDLE or die 'ERR_FILE_CLOSE';   
                    
                };
                if($@)
                {
                    if($@=~/ERR_FILE_CLOSE/)
                    {
                        # log 'file close error' and continue                       
                        ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_CLOSE,__LINE__);
                    }                    
                }
                else
                {
                    ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_CLOSE,'');
                }
                
                return 1;
            }           
        }
    }
    eval
    {
        close RECOVERYHANDLE or die 'ERR_FILE_CLOSE';
    };
    if($@)
    {
        if($@=~/ERR_FILE_CLOSE/)
        {   
            # log 'file close error' and continue           
            ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_CLOSE,__LINE__);
        }        
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_CLOSE,'');
    }
    
    return 0; 
}

# populates the $array global variable...
sub pars_siteHasValidFrameworkDb
{
    my $i = shift;
    my $documentRoot = $array[$i][DOCUMENTROOT];
    my $strSiteName = $array[$i][SITENAME];
    my $framework = "";
    if ($DEBUG_MODE) { ilog_print(1,"\nDEBUG: pars_siteHasValidFrameworkDb [i:$i][strSiteName:$strSiteName][documentRoot:$documentRoot]\n"); }
    if (!(-d $documentRoot))
    {
        # TODO: why is this empty??
        return;
    }

    my @files = File::Find::Rule->file()
                ->name("wp-config.php")
                ->extras({ follow => 1 })
                ->in($documentRoot);
    if (@files > 0)
    {
        $framework = WORDPRESS;
        $array[$i][FRAMEWORK] = $framework;
    }
    else
    {
        @files = File::Find::Rule->file()
            ->name("settings.php")
            ->extras({ follow => 1 })
            ->in($documentRoot);
        if (@files > 0)
        {
            $framework = DRUPAL;
            $array[$i][FRAMEWORK] = $framework;
        }
        else
        {
            @files = File::Find::Rule->file()
                ->name("configuration.php")
                ->extras({ follow => 1 })
                ->in($documentRoot);
            if (@files > 0)
            {
                $framework = JOOMLA;
                $array[$i][FRAMEWORK] = $framework;        
            }
        }
    }
    
    if (!$framework)
    {
        return;
    }

    my $strYesOrNo =" ";
    while($strYesOrNo!~/^\s*[YynN]\s*$/)
    {
        ilog_printf(1, "\n    $framework site detected, would you like to automatically create and migrate the database [$strSiteName]? (Y/N):");
        chomp($strYesOrNo = <STDIN>);
        ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO)
            if ($strYesOrNo!~/^\s*[YynN]\s*$/);
    }
    
    $array[$i][MYSQL] = ($strYesOrNo=~/^\s*[Yy]\s*$/);
    # TODO: more accurate way to make sure that this is the root config
    my $configFile = $files[0];
    $array[$i][CONFIGFILE] = $configFile;
    if (!$array[$i][MYSQL])
    {
        return;
    }    
    
    my $dbName;
    my $dbUser;
    my $dbPassword;
    my $dbHost;
    my $strCurWorkingFolder = &utf_getCurrentWorkingFolder();
    #get session name
    my $strSessionName = &ilog_getSessionName();
    #form the complete working folder
    my $workingFolder = $strCurWorkingFolder . '/' . $strSessionName;

    if ($framework eq WORDPRESS)
    {
        `php read_wp_settings.php "$configFile" "$workingFolder/${framework}-settings.txt";`;        
    }
    elsif ($framework eq DRUPAL)
    {
        `php read_drupal_settings.php "$configFile" "$workingFolder/${framework}-settings.txt";`;        
    }
    elsif ($framework eq JOOMLA)
    {
        `php read_joomla_settings.php "$configFile" "$workingFolder/${framework}-settings.txt";`;
    }
    else
    {
        # we have a bug...
        ilog_print(1,"\nERROR: Unrecognized framework: $framework\n");
        return 0;
    }

    open my $configFile, '<', "$workingFolder/${framework}-settings.txt" or die "Can't read ${framework}-settings.txt: $!";
    while (my $line = <$configFile>)
    {
        my @tempSplit = split('=', $line);
        my $tempValue = @tempSplit[1];
        chomp($tempValue);
        if ($line =~ /DB_NAME/)
        {
            # $dbName = $tempValue;
            $array[$i][CONFIGFILE] = $tempValue;
        }
        if ($line =~ /DB_USER/)
        {
            # $dbUser = $tempValue;
            $array[$i][DB_USER] = $tempValue;
        }
        if ($line =~ /DB_PASSWORD/)
        {
            # $dbPassword = $tempValue;
            $array[$i][DB_PASSWORD] = $tempValue;
        }
        if ($line =~ /DB_HOST/)
        {
            # $dbHost = $tempValue;
            $array[$i][DB_HOST] = $tempValue;
        }
        if ($line =~ /WP_SITEURL/)
        {
            # $wpSiteurl = $tempValue;
            $array[$i][WP_SITEURL] = $tempValue;
        }
        if ($line =~ /INCLUDED_FILES/)
        {
            # @files = split /;/,$tempValue;
            $array[$i][INCLUDED_FILES] = $tempValue;
        }
    }
}

#######################################################################################################################
#
# Method Name   : pars_siteHasDb
#
#######################################################################################################################
sub pars_siteHasDb
{
    my $siteName = shift;
    $siteName =~ s/^\s+//;
    $siteName =~ s/\s+$//;
    my @tmpArray;
    my $recoveryFile = $ResourceFile;
    eval
    {
        open RECOVERYHANDLE ,$recoveryFile or die 'ERR_FILE_OPEN';
    };
    if($@)
    {
        if($@=~/ERR_FILE_OPEN/)
        {
            ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_OPEN,__LINE__);       
            return FALSE;                                                           
        }   
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_OPEN,'');
    }
    while ($lineContent = <RECOVERYHANDLE>) 
    {
        if($lineContent =~ /^\[/)
        {
            $lineContent =~ s/\[//;
            $lineContent =~ s/\]//;
            $lineContent =~ s/^\s+//;
            $lineContent =~ s/\s+$//;
            if($lineContent eq $siteName)
            {
                while ($lineContent = <RECOVERYHANDLE>) 
                {                   
                    if($lineContent =~ /^MySQL/)
                    {
                        return $lineContent =~ /yes/;
                    }
                }
                eval
                {
                    close RECOVERYHANDLE or die 'ERR_FILE_CLOSE';           
                };
            }       
        }
    }

    return 0; 
}

#-------------------------------------------------------------------------
# Method Name       :        pars_AskSelectSites
# Description       :        The method asks the user if they want to migrate
#                            the site.
# Input             :        Sitename
# Return Value      :        boolean
#-------------------------------------------------------------------------
sub pars_AskSelectSites
{
    my $strYesOrNo = "";
    my $strSiteName = shift;
    my $documentRoot = shift;
    my $promptyn;    
    ilog_print(1,"\n\n");
    ui_printline();
    ilog_printf(MSG_SITE_DETAILS,$strSiteName);
    ui_printline();
    ilog_printf(MSG_SOURCE_PATH, $documentRoot);
    $strYesOrNo =" ";
    while($strYesOrNo!~/^\s*[YynN]\s*$/)
    {           
        ilog_printf(MSG_MIGRATE_SITE, $strSiteName);
        chomp($strYesOrNo = <STDIN>);
        ilog_print(0,ERR_INVALID_INPUT.ERR_ONLY_YES_OR_NO) 
            if ($strYesOrNo!~/^\s*[YynN]\s*$/);
    }
    return 0 if ($strYesOrNo=~/^\s*[Nn]\s*$/);   # exit - site was not selected
    return 1; # site was selected
}

#######################################################################################################################
#
# Method Name   : pars_siteSelected
#
# Description   : This function is used to determine whether the particular site found in httpd.conf is selected for 
#                 migration by the tool user
#
# Input         : Site name as found in HTTPD.conf
#
# OutPut        : 
#                 1 if the sitename is found
#                 0 if the sitename is NOT found    
#
# Status        : None
#
#######################################################################################################################
sub pars_siteSelected
{
    my $siteName = shift;
    $siteName =~ s/^\s+//;
    $siteName =~ s/\s+$//;
    my @tmpArray;
    my $recoveryFile = $ResourceFile;
    eval
    {
        open RECOVERYHANDLE ,$recoveryFile or die 'ERR_FILE_OPEN';
    };
    if($@)
    {
        if($@=~/ERR_FILE_OPEN/)
        {   
            # log error and exit tool           
            ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_OPEN,__LINE__);       
            return FALSE;            
        }
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_OPEN,'');
    }

    while ($lineContent = <RECOVERYHANDLE>) 
    {
        if($lineContent =~ /^\[/)
        {
            $lineContent =~ s/\[//;
            $lineContent =~ s/\]//;
            $lineContent =~ s/^\s+//;
            $lineContent =~ s/\s+$//;
            if($lineContent eq $siteName)
            {
                while ($lineContent = <RECOVERYHANDLE>) 
                {                   
                    if($lineContent =~ /^DestinationPath/)
                    {
                        @tmpArray = split /=/,$lineContent;
                        $destinationPath = $tmpArray[1];
                        if($destinationPath =~ /[A-Za-z]:$/)
                        {
                            chomp($destinationPath); 
                            $destinationPath = $destinationPath . "\\\\";                           
                        }
                        elsif($destinationPath =~ /[A-Za-z]:\\$/)
                        {
                            chomp($destinationPath); 
                            $destinationPath = $destinationPath . "\\";                         
                        }

                        chomp($destinationPath);
                        last;
                    }
                }
                eval
                {
                    close RECOVERYHANDLE or die 'ERR_FILE_CLOSE';                    
                };
                if($@)
                {
                    if($@=~/ERR_FILE_CLOSE/)
                    {   
                        # log 'file close error' and continue                       
                        ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_CLOSE,__LINE__);
                    }                    
                }
                else
                {
                    ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_CLOSE,'');
                }
                
                return 1;
            }            
        }
    }

    eval
    {
        close RECOVERYHANDLE or die 'ERR_FILE_CLOSE';        
    };
    if($@)
    {
        if($@=~/ERR_FILE_CLOSE/)
        {   
            # log 'file close error' and continue           
            ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_CLOSE,__LINE__);            
        }        
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_CLOSE,'');
    }

    return 0; 
}

#######################################################################################################################
#
# Method Name   : pars_getNextDirective
#
# Description   : This function is used to read the directive values from HTTPD.conf file
#
# Input         : None
#
# OutPut        : None
#
# Status        : None
#
#######################################################################################################################
sub pars_getNextDirective
{
    while ($lineContent = <CONFIGHANDLE>) 
    {
        chomp($lineContent);
        $lineContent =~ s/^\s+//;
        if($lineContent ne "")
        {
            if($lineContent !~ /^#/)
            {
                if($lineContent =~ /</)
                {
                    $lineContent =~ s/<//;
                    $lineContent =~ s/>//;
                    $lineContent =~ s/^\s+//;
                }
                if($lineContent =~ /\\$/)
                {
                    $lineContent =~ s/\\$//;
                    @Tmp = split / /,$lineContent;
                    $directiveName  = $Tmp[0]; 
                    $directiveValue = '';
                    foreach $temp (@Tmp) 
                    {
                        if($temp ne $directiveName)
                        {
                            $directiveValue = $directiveValue ." " . $temp;
                        }
                    }

                    while($lineContent = <CONFIGHANDLE>)
                    {
                        chomp($lineContent);
                        if($lineContent !~ /\\$/)
                        {
                            
                            $directiveValue = $directiveValue . " " . $lineContent;
                            $directiveValue =~ s/\s+/ /g;       
                            chomp($directiveValue);
                            return 1;
                        }
                        $lineContent =~ s/\\$//;
                        $directiveValue = $directiveValue . " " . $lineContent;
                        
                    }
                }

                @Tmp = split / /,$lineContent;
                $directiveName  = $Tmp[0]; 
                $directiveValue = '';
                foreach $temp (@Tmp) 
                {
                    if($temp ne $directiveName)
                    {
                        $directiveValue = $directiveValue ." " . $temp;
                    }
                }
                $directiveValue =~ s/^\s+//m;
                $directiveValue =~ s/\s+$//m;
                $directiveValue =~ s/^"//;
                $directiveValue =~ s/"$//;
                chomp($directiveValue);
                
                return 1;
            }     
        }       
    }
    if($flag)
    {
        my $temp;
        if ($#includeFileName == 0)
        {           
            $flag = 0;            
        }        
        
        $configFile = pop(@includeFileName);        
        eval
        {            
            open CONFIGHANDLE ,$configFile or die 'ERR_FILE_OPEN';
            binmode(CONFIGHANDLE);
        };
        if($@)
        {
            if($@=~/ERR_FILE_OPEN/)
            {   
                # log error and exit tool               
                ilog_setLogInformation('INT_ERROR',$configFile,ERR_FILE_OPEN,__LINE__);     
                return FALSE;                
            }            
        }
        else
        {
            ilog_setLogInformation('INT_INFO',$configFile,MSG_FILE_OPEN,'');
        }
        
        my $filePointer;
        $filePointer = pop(@includeFilePointer);        
        seek CONFIGHANDLE , $filePointer , 0 ;
        while ($lineContent = <CONFIGHANDLE>) 
        {
            chomp($lineContent);
            $lineContent =~ s/^\s+//;
            
            if($lineContent ne "")
            {
                if($lineContent !~ /^#/)
                {
                    if($lineContent =~ /</)
                    {
                        $lineContent =~ s/<//;
                        $lineContent =~ s/>//;
                        $lineContent =~ s/^\s+//;
                    }
                    if($lineContent =~ /\\$/)
                    {
                        $lineContent =~ s/\\$//;
                        @Tmp = split / /,$lineContent;
                        $directiveName  = $Tmp[0]; 
                        $directiveValue = '';
                        foreach $temp (@Tmp) 
                        {
                            if($temp ne $directiveName)
                            {
                                $directiveValue = $directiveValue ." " . $temp;
                            }
                        }

                        while($lineContent = <CONFIGHANDLE>)
                        {
                            chomp($lineContent);
                            if($lineContent !~ /\\$/)
                            {
                                
                                $directiveValue = $directiveValue . " " . $lineContent;
                                $directiveValue =~ s/\s+/ /g;       
                                chomp($directiveValue);
                                return 1;
                            }

                            $lineContent =~ s/\\$//;
                            $directiveValue = $directiveValue . " " . $lineContent;                            
                        }
                    }

                    @Tmp = split / /,$lineContent;
                    $directiveName  = $Tmp[0]; 
                    $directiveValue = '';
                    foreach $temp (@Tmp) 
                    {
                        if($temp ne $directiveName)
                        {
                            $directiveValue = $directiveValue ." " . $temp;
                        }
                    }

                    $directiveValue =~ s/^\s+//m;
                    $directiveValue =~ s/\s+$//m;
                    $directiveValue =~ s/^"//;
                    $directiveValue =~ s/"$//;
                    chomp($directiveValue);
                    return 1;
                }     
            }       
        }
    }

    chomp($directiveValue);
    return 0;
}

#######################################################################################################################
#
# Method Name   : pars_getNextDirectivehtaccess
#
# Description   : This function is used to read the directive values from .HTACCESS file
#
# Input         : None
#
# OutPut        : None
#
# Status        : None
#
#######################################################################################################################
sub pars_getNextDirectivehtaccess
{
    while ($lineContent = <HTACCESSHANDLE>) 
    {
        chomp($lineContent);
        $lineContent =~ s/^\s+//;
        if($lineContent ne "")
        {
            if($lineContent !~ /^#/)
            {
                if($lineContent =~ /</)
                {
                    $lineContent =~ s/<//;
                    $lineContent =~ s/>//;
                    $lineContent =~ s/^\s+//;
                }
                if($lineContent =~ /\\$/)
                {
                    $lineContent =~ s/\\$//;
                    @Tmp = split / /,$lineContent;
                    $directiveName  = $Tmp[0]; 
                    $directiveValue = '';
                    foreach $temp (@Tmp) 
                    {
                        if($temp ne $directiveName)
                        {
                            $directiveValue = $directiveValue ." " . $temp;
                        }
                    }
                    
                    while($lineContent = <HTACCESSHANDLE>)
                    {
                        chomp($lineContent);
                        if($lineContent !~ /\\$/)
                        {                            
                            $directiveValue = $directiveValue . " " . $lineContent;
                            $directiveValue =~ s/\s+/ /g;       
                            return 1;
                        }
                        $lineContent =~ s/\\$//;
                        $directiveValue = $directiveValue . " " . $lineContent;
                    }
                }
                @Tmp = split / /,$lineContent;
                $directiveName  = $Tmp[0]; 
                $directiveValue = '';
                
                foreach $temp (@Tmp) 
                {
                    if($temp ne $directiveName)
                    {
                        $directiveValue = $directiveValue ." " . $temp;
                        
                    }
                }

                $directiveValue =~ s/^\s+//m;
                $directiveValue =~ s/\s+$//m;
                $directiveValue =~ s/^"//;
                $directiveValue =~ s/"$//;
                chomp($directiveValue);
                return 1;
            }     
        }       
    }

    return 0;
}


#######################################################################################################################
#
# Method Name   : pars_setHtaccess
#
# Description   : Populate the 2D array with the Htaccess related directives
#
# Input         : None
#
# OutPut        : None
#
# Status        : None
# 
#
#######################################################################################################################
sub pars_setHtaccess
{
    #**************************************************************************************************
    # Start processing for .htaccess as follows : 
    # Enumerate the sites selected for migration
    # For each site depending on the value of AllowOverride option start processing 
    # the Folder represented by the Documentroot directive and the file to be processed is indicated by 
    # the AccessFilename directive
    #**************************************************************************************************
    my $Indexi;
    my $Indexj;
    my @Listing;
    my $singleEntry;
    my $htaccessfilename;
    my @splitEntry;
    my $finalPath;
    my $start = 0;
    if(&pars_siteSelected("Default Web Site"))
    {
        $start = 0;
    }
    else
    {
        $start = 1;
    }

    for($Indexi = $start; $Indexi <= $rowCount; $Indexi++)
    {
        # Get the .Htaccessfile for the directory and the sub directory
        @Listing = pars_GetDirlistinght($array[$Indexi][DOCUMENTROOT]);
        $htaccessfilename = $array[$Indexi][ACCESSFILENAME];
        $finalPath = $array[$Indexi][DOCUMENTROOT];
        foreach $singleEntry (@Listing)
        {
            @splitEntry = split / /, $singleEntry;
            if($singleEntry =~ /:$/)
            {
                $finalPath = $singleEntry;
            }
            my $fileNameHT;
            $fileNameHT = $splitEntry[$#splitEntry];
            chomp($fileNameHT);
            if($htaccessfilename eq $fileNameHT)
            {                
                #************************************************************
                # Get the path for this file
                # search the Array folder for the allowoveride option
                # if none is found then the default i.e., "All" is considered 
                # if found then the directive is dealt as follow's
                #************************************************************                
                $finalPath =~ s/:$//;
                chomp($finalPath);
                my $indexToReplace;
                my $ret;
                ($ret,$indexToReplace) = pars_directoryFound($finalPath,$array[$Indexi][SITENAME]);
                if($ret)
                {
                    #*************************************************************************
                    # There is a entry for this folder in the 2d array.
                    # Read the AllowOverride value
                    # Depending on the AllowOverride value replace this row in the $arrayDir
                    # Ftp the .htaccess file at this place to replace the array values
                    #*************************************************************************
                    my $filenameFtp = $finalPath . "/" . $htaccessfilename;
                    pars_GetFileFromSource($filenameFtp,$htaccessfilename);
                    my @allowOverride = split / /, $arrayDir[$indexToReplace][ALLOWOVERRIDE];
                    my $Indexj = 0;
                    my $tempValue;
                    my $overWrite = 0;
                    foreach $tempValue (@allowOverride)
                    {
                        if($tempValue eq "AuthConfig")
                        {                           
                            if(!$overWrite)
                            {
                                for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                {
                                    $arrayDir[$indexToReplace][$Indexj] = "";
                                }

                                $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "On";
                                $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                ++$overWrite;
                            }
                            eval
                            {                                
                                open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                
                            };
                            if($@)
                            {
                                if($@=~/ERR_FILE_OPEN/)
                                {
                                    # log error and exit tool                                    
                                    ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                    return FALSE;                                    
                                }                                
                            }
                            else
                            {
                                ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                            }
                            
                            while (&pars_getNextDirectivehtaccess() == 1)
                            {                               
                                if($directiveName eq "AuthGroupFile")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][AUTHGROUPFILE] = $directiveValue;
                                }
                                
                                if($directiveName eq "AuthName")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][AUTHNAME] = $directiveValue;
                                }
                                if($directiveName eq "AuthType")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][AUTHTYPE] = $directiveValue;
                                }
                                if($directiveName eq "AuthUserFile")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][AUTHUSERFILE] = $directiveValue;
                                }
                            }
                        }

                        if($tempValue eq "FileInfo")
                        {
                            if(!$overWrite)
                            {
                                for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                {
                                    $arrayDir[$indexToReplace][$Indexj] = "";
                                }
                                $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "Off";
                                $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                ++$overWrite;
                            }
                            eval
                            {                                
                                open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                
                            };
                            if($@)
                            {
                                if($@=~/ERR_FILE_OPEN/)
                                {   
                                    # log error and exit tool
                                    ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                    return FALSE;                                    
                                }                                
                            }
                            else
                            {
                                ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                            }
                            
                            while (&pars_getNextDirectivehtaccess() == 1)
                            {
                                
                                if($directiveName eq "AddEncoding")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][ADDENCODING] = $arrayDir[$indexToReplace][ADDENCODING] . $directiveValue . "|";
                                }
                                
                                if($directiveName eq "DefaultType")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    
                                    my $temp = $directiveValue . " " . ".*";
                                    $arrayDir[$indexToReplace][ADDTYPE] = $arrayDir[$indexToReplace][ADDTYPE] . $temp . "|";
                                }
                                if($directiveName eq "ErrorDocument")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][ERRORDOCUMENT] = $arrayDir[$indexToReplace][ERRORDOCUMENT] . $directiveValue . "|";
                                }
                                if($directiveName eq "AddType")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][ADDTYPE] = $arrayDir[$indexToReplace][ADDTYPE] . $directiveValue . "|";
                                }
                            }
                        }
                        if($tempValue eq "Indexes")
                        {
                            if(!$overWrite)
                            {
                                for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                {
                                    $arrayDir[$indexToReplace][$Indexj] = "";
                                }
                                $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "Off";
                                $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                ++$overWrite;
                            }
                            eval
                            {                                
                                open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                
                            };
                            if($@)
                            {
                                if($@=~/ERR_FILE_OPEN/)
                                {
                                    # log error and exit tool                                    
                                    ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                    return FALSE;                                    
                                }                                
                            }
                            else
                            {
                                ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                            }
                            
                            while (&pars_getNextDirectivehtaccess() == 1)
                            {
                                if($directiveName eq "DirectoryIndex")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][DIRECTORYINDEX] = $directiveValue;
                                    $arrayDir[$indexToReplace][DIRECTORYINDEX] =~ s/ /,/g;
                                }
                            }
                        }

                        if($tempValue eq "Limit")
                        {                            
                            #*****************************************************************************************                          
                            #   Since the AllowOveride Value is Limit,
                            #   only the *Allow* *Deny* and *Order* directives are considered from the .htaccess files 
                            #   and the rest of the directives are discarded.
                            #*****************************************************************************************
                            if(!$overWrite)
                            {
                                for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                {
                                    $arrayDir[$indexToReplace][$Indexj] = "";
                                }
                                $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "Off";
                                $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                ++$overWrite;
                            }
                            eval
                            {                                
                                open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                
                            };
                            if($@)
                            {
                                if($@=~/ERR_FILE_OPEN/)
                                {   
                                    # log error and exit tool                                    
                                    ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                    return FALSE;                                    
                                }                                
                            }
                            else
                            {
                                ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                            }

                            while (&pars_getNextDirectivehtaccess()==1)
                            {                                
                                if($directiveName eq "Allow")
                                {
                                    # Not migrated. 
                                }
                                if($directiveName eq "Deny")
                                {
                                    
                                    #Equivalent IIS tag => MimeMap
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][DENY] =~ s/^\s+//;
                                    $arrayDir[$indexToReplace][DENY] =~ s/^\s+//;
                                    $arrayDir[$indexToReplace][DENY] = $directiveValue;
                                }
                                if($directiveName eq "Order")
                                {
                                    #Equivalent IIS tag => Not applicable
                                    
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][ORDER] =~ s/^\s+//;
                                    $arrayDir[$indexToReplace][ORDER] =~ s/^\s+//;
                                    $arrayDir[$indexToReplace][ORDER] = $directiveValue;
                                }
                            }
                        }

                        if($tempValue eq "Options")
                        {
                            #*****************************************************************************************                          
                            #   Since the AllowOveride Value is Options, 
                            #   only the *Options* and *XBitHack* directives are considered from the .htaccess files 
                            #   and the rest of the directives are discarded.
                            #*****************************************************************************************                          
                            if(!$overWrite)
                            {
                                for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                {
                                    $arrayDir[$indexToReplace][$Indexj] = "";
                                }
                                $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "Off";
                                $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                ++$overWrite;
                            }
                            eval
                            {                                
                                open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                
                            };
                            if($@)
                            {
                                if($@=~/ERR_FILE_OPEN/)
                                {   
                                    # log error and exit tool                                    
                                    ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                    return FALSE;                                    
                                }                                
                            }
                            else
                            {
                                ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                            }
                            
                            while (&pars_getNextDirectivehtaccess() == 1)
                            {                                
                                if($directiveName eq "Options")
                                {
                                    # Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][OPTIONS] =~ s/^\s+//;
                                    $arrayDir[$indexToReplace][OPTIONS] =~ s/^\s+//;
                                    $arrayDir[$indexToReplace][OPTIONS] = $arrayDir[$indexToReplace][OPTIONS] . " " . $directiveValue;
                                }
                                
                                if($directiveName eq "XBitHack")
                                {
                                    # Not migrated. 
                                }
                            }
                        }
                        if($tempValue eq "All")
                        {                           
                            #******************************************************************                         
                            #   Since the AllowOveride Value is All,
                            #   all the directive present in the HTACCESS files are considered
                            #******************************************************************                         
                            
                            if(!$overWrite)
                            {
                                my $tmpDocumentRoot = $arrayDir[$indexToReplace][DOCUMENTROOT];                                
                                for($Indexj=3; $Indexj < ($maxColumn-2); $Indexj++)
                                {
                                    $arrayDir[$indexToReplace][$Indexj] = "";
                                }
                                $arrayDir[$indexToReplace][DOCUMENTROOT] = $tmpDocumentRoot;
                                $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "On";
                                $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                ++$overWrite;
                                
                            }
                            
                            eval
                            {                                
                                open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                
                            };
                            if($@)
                            {
                                if($@=~/ERR_FILE_OPEN/)
                                {   
                                    # log error and exit tool                                    
                                    ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                    return FALSE;                                    
                                }                                
                            }
                            else
                            {
                                ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                            }
                            
                            while (&pars_getNextDirectivehtaccess() == 1)
                            {
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                
                                if($directiveName eq "Options")
                                {                                    
                                    #Equivalent IIS tag => AccessExecute                                    
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][OPTIONS] = $arrayDir[$indexToReplace][OPTIONS] . $directiveValue . " ";
                                }
                                if($directiveName eq "Order")
                                {                                    
                                    #Equivalent IIS tag => Not applicable                                    
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][ORDER] = $directiveValue;
                                }
                                if($directiveName eq "AddEncoding")
                                {
                                    #Equivalent IIS tag => MimeMap
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][ADDENCODING] = $arrayDir[$indexToReplace][ADDENCODING] . $directiveValue . "|";
                                }
                                if($directiveName eq "AddType")
                                {
                                    #Equivalent IIS tag => MimeMap
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    
                                    $arrayDir[$indexToReplace][ADDTYPE] = $arrayDir[$indexToReplace][ADDTYPE] . $directiveValue . "|";
                                }
                                if($directiveName eq "AuthGroupFile")
                                {                                    
                                    #Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][AUTHGROUPFILE] = $directiveValue;
                                }
                                if($directiveName eq "AuthName")
                                {                                    
                                    #Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;                        
                                    $arrayDir[$indexToReplace][AUTHNAME] = $directiveValue;
                                    
                                }
                                if($directiveName eq "AuthType")
                                {                                    
                                    #Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][AUTHTYPE] = $directiveValue;
                                }
                                if($directiveName eq "AuthUserFile")
                                {                                    
                                    #Equivalent IIS tag => Not Applicable
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][AUTHUSERFILE] = $directiveValue;
                                }
                                if($directiveName eq "DefaultType")
                                {
                                    #Equivalent IIS tag => MimeMap
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    
                                    my $temp = $directiveValue . " " . ".*";
                                    $arrayDir[$indexToReplace][ADDTYPE] = $arrayDir[$indexToReplace][ADDTYPE] . $temp . "|";
                                    
                                }
                                if($directiveName eq "Deny")
                                {
                                    #Equivalent IIS tag => MimeMap
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][DENY] = $directiveValue;
                                }
                                
                                if($directiveName eq "DirectoryIndex")
                                {
                                    
                                    #Equivalent IIS tag => EnableDirBrowsing;
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][DIRECTORYINDEX] = $directiveValue;
                                    $arrayDir[$indexToReplace][DIRECTORYINDEX] =~ s/ /,/g;
                                    
                                }
                                if($directiveName eq "ErrorDocument")
                                {
                                    #Equivalent IIS tag => HttpErrors
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][ERRORDOCUMENT] = $arrayDir[$rowDirCount][ERRORDOCUMENT] . $directiveValue . " ";
                                }
                                if($directiveName eq "ExpiresActive")
                                {
                                    #Equivalent IIS tag => HttpExpires
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][EXPIRESACTIVE] = $directiveValue;
                                }
                                
                                if($directiveName eq "HostnameLookups")
                                {
                                    #Equivalent IIS tag => EnableReverseDNS
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = $directiveValue;
                                }
                                if($directiveName eq "IdentityCheck")
                                {
                                    #Equivalent IIS tag => LogExtFileUserName
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $arrayDir[$indexToReplace][IDENTITYCHECK] = $directiveValue;
                                    
                                }
                                if($directiveName eq "Header")
                                {
                                    #Equivalent IIS tag => HttpCustomHeaders
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    $directiveValue =~ s/"//g;
                                    if($directiveValue =~ /^set/)
                                    {
                                        $arrayDir[$indexToReplace][HEADER] = $arrayDir[$indexToReplace][HEADER] . $directiveValue . "|" ;
                                    }
                                }
                                if($directiveName eq "Files")
                                {
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    my $numPass;
                                    $numPass  = 1;
                                    if($directiveValue =~ /^~/)
                                    {
                                        $fileMatch = 1;
                                        my @temp;
                                        @temp = split / /,$directiveValue;
                                        $directiveName = "FilesMatch";
                                        $directiveValue = $temp[1];
                                        
                                        chomp($directiveValue);
                                        $directiveValue =~ s/"//g;
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        
                                    }
                                    else
                                    {
                                        my @file;
                                        my $fileList;
                                        my @fileEntire;
                                        my $temp;
                                        my $counter = 0;
                                        my @Listing;
                                        my $singleEntry;
                                        my @fileEntire;
                                        my @filePath;
                                        my $singleEntry;
                                        my $count = 0;
                                        my $files;
                                        my @tempArray;
                                        @Listing = pars_GetDirlistinght("$arrayDir[$indexToReplace][DIRECTORY]");
                                        my $rootDir;
                                        $rootDir = $arrayDir[$indexToReplace][DIRECTORY];
                                        
                                        foreach $singleEntry (@Listing)
                                        {                                            
                                            if($singleEntry =~ /:$/)
                                            {
                                                #Dont do anything
                                                $singleEntry =~ s/:$//;
                                                $rootDir = $singleEntry;
                                                chomp($rootDir);                                                
                                            }
                                            elsif($singleEntry =~ /^total/)
                                            {                                                
                                                #Dont do anything                                                
                                            }
                                            elsif($singleEntry =~ /^d/)
                                            {                                                
                                                #Dont do anything                                                
                                            }
                                            elsif($singleEntry eq "")
                                            {                                                
                                                #Dont do anything                                                
                                            }
                                            else
                                            {
                                                $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                                $filePath[$count] = $rootDir;
                                                $count++;
                                            }
                                        }
                                        my $indI = 0;
                                        my $dirValue = $directiveValue;
                                        foreach $temp (@fileEntire)
                                        {
                                            $directiveValue =~ s/"//g;
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            
                                            if($temp eq $dirValue)
                                            {
                                                if($numPass)
                                                {                                                    
                                                    $files = $temp;
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    ++$filecount;
                                                    $files[$filecount][SITENAME] = $arrayDir[$indexToReplace][SITENAME];
                                                    $files[$filecount][DOCUMENTROOT] = $arrayDir[$indexToReplace][DOCUMENTROOT];
                                                    $files[$filecount][FILESMATCH] = $files;
                                                    $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                                    $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                                    $files[$filecount][IDENTITYCHECK] = "Off";
                                                    $files[$filecount][ALLOWOVERRIDE] = "All";
                                                    while (&pars_getNextDirectivehtaccess() == 1)
                                                    {
                                                        if($directiveName eq "/Files")
                                                        {
                                                            last;
                                                        }
                                                        if($directiveName eq "Options")
                                                        {
                                                            #Equivalent IIS tag => AccessExecute
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                                        }
                                                        if($directiveName eq "Order")
                                                        {
                                                            #Equivalent IIS tag => Not applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ORDER] = $directiveValue;
                                                        }
                                                        if($directiveName eq "AddEncoding")
                                                        {
                                                            #Equivalent IIS tag => MimeMap
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                                            
                                                        }
                                                        if($directiveName eq "AddType")
                                                        {
                                                            #Equivalent IIS tag => MimeMap
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                                            
                                                        }
                                                        if($directiveName eq "AuthName")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][AUTHNAME] = $directiveValue;
                                                        }
                                                        if($directiveName eq "AuthType")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][AUTHTYPE] = $directiveValue;
                                                        }
                                                        if($directiveName eq "AuthUserFile")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            if($directiveValue =~ /^\//)
                                                            {
                                                                $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                                            }
                                                            else
                                                            {
                                                                
                                                                $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                                            }
                                                            
                                                        }
                                                        if($directiveName eq "AuthGroupFile")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            if($directiveValue =~ /^\//)
                                                            {
                                                                $files[$filecount][AUTHGROUPFILE] = $directiveValue;                                                                
                                                            }
                                                            else
                                                            {                                                                
                                                                $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                                            }
                                                        }

                                                        if($directiveName eq "DefaultType")
                                                        {
                                                            #Equivalent IIS tag => MimeMap
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            
                                                            my $temp = $directiveValue . " " . ".*";
                                                            $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                                        }
                                                        if($directiveName eq "Deny")
                                                        {
                                                            #Equivalent IIS tag => MimeMap
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][DENY] = $directiveValue;
                                                        }
                                                        if($directiveName eq "DirectoryIndex")
                                                        {
                                                            #Equivalent IIS tag => EnableDirBrowsing;
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                                            $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                                        }
                                                        if($directiveName eq "ErrorDocument")
                                                        {
                                                            #Equivalent IIS tag => HttpErrors
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                                        }
                                                        if($directiveName eq "ExpiresActive")
                                                        {
                                                            #Equivalent IIS tag => HttpExpires
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                        }
                                                        if($directiveName eq "HostnameLookups")
                                                        {
                                                            #Equivalent IIS tag => EnableReverseDNS
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                                        }
                                                        if($directiveName eq "IdentityCheck")
                                                        {
                                                            #Equivalent IIS tag => LogExtFileUserName
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                                        }
                                                        if($directiveName eq "AllowOverride")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable.
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                                        }
                                                        if($directiveName eq "Header")
                                                        {
                                                            #Equivalent IIS tag => HttpCustomHeaders
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $directiveValue =~ s/"//g;
                                                            if($directiveValue =~ /^set/)
                                                            {
                                                                $files[$filecount][HEADER] = $files[$filecount][HEADER] . $directiveValue . "|" ;
                                                            }
                                                        }
                                                        if($directiveName eq "ExpiresActive")
                                                        {   
                                                            #Equivalent IIS tag => HttpExpires
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                        }
                                                    }
                                                    $numPass = 0;
                                                }
                                                else
                                                {
                                                    my $kk = 0;
                                                    my $jj = 0;
                                                    ++$filecount;
                                                    
                                                    for($kk = 0; $kk < $maxColumn;$kk++)
                                                    {
                                                        $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                                    }
                                                    
                                                    $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                                }
                                            }
                                            $indI++;
                                        }
                                    }
                                }
                                if($directiveName eq "FilesMatch")
                                {
                                    my @file;
                                    my $fileList;
                                    my @fileEntire;
                                    my $temp;
                                    my $counter = 0;
                                    my @Listing;
                                    my $singleEntry;
                                    my @fileEntire;
                                    my @filePath;
                                    my $singleEntry;
                                    my $count = 0;
                                    my $files;
                                    my @tempArray;
                                    my $numPass = 1;
                                    
                                    @Listing = pars_GetDirlistinght("$arrayDir[$indexToReplace][DIRECTORY]");
                                    my $rootDir;
                                    $rootDir = $arrayDir[$indexToReplace][DIRECTORY];
                                    foreach $singleEntry (@Listing)
                                    {
                                        
                                        if($singleEntry =~ /:$/)
                                        {
                                            #Dont do anything
                                            $singleEntry =~ s/:$//;
                                            $rootDir = $singleEntry;
                                            chomp($rootDir);
                                            
                                        }
                                        elsif($singleEntry =~ /^total/)
                                        {                                            
                                            #Dont do anything                                            
                                        }
                                        elsif($singleEntry =~ /^d/)
                                        {                                            
                                            #Dont do anything                                            
                                        }
                                        elsif($singleEntry eq "")
                                        {                                            
                                            #Dont do anything                                            
                                        }
                                        else
                                        {
                                            $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                            $filePath[$count] = $rootDir;
                                            $count++;
                                        }
                                    }
                                    my $indI = 0;
                                    my $dirValue = $directiveValue;
                                    foreach $temp (@fileEntire)
                                    {                                        
                                        $directiveValue =~ s/"//g;
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        
                                        if($temp =~ /$dirValue/)
                                        {
                                            if($numPass)
                                            {   
                                                $files = $temp;
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                ++$filecount;
                                                $files[$filecount][SITENAME] = $arrayDir[$indexToReplace][SITENAME];
                                                $files[$filecount][DOCUMENTROOT] = $arrayDir[$indexToReplace][DOCUMENTROOT];
                                                $files[$filecount][FILESMATCH] = $files;
                                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                                $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                                $files[$filecount][IDENTITYCHECK] = "Off";
                                                $files[$filecount][ALLOWOVERRIDE] = "All";
                                                while (&pars_getNextDirectivehtaccess() == 1)
                                                {
                                                    if($directiveName eq "/FilesMatch")
                                                    {
                                                        last;
                                                    }
                                                    if($fileMatch)
                                                    {
                                                        if($directiveName eq "/Files")
                                                        {                                                            
                                                            $fileMatch = 0;
                                                            last;
                                                        }
                                                    }
                                                    if($directiveName eq "Options")
                                                    {
                                                        #Equivalent IIS tag => AccessExecute
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                                    }
                                                    if($directiveName eq "Order")
                                                    {
                                                        #Equivalent IIS tag => Not applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ORDER] = $directiveValue;
                                                    }
                                                    if($directiveName eq "AddEncoding")
                                                    {
                                                        #Equivalent IIS tag => MimeMap
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                                    }
                                                    if($directiveName eq "AddType")
                                                    {
                                                        #Equivalent IIS tag => MimeMap
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                                    }
                                                    if($directiveName eq "AuthName")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][AUTHNAME] = $directiveValue;
                                                    }
                                                    if($directiveName eq "AuthType")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][AUTHTYPE] = $directiveValue;
                                                    }
                                                    if($directiveName eq "AuthUserFile")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        if($directiveValue =~ /^\//)
                                                        {
                                                            $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                                        }
                                                        else
                                                        {                                                            
                                                            $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                                        }                                                        
                                                    }
                                                    if($directiveName eq "AuthGroupFile")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        if($directiveValue =~ /^\//)
                                                        {
                                                            $files[$filecount][AUTHGROUPFILE] = $directiveValue;
                                                            
                                                        }
                                                        else
                                                        {
                                                            
                                                            $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                                        }
                                                    }
                                                    if($directiveName eq "DefaultType")
                                                    {
                                                        #Equivalent IIS tag => MimeMap
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        
                                                        my $temp = $directiveValue . " " . ".*";
                                                        $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                                    }
                                                    if($directiveName eq "Deny")
                                                    {
                                                        #Equivalent IIS tag => MimeMap
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][DENY] = $directiveValue;
                                                    }
                                                    if($directiveName eq "DirectoryIndex")
                                                    {
                                                        #Equivalent IIS tag => EnableDirBrowsing;
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                                        $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                                    }
                                                    if($directiveName eq "ErrorDocument")
                                                    {
                                                        #Equivalent IIS tag => HttpErrors
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                                    }
                                                    if($directiveName eq "ExpiresActive")
                                                    {
                                                        #Equivalent IIS tag => HttpExpires
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                    }
                                                    if($directiveName eq "HostnameLookups")
                                                    {
                                                        #Equivalent IIS tag => EnableReverseDNS
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                                    }
                                                    if($directiveName eq "IdentityCheck")
                                                    {
                                                        #Equivalent IIS tag => LogExtFileUserName
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                                    }
                                                    if($directiveName eq "AllowOverride")
                                                    {
                                                        #Equivalent IIS tag => Not Applicable.
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                                        
                                                    }
                                                    if($directiveName eq "Header")
                                                    {
                                                        #Equivalent IIS tag => HttpCustomHeaders
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $directiveValue =~ s/"//g;
                                                        if($directiveValue =~ /^set/)
                                                        {
                                                            $files[$filecount][HEADER] = $files[$filecount] . $directiveValue . "|" ;
                                                        }
                                                    }
                                                    if($directiveName eq "ExpiresActive")
                                                    {   
                                                        #Equivalent IIS tag => HttpExpires
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                    }
                                                }
                                                $numPass = 0;
                                            }
                                            else
                                            {
                                                my $kk = 0;
                                                my $jj = 0;
                                                ++$filecount;                                                
                                                for($kk = 0; $kk < $maxColumn;$kk++)
                                                {
                                                    $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                                }
                                                
                                                $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                                $files[$filecount][FILESMATCH] = $temp;
                                            }
                                        }
                                        $indI++;
                                    }
                                }
                            }
                        }
                        if($tempValue eq "None")
                        {
                            # Dont do anything.
                        }
                    }
                }
                else
                {
                    #*****************************************************************************************                          
                    # The Default value is all
                    # So create a Row in the $arrayDir populating the value read from the .htaccess file
                    #*****************************************************************************************                          
                    my $filenameFtp = $finalPath . "/" . $htaccessfilename;
                    pars_GetFileFromSource($filenameFtp,$htaccessfilename);
                    eval
                    {                        
                        open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';
                        
                    };
                    if($@)
                    {
                        if($@=~/ERR_FILE_OPEN/)
                        {
                            # log error and exit tool                            
                            ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                            return FALSE;                            
                        }                        
                    }
                    else
                    {
                        ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                    }
                    ++$rowDirCount;                    
                    $arrayDir[$rowDirCount][SITENAME] = $array[$Indexi][SITENAME];
                    $arrayDir[$rowDirCount][ACCESSFILENAME] = $array[$Indexi][ACCESSFILENAME];
                    $arrayDir[$rowDirCount][DIRECTORY] = $finalPath;
                    $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "off";
                    $arrayDir[$rowDirCount][IDENTITYCHECK] = "off";
                    $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
                    $arrayDir[$rowDirCount][DESTINATIONPATH] = $array[$Indexi][DESTINATIONPATH];
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\\/\//g;
                    $arrayDir[$rowDirCount][DOCUMENTROOT] = $array[$Indexi][DOCUMENTROOT];
                    $arrayDir[$rowDirCount][HTACCESS] = 1;
                    if(index($arrayDir[$rowDirCount][DIRECTORY],$array[$rowCount][DOCUMENTROOT]) != 0)  
                    {
                        $arrayDir[$rowDirCount][TASKLIST]  = 1;
                        $arrayDir[$rowDirCount][DESTINATIONPATH] = $arrayDir[$rowDirCount][DESTINATIONPATH] . $arrayDir[$rowDirCount][DIRECTORY];                         
                    }
                    else
                    {
                        my $temp;
                        $temp = pars_getRelativePath($arrayDir[$rowDirCount][DIRECTORY],$array[$Indexi][DOCUMENTROOT]);
                        $arrayDir[$rowDirCount][DESTINATIONPATH] = $arrayDir[$rowDirCount][DESTINATIONPATH] . $temp;                        
                    }
                    
                    if($arrayDir[$rowDirCount][DESTINATIONPATH] =~ /\/$/)
                    {
                        $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\/$//;                        
                    }
                    
                    
                    while (&pars_getNextDirectivehtaccess() == 1)
                    {
                        $directiveValue =~ s/^\s+//;
                        $directiveValue =~ s/\s+$//;
                        
                        if($directiveName eq "Options")
                        {                            
                            #Equivalent IIS tag => AccessExecute                            
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][OPTIONS] = $arrayDir[$rowDirCount][OPTIONS] . $directiveValue . " ";
                        }
                        if($directiveName eq "Order")
                        {                            
                            #Equivalent IIS tag => Not applicable                            
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][ORDER] = $directiveValue;
                        }
                        if($directiveName eq "AddEncoding")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][ADDENCODING] = $arrayDir[$rowDirCount][ADDENCODING] . $directiveValue . "|";
                        }
                        if($directiveName eq "AddType")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][ADDTYPE] = $arrayDir[$rowDirCount][ADDTYPE] . $directiveValue . "|";
                        }
                        if($directiveName eq "AuthGroupFile")
                        {                            
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][AUTHGROUPFILE] = $directiveValue;
                        }
                        if($directiveName eq "AuthName")
                        {                            
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][AUTHNAME] = $directiveValue;
                        }
                        if($directiveName eq "AuthType")
                        {
                            
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][AUTHTYPE] = $directiveValue;
                        }
                        if($directiveName eq "AuthUserFile")
                        {
                            
                            #Equivalent IIS tag => Not Applicable
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][AUTHUSERFILE] = $directiveValue;
                        }
                        if($directiveName eq "DefaultType")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            
                            my $temp = $directiveValue . " " . ".*";
                            $arrayDir[$rowDirCount][ADDTYPE] = $arrayDir[$rowDirCount][ADDTYPE] . $temp . "|";
                        }
                        if($directiveName eq "Deny")
                        {
                            #Equivalent IIS tag => MimeMap
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][DENY] = $directiveValue;
                        }
                        
                        if($directiveName eq "DirectoryIndex")
                        {
                            
                            #Equivalent IIS tag => EnableDirBrowsing;
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][DIRECTORYINDEX] = $directiveValue;
                            $arrayDir[$rowDirCount][DIRECTORYINDEX] =~ s/ /,/g;
                        }
                        if($directiveName eq "ErrorDocument")
                        {
                            #Equivalent IIS tag => HttpErrors
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][ERRORDOCUMENT] = $arrayDir[$rowDirCount][ERRORDOCUMENT] . $directiveValue . " ";
                        }
                        if($directiveName eq "ExpiresActive")
                        {
                            #Equivalent IIS tag => HttpExpires
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][EXPIRESACTIVE] = $directiveValue;
                        }
                        if($directiveName eq "HostnameLookups")
                        {
                            #Equivalent IIS tag => EnableReverseDNS
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = $directiveValue;
                        }
                        if($directiveName eq "IdentityCheck")
                        {
                            #Equivalent IIS tag => LogExtFileUserName
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $arrayDir[$rowDirCount][IDENTITYCHECK] = $directiveValue;
                            
                        }
                        if($directiveName eq "Header")
                        {
                            #Equivalent IIS tag => HttpCustomHeaders
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            $directiveValue =~ s/"//g;
                            if($directiveValue =~ /^set/)
                            {
                                $arrayDir[$rowDirCount][HEADER] = $arrayDir[$rowDirCount][HEADER] . $directiveValue . "|" ;
                            }
                        }
                        if($directiveName eq "Files")
                        {
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            my $numPass;
                            $numPass  = 1;
                            if($directiveValue =~ /^~/)
                            {
                                $fileMatch = 1;
                                my @temp;
                                @temp = split / /,$directiveValue;
                                $directiveName = "FilesMatch";
                                $directiveValue = $temp[1];
                                
                                chomp($directiveValue);
                                $directiveValue =~ s/"//g;
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                
                            }
                            else
                            {
                                my @file;
                                my $fileList;
                                my @fileEntire;
                                my $temp;
                                my $counter = 0;
                                my @Listing;
                                my $singleEntry;
                                my @fileEntire;
                                my @filePath;
                                my $singleEntry;
                                my $count = 0;
                                my $files;
                                my @tempArray;
                                @Listing = pars_GetDirlistinght("$arrayDir[$rowDirCount][DIRECTORY]");
                                my $rootDir;
                                $rootDir = $arrayDir[$rowDirCount][DIRECTORY];
                                
                                foreach $singleEntry (@Listing)
                                {
                                    
                                    if($singleEntry =~ /:$/)
                                    {
                                        #Dont do anything
                                        $singleEntry =~ s/:$//;
                                        $rootDir = $singleEntry;
                                        chomp($rootDir);
                                        
                                    }
                                    elsif($singleEntry =~ /^total/)
                                    {                                        
                                        #Dont do anything                                        
                                    }
                                    elsif($singleEntry =~ /^d/)
                                    {                                        
                                        #Dont do anything                                        
                                    }
                                    elsif($singleEntry eq "")
                                    {                                        
                                        #Dont do anything                                        
                                    }
                                    else
                                    {
                                        $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                        $filePath[$count] = $rootDir;
                                        $count++;
                                    }
                                }
                                my $indI = 0;
                                my $dirValue = $directiveValue;
                                foreach $temp (@fileEntire)
                                {
                                    $directiveValue =~ s/"//g;
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;
                                    
                                    if($temp eq $dirValue)
                                    {
                                        if($numPass)
                                        {                                            
                                            $files = $temp;
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;
                                            ++$filecount;
                                            $files[$filecount][SITENAME] = $arrayDir[$rowDirCount][SITENAME];
                                            $files[$filecount][DOCUMENTROOT] = $arrayDir[$rowDirCount][DOCUMENTROOT];
                                            $files[$filecount][FILESMATCH] = $files;
                                            $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                            $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                            $files[$filecount][IDENTITYCHECK] = "Off";
                                            $files[$filecount][ALLOWOVERRIDE] = "All";
                                            while (&pars_getNextDirectivehtaccess() == 1)
                                            {
                                                if($directiveName eq "/Files")
                                                {
                                                    last;
                                                }
                                                if($directiveName eq "Options")
                                                {
                                                    #Equivalent IIS tag => AccessExecute
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                                }
                                                if($directiveName eq "Order")
                                                {
                                                    #Equivalent IIS tag => Not applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ORDER] = $directiveValue;
                                                }
                                                if($directiveName eq "AddEncoding")
                                                {
                                                    #Equivalent IIS tag => MimeMap
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                                    
                                                }
                                                if($directiveName eq "AddType")
                                                {
                                                    #Equivalent IIS tag => MimeMap
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                                    
                                                }
                                                if($directiveName eq "AuthName")
                                                {
                                                    #Equivalent IIS tag => Not Applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][AUTHNAME] = $directiveValue;
                                                }
                                                if($directiveName eq "AuthType")
                                                {
                                                    #Equivalent IIS tag => Not Applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][AUTHTYPE] = $directiveValue;
                                                }
                                                if($directiveName eq "AuthUserFile")
                                                {
                                                    #Equivalent IIS tag => Not Applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    if($directiveValue =~ /^\//)
                                                    {
                                                        $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                                    }
                                                    else
                                                    {
                                                        
                                                        $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                                    }                                                    
                                                }
                                                if($directiveName eq "AuthGroupFile")
                                                {
                                                    #Equivalent IIS tag => Not Applicable
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    if($directiveValue =~ /^\//)
                                                    {
                                                        $files[$filecount][AUTHGROUPFILE] = $directiveValue;                                                        
                                                    }
                                                    else
                                                    {                                                       
                                                        $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                                    }
                                                }
                                                if($directiveName eq "DefaultType")
                                                {
                                                    #Equivalent IIS tag => MimeMap
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    
                                                    my $temp = $directiveValue . " " . ".*";
                                                    $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                                }
                                                if($directiveName eq "Deny")
                                                {
                                                    #Equivalent IIS tag => MimeMap
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][DENY] = $directiveValue;
                                                }
                                                if($directiveName eq "DirectoryIndex")
                                                {
                                                    #Equivalent IIS tag => EnableDirBrowsing;
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                                    $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                                }
                                                if($directiveName eq "ErrorDocument")
                                                {
                                                    #Equivalent IIS tag => HttpErrors
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                                }
                                                if($directiveName eq "ExpiresActive")
                                                {
                                                    #Equivalent IIS tag => HttpExpires
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                }
                                                if($directiveName eq "HostnameLookups")
                                                {
                                                    #Equivalent IIS tag => EnableReverseDNS
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                                }
                                                if($directiveName eq "IdentityCheck")
                                                {
                                                    #Equivalent IIS tag => LogExtFileUserName
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                                }
                                                if($directiveName eq "AllowOverride")
                                                {
                                                    #Equivalent IIS tag => Not Applicable.
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                                }
                                                if($directiveName eq "Header")
                                                {
                                                    #Equivalent IIS tag => HttpCustomHeaders
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $directiveValue =~ s/"//g;
                                                    if($directiveValue =~ /^set/)
                                                    {
                                                        $files[$filecount][HEADER] = $files[$filecount][HEADER] . $directiveValue . "|" ;
                                                    }
                                                }
                                                if($directiveName eq "ExpiresActive")
                                                {   
                                                    #Equivalent IIS tag => HttpExpires
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                }
                                            }

                                            $numPass = 0;
                                        }
                                        else
                                        {
                                            my $kk = 0;
                                            my $jj = 0;
                                            ++$filecount;                                            
                                            for($kk = 0; $kk < $maxColumn;$kk++)
                                            {
                                                $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                            }
                                            
                                            $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                        }
                                    }
                                    $indI++;
                                }
                            }
                        }
                        if($directiveName eq "FilesMatch")
                        {
                            my @file;
                            my $fileList;
                            my @fileEntire;
                            my $temp;
                            my $counter = 0;
                            my @Listing;
                            my $singleEntry;
                            my @fileEntire;
                            my @filePath;
                            my $singleEntry;
                            my $count = 0;
                            my $files;
                            my @tempArray;
                            my $numPass = 1;
                            
                            @Listing = pars_GetDirlistinght("$arrayDir[$rowDirCount][DIRECTORY]");
                            my $rootDir;
                            $rootDir = $arrayDir[$rowDirCount][DIRECTORY];
                            foreach $singleEntry (@Listing)
                            {                                
                                if($singleEntry =~ /:$/)
                                {
                                    #Dont do anything
                                    $singleEntry =~ s/:$//;
                                    $rootDir = $singleEntry;
                                    chomp($rootDir);
                                    
                                }
                                elsif($singleEntry =~ /^total/)
                                {                                    
                                    #Dont do anything                                    
                                }
                                elsif($singleEntry =~ /^d/)
                                {                                    
                                    #Dont do anything                                    
                                }
                                elsif($singleEntry eq "")
                                {                                    
                                    #Dont do anything                                    
                                }
                                else
                                {
                                    $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                    $filePath[$count] = $rootDir;
                                    $count++;
                                }
                            }
                            my $indI = 0;
                            my $dirValue = $directiveValue;
                            foreach $temp (@fileEntire)
                            {                                
                                $directiveValue =~ s/"//g;
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;                                
                                if($temp =~ /$dirValue/)
                                {
                                    if($numPass)
                                    {   
                                        $files = $temp;
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        ++$filecount;
                                        $files[$filecount][SITENAME] = $arrayDir[$rowDirCount][SITENAME];
                                        $files[$filecount][DOCUMENTROOT] = $arrayDir[$rowDirCount][DOCUMENTROOT];
                                        $files[$filecount][FILESMATCH] = $files;
                                        $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                        $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                        $files[$filecount][IDENTITYCHECK] = "Off";
                                        $files[$filecount][ALLOWOVERRIDE] = "All";
                                        while (&pars_getNextDirectivehtaccess() == 1)
                                        {
                                            if($directiveName eq "/FilesMatch")
                                            {
                                                last;
                                            }
                                            if($fileMatch)
                                            {
                                                if($directiveName eq "/Files")
                                                {
                                                    
                                                    $fileMatch = 0;
                                                    last;
                                                }
                                            }
                                            if($directiveName eq "Options")
                                            {
                                                #Equivalent IIS tag => AccessExecute
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                            }
                                            if($directiveName eq "Order")
                                            {
                                                #Equivalent IIS tag => Not applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ORDER] = $directiveValue;
                                            }
                                            if($directiveName eq "AddEncoding")
                                            {
                                                #Equivalent IIS tag => MimeMap
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                            }
                                            if($directiveName eq "AddType")
                                            {
                                                #Equivalent IIS tag => MimeMap
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                            }
                                            if($directiveName eq "AuthName")
                                            {
                                                #Equivalent IIS tag => Not Applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][AUTHNAME] = $directiveValue;
                                            }
                                            if($directiveName eq "AuthType")
                                            {
                                                #Equivalent IIS tag => Not Applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][AUTHTYPE] = $directiveValue;
                                            }
                                            if($directiveName eq "AuthUserFile")
                                            {
                                                #Equivalent IIS tag => Not Applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                if($directiveValue =~ /^\//)
                                                {
                                                    $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                                }
                                                else
                                                {
                                                    
                                                    $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                                }
                                                
                                            }
                                            if($directiveName eq "AuthGroupFile")
                                            {
                                                #Equivalent IIS tag => Not Applicable
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                if($directiveValue =~ /^\//)
                                                {
                                                    $files[$filecount][AUTHGROUPFILE] = $directiveValue;
                                                    
                                                }
                                                else
                                                {
                                                    
                                                    $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                                }
                                            }
                                            if($directiveName eq "DefaultType")
                                            {
                                                #Equivalent IIS tag => MimeMap
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                
                                                my $temp = $directiveValue . " " . ".*";
                                                $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                            }
                                            if($directiveName eq "Deny")
                                            {
                                                #Equivalent IIS tag => MimeMap
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][DENY] = $directiveValue;
                                            }
                                            if($directiveName eq "DirectoryIndex")
                                            {
                                                #Equivalent IIS tag => EnableDirBrowsing;
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                                $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                            }
                                            if($directiveName eq "ErrorDocument")
                                            {
                                                #Equivalent IIS tag => HttpErrors
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                            }
                                            if($directiveName eq "ExpiresActive")
                                            {
                                                #Equivalent IIS tag => HttpExpires
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                            }
                                            if($directiveName eq "HostnameLookups")
                                            {
                                                #Equivalent IIS tag => EnableReverseDNS
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                            }
                                            if($directiveName eq "IdentityCheck")
                                            {
                                                #Equivalent IIS tag => LogExtFileUserName
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                            }
                                            if($directiveName eq "AllowOverride")
                                            {
                                                #Equivalent IIS tag => Not Applicable.
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                            }
                                            if($directiveName eq "Header")
                                            {
                                                #Equivalent IIS tag => HttpCustomHeaders
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $directiveValue =~ s/"//g;
                                                if($directiveValue =~ /^set/)
                                                {
                                                    $files[$filecount][HEADER] = $files[$filecount][HEADER] . $directiveValue . "|" ;
                                                }
                                            }
                                            if($directiveName eq "ExpiresActive")
                                            {   
                                                #Equivalent IIS tag => HttpExpires
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                            }
                                        }
                                        $numPass = 0;
                                    }
                                    else
                                    {
                                        my $kk = 0;
                                        my $jj = 0;
                                        ++$filecount;
                                        
                                        for($kk = 0; $kk < $maxColumn;$kk++)
                                        {
                                            $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                        }
                                        
                                        $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                        $files[$filecount][FILESMATCH] = $temp;
                                    }
                                }

                                $indI++;
                            }
                        }                        
                    }
                }
            }
        }
    }   
    # to process for the HTACCESS files present with in the directory tags
    for($Indexi = 0; $Indexi <= $rowDirCount; $Indexi++)
    {
        # Get the .Htaccessfile for the directory and the sub directory
        if($arrayDir[$Indexi][TASKLIST] == 1)
        {
            @Listing = pars_GetDirlistinght($arrayDir[$Indexi][DIRECTORY]);
            $htaccessfilename = $arrayDir[$Indexi][ACCESSFILENAME];
            $finalPath = $arrayDir[$Indexi][DIRECTORY];
            
            foreach $singleEntry (@Listing)
            {
                @splitEntry = split / /, $singleEntry;
                if($singleEntry =~ /:$/)
                {
                    $finalPath = $singleEntry;
                }
                my $fileNameHT;
                $fileNameHT = $splitEntry[$#splitEntry];
                chomp($fileNameHT);
                
                if($htaccessfilename eq $fileNameHT)
                {
                    #************************************************************
                    # Get the path for this file
                    # search the Array folder for the allowoveride option
                    # if none is found then the default i.e., "All" is considered 
                    # if found then the directive is dealt as follow's
                    #************************************************************
                    
                    $finalPath =~ s/:$//;
                    chomp($finalPath);
                    my $indexToReplace;
                    my $ret;
                    ($ret,$indexToReplace) = pars_directoryFound($finalPath,$arrayDir[$Indexi][SITENAME]);
                    
                    if($ret)
                    {
                        #*************************************************************************
                        # There is a entry for this folder in the 2d array.
                        # Read the AllowOverride value
                        # Depending on the AllowOverride value replace this row in the $arrayDir
                        # Ftp the .htaccess file at this place to replace the array values
                        #*************************************************************************
                        my $filenameFtp = $finalPath . "/" . $htaccessfilename;
                        pars_GetFileFromSource($filenameFtp,$htaccessfilename);
                        
                        #open HTACCESSHANDLE, $htaccessfilename or die "Error opening .htaccess file";
                        my @allowOverride = split / /, $arrayDir[$indexToReplace][ALLOWOVERRIDE];
                        my $Indexj = 0;
                        my $tempValue;
                        my $overWrite = 0;
                        foreach $tempValue (@allowOverride)
                        {
                            if($tempValue eq "AuthConfig")
                            {
                                if(!$overWrite)
                                {
                                    for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                    {
                                        $arrayDir[$indexToReplace][$Indexj] = "";
                                    }
                                    $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "On";
                                    $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                    ++$overWrite;
                                }
                                eval
                                {                                    
                                    open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                    
                                };
                                if($@)
                                {
                                    if($@=~/ERR_FILE_OPEN/)
                                    {
                                        # log error and exit tool                                        
                                        ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                        return FALSE;                                        
                                    }                                    
                                }
                                else
                                {
                                    ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                                }
                                
                                while (&pars_getNextDirectivehtaccess() == 1)
                                {
                                    
                                    if($directiveName eq "AuthGroupFile")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][AUTHGROUPFILE] = $directiveValue;
                                    }
                                    
                                    if($directiveName eq "AuthName")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][AUTHNAME] = $directiveValue;
                                    }
                                    if($directiveName eq "AuthType")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][AUTHTYPE] = $directiveValue;
                                    }
                                    if($directiveName eq "AuthUserFile")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][AUTHUSERFILE] = $directiveValue;
                                    }
                                }
                            }
                            if($tempValue eq "FileInfo")
                            {
                                if(!$overWrite)
                                {
                                    for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                    {
                                        $arrayDir[$indexToReplace][$Indexj] = "";
                                    }
                                    $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "Off";
                                    $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                    ++$overWrite;
                                }
                                eval
                                {                                    
                                    open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                    
                                };
                                if($@)
                                {
                                    if($@=~/ERR_FILE_OPEN/)
                                    {
                                        # log error and exit tool                                        
                                        ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                        return FALSE;                                        
                                    }                                    
                                }
                                else
                                {
                                    ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                                }
                                
                                while (&pars_getNextDirectivehtaccess() == 1)
                                {                                   
                                    if($directiveName eq "AddEncoding")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][ADDENCODING] = $arrayDir[$indexToReplace][ADDENCODING] . $directiveValue . "|";
                                    }
                                    
                                    if($directiveName eq "DefaultType")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        
                                        my $temp = $directiveValue . " " . ".*";
                                        $arrayDir[$indexToReplace][ADDTYPE] = $arrayDir[$indexToReplace][ADDTYPE] . $temp . "|";
                                    }
                                    if($directiveName eq "ErrorDocument")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][ERRORDOCUMENT] = $directiveValue;
                                    }
                                    if($directiveName eq "AddType")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][ADDTYPE] = $arrayDir[$indexToReplace][ADDTYPE] . $directiveValue . "|";
                                    }
                                }
                            }
                            if($tempValue eq "Indexes")
                            {
                                if(!$overWrite)
                                {
                                    for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                    {
                                        $arrayDir[$indexToReplace][$Indexj] = "";
                                    }

                                    $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "Off";
                                    $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                    ++$overWrite;
                                }
                                
                                eval
                                {                                    
                                    open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                    
                                };

                                if($@)
                                {
                                    if($@=~/ERR_FILE_OPEN/)
                                    {   
                                        # log error and exit tool                                        
                                        ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                        return FALSE;                                        
                                    }                                    
                                }
                                else
                                {
                                    ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                                }
                                
                                while (&pars_getNextDirectivehtaccess() == 1)
                                {
                                    if($directiveName eq "DirectoryIndex")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][DIRECTORYINDEX] = $directiveValue;
                                        $arrayDir[$indexToReplace][DIRECTORYINDEX] =~ s/ /,/g;                                      
                                    }
                                }
                            }

                            if($tempValue eq "Limit")
                            {                                
                                #*****************************************************************************************                          
                                #   Since the AllowOveride Value is Limit,
                                #   only the *Allow* *Deny* and *Order* directives are considered from the .htaccess files 
                                #   and the rest of the directives are discarded.
                                #*****************************************************************************************
                                if(!$overWrite)
                                {
                                    for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                    {
                                        $arrayDir[$indexToReplace][$Indexj] = "";
                                    }
                                    $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "Off";
                                    $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                    ++$overWrite;
                                }
                                eval
                                {                                    
                                    open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                    
                                };
                                if($@)
                                {
                                    if($@=~/ERR_FILE_OPEN/)
                                    {
                                        # log error and exit tool                                        
                                        ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                        return FALSE;                                        
                                    }                                    
                                }
                                else
                                {
                                    ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                                }
                                while (&pars_getNextDirectivehtaccess()==1)
                                {                                    
                                    if($directiveName eq "Allow")
                                    {
                                        # Not migrated. 
                                    }
                                    if($directiveName eq "Deny")
                                    {                                        
                                        #Equivalent IIS tag => MimeMap
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][DENY] =~ s/^\s+//;
                                        $arrayDir[$indexToReplace][DENY] =~ s/^\s+//;
                                        $arrayDir[$indexToReplace][DENY] = $directiveValue;
                                    }
                                    if($directiveName eq "Order")
                                    {
                                        #Equivalent IIS tag => Not applicable                                        
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][ORDER] =~ s/^\s+//;
                                        $arrayDir[$indexToReplace][ORDER] =~ s/^\s+//;
                                        $arrayDir[$indexToReplace][ORDER] = $directiveValue;
                                    }
                                }
                            }

                            if($tempValue eq "Options")
                            {
                                #*****************************************************************************************                          
                                #   Since the AllowOveride Value is Options, 
                                #   only the *Options* and *XBitHack* directives are considered from the .htaccess files 
                                #   and the rest of the directives are discarded.
                                #*****************************************************************************************                          
                                if(!$overWrite)
                                {
                                    for($Indexj=3; $Indexj < $maxColumn; $Indexj++)
                                    {
                                        $arrayDir[$indexToReplace][$Indexj] = "";
                                    }
                                    $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "Off";
                                    $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                    ++$overWrite;
                                }
                                eval
                                {                                    
                                    open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                    
                                };
                                if($@)
                                {
                                    if($@=~/ERR_FILE_OPEN/)
                                    {   
                                        # log error and exit tool                                        
                                        ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                        return FALSE;                                        
                                    }                                    
                                }
                                else
                                {
                                    ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                                }
                                
                                while (&pars_getNextDirectivehtaccess() == 1)
                                {                                    
                                    if($directiveName eq "Options")
                                    {
                                        # Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][OPTIONS] =~ s/^\s+//;
                                        $arrayDir[$indexToReplace][OPTIONS] =~ s/^\s+//;
                                        $arrayDir[$indexToReplace][OPTIONS] = $arrayDir[$indexToReplace][OPTIONS] . " " . $directiveValue;
                                    }
                                    
                                    if($directiveName eq "XBitHack")
                                    {
                                        # Not migrated. 
                                    }
                                }
                            }

                            if($tempValue eq "All")
                            {                               
                                #******************************************************************                         
                                #   Since the AllowOveride Value is All,
                                #   all the directive present in the HTACCESS files are considered
                                #******************************************************************                         
                                if(!$overWrite)
                                {
                                    for($Indexj=3; $Indexj < ($maxColumn-1); $Indexj++)
                                    {
                                        $arrayDir[$indexToReplace][$Indexj] = "";
                                    }
                                    $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = "On";
                                    $arrayDir[$indexToReplace][IDENTITYCHECK] = "Off";
                                    ++$overWrite;
                                }
                                
                                eval
                                {                                    
                                    open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                                    
                                };
                                if($@)
                                {
                                    if($@=~/ERR_FILE_OPEN/)
                                    {
                                        # log error and exit tool                                        
                                        ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                        return FALSE;                                        
                                    }                                    
                                }
                                else
                                {
                                    ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                                }
                                
                                while (&pars_getNextDirectivehtaccess() == 1)
                                {
                                    $directiveValue =~ s/^\s+//;
                                    $directiveValue =~ s/\s+$//;                                    
                                    if($directiveName eq "Options")
                                    {                                        
                                        #Equivalent IIS tag => AccessExecute                                        
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][OPTIONS] = $arrayDir[$indexToReplace][OPTIONS] . $directiveValue . " ";
                                    }
                                    if($directiveName eq "Order")
                                    {                                        
                                        #Equivalent IIS tag => Not applicable                                        
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][ORDER] = $directiveValue;
                                    }
                                    if($directiveName eq "AddEncoding")
                                    {
                                        #Equivalent IIS tag => MimeMap
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][ADDENCODING] = $arrayDir[$indexToReplace][ADDENCODING] . $directiveValue . "|";
                                    }
                                    if($directiveName eq "AddType")
                                    {
                                        #Equivalent IIS tag => MimeMap
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][ADDTYPE] = $arrayDir[$indexToReplace][ADDTYPE] . $directiveValue . "|";
                                    }
                                    if($directiveName eq "AuthGroupFile")
                                    {
                                        
                                        #Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][AUTHGROUPFILE] = $directiveValue;
                                    }
                                    if($directiveName eq "AuthName")
                                    {                                        
                                        #Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;                        
                                        $arrayDir[$indexToReplace][AUTHNAME] = $directiveValue;
                                    }
                                    if($directiveName eq "AuthType")
                                    {                                        
                                        #Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][AUTHTYPE] = $directiveValue;
                                    }
                                    if($directiveName eq "AuthUserFile")
                                    {                                        
                                        #Equivalent IIS tag => Not Applicable
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][AUTHUSERFILE] = $directiveValue;
                                    }
                                    if($directiveName eq "DefaultType")
                                    {
                                        #Equivalent IIS tag => MimeMap
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        
                                        my $temp = $directiveValue . " " . ".*";
                                        $arrayDir[$indexToReplace][ADDTYPE] = $arrayDir[$indexToReplace][ADDTYPE] . $temp . "|";
                                    }
                                    if($directiveName eq "Deny")
                                    {
                                        #Equivalent IIS tag => MimeMap
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][DENY] = $directiveValue;
                                    }
                                    
                                    if($directiveName eq "DirectoryIndex")
                                    {                                        
                                        #Equivalent IIS tag => EnableDirBrowsing;
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][DIRECTORYINDEX] = $directiveValue;
                                        $arrayDir[$indexToReplace][DIRECTORYINDEX] =~ s/ /,/g;
                                    }
                                    if($directiveName eq "ErrorDocument")
                                    {
                                        #Equivalent IIS tag => HttpErrors
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][ERRORDOCUMENT] = $arrayDir[$rowDirCount][ERRORDOCUMENT] . $directiveValue . " ";
                                    }
                                    if($directiveName eq "ExpiresActive")
                                    {
                                        #Equivalent IIS tag => HttpExpires
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][EXPIRESACTIVE] = $directiveValue;
                                    }
                                    if($directiveName eq "HostnameLookups")
                                    {
                                        #Equivalent IIS tag => EnableReverseDNS
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][HOSTNAMELOOKUPS] = $directiveValue;
                                    }
                                    if($directiveName eq "IdentityCheck")
                                    {
                                        #Equivalent IIS tag => LogExtFileUserName
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $arrayDir[$indexToReplace][IDENTITYCHECK] = $directiveValue;
                                        
                                    }
                                    if($directiveName eq "Header")
                                    {
                                        #Equivalent IIS tag => HttpCustomHeaders
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        $directiveValue =~ s/"//g;
                                        if($directiveValue =~ /^set/)
                                        {
                                            $arrayDir[$indexToReplace][HEADER] = $arrayDir[$indexToReplace][HEADER] . $directiveValue . "|" ;
                                        }
                                    }

                                    if($directiveName eq "Files")
                                    {
                                        $directiveValue =~ s/^\s+//;
                                        $directiveValue =~ s/\s+$//;
                                        my $numPass;
                                        $numPass  = 1;
                                        if($directiveValue =~ /^~/)
                                        {
                                            $fileMatch = 1;
                                            my @temp;
                                            @temp = split / /,$directiveValue;
                                            $directiveName = "FilesMatch";
                                            $directiveValue = $temp[1];
                                            
                                            chomp($directiveValue);
                                            $directiveValue =~ s/"//g;
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;                                            
                                        }
                                        else
                                        {
                                            my @file;
                                            my $fileList;
                                            my @fileEntire;
                                            my $temp;
                                            my $counter = 0;
                                            my @Listing;
                                            my $singleEntry;
                                            my @fileEntire;
                                            my @filePath;
                                            my $singleEntry;
                                            my $count = 0;
                                            my $files;
                                            my @tempArray;
                                            @Listing = pars_GetDirlistinght("$arrayDir[$Indexi][DIRECTORY]");
                                            my $rootDir;
                                            $rootDir = $arrayDir[$Indexi][DIRECTORY];
                                            
                                            foreach $singleEntry (@Listing)
                                            {
                                                
                                                if($singleEntry =~ /:$/)
                                                {
                                                    #Dont do anything
                                                    $singleEntry =~ s/:$//;
                                                    $rootDir = $singleEntry;
                                                    chomp($rootDir);
                                                    
                                                }
                                                elsif($singleEntry =~ /^total/)
                                                {                                                    
                                                    #Dont do anything                                                    
                                                }
                                                elsif($singleEntry =~ /^d/)
                                                {                                                    
                                                    #Dont do anything                                                    
                                                }
                                                elsif($singleEntry eq "")
                                                {                                                    
                                                    #Dont do anything                                                    
                                                }
                                                else
                                                {
                                                    $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                                    $filePath[$count] = $rootDir;
                                                    $count++;
                                                }
                                            }
                                            my $indI = 0;
                                            my $dirValue = $directiveValue;
                                            foreach $temp (@fileEntire)
                                            {
                                                $directiveValue =~ s/"//g;
                                                $directiveValue =~ s/^\s+//;
                                                $directiveValue =~ s/\s+$//;
                                                
                                                if($temp eq $dirValue)
                                                {                                                   
                                                    if($numPass)
                                                    {                                                        
                                                        $files = $temp;
                                                        $directiveValue =~ s/^\s+//;
                                                        $directiveValue =~ s/\s+$//;
                                                        ++$filecount;
                                                        $files[$filecount][SITENAME] = $arrayDir[$Indexi][SITENAME];
                                                        $files[$filecount][DOCUMENTROOT] = $arrayDir[$Indexi][DOCUMENTROOT];
                                                        $files[$filecount][FILESMATCH] = $files;
                                                        $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                                        $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                                        $files[$filecount][IDENTITYCHECK] = "Off";
                                                        $files[$filecount][ALLOWOVERRIDE] = "All";
                                                        while (&pars_getNextDirectivehtaccess() == 1)
                                                        {
                                                            if($directiveName eq "/Files")
                                                            {
                                                                last;
                                                            }
                                                            if($directiveName eq "Options")
                                                            {
                                                                #Equivalent IIS tag => AccessExecute
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                                            }
                                                            if($directiveName eq "Order")
                                                            {
                                                                #Equivalent IIS tag => Not applicable
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][ORDER] = $directiveValue;
                                                            }
                                                            if($directiveName eq "AddEncoding")
                                                            {
                                                                #Equivalent IIS tag => MimeMap
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                                                
                                                            }
                                                            if($directiveName eq "AddType")
                                                            {
                                                                #Equivalent IIS tag => MimeMap
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                                                
                                                            }
                                                            if($directiveName eq "AuthName")
                                                            {
                                                                #Equivalent IIS tag => Not Applicable
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][AUTHNAME] = $directiveValue;
                                                            }
                                                            if($directiveName eq "AuthType")
                                                            {
                                                                #Equivalent IIS tag => Not Applicable
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][AUTHTYPE] = $directiveValue;
                                                            }
                                                            if($directiveName eq "AuthUserFile")
                                                            {
                                                                #Equivalent IIS tag => Not Applicable
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                if($directiveValue =~ /^\//)
                                                                {
                                                                    $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                                                }
                                                                else
                                                                {
                                                                    
                                                                    $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                                                }
                                                                
                                                            }
                                                            if($directiveName eq "AuthGroupFile")
                                                            {
                                                                #Equivalent IIS tag => Not Applicable
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                if($directiveValue =~ /^\//)
                                                                {
                                                                    $files[$filecount][AUTHGROUPFILE] = $directiveValue;                                                                    
                                                                }
                                                                else
                                                                {                                                                    
                                                                    $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                                                }
                                                            }
                                                            if($directiveName eq "DefaultType")
                                                            {
                                                                #Equivalent IIS tag => MimeMap
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                
                                                                my $temp = $directiveValue . " " . ".*";
                                                                $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                                            }
                                                            if($directiveName eq "Deny")
                                                            {
                                                                #Equivalent IIS tag => MimeMap
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][DENY] = $directiveValue;
                                                            }
                                                            if($directiveName eq "DirectoryIndex")
                                                            {
                                                                #Equivalent IIS tag => EnableDirBrowsing;
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                                                $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                                            }
                                                            if($directiveName eq "ErrorDocument")
                                                            {
                                                                #Equivalent IIS tag => HttpErrors
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                                            }
                                                            if($directiveName eq "ExpiresActive")
                                                            {
                                                                #Equivalent IIS tag => HttpExpires
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                            }
                                                            if($directiveName eq "HostnameLookups")
                                                            {
                                                                #Equivalent IIS tag => EnableReverseDNS
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                                            }
                                                            if($directiveName eq "IdentityCheck")
                                                            {
                                                                #Equivalent IIS tag => LogExtFileUserName
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                                            }
                                                            if($directiveName eq "AllowOverride")
                                                            {
                                                                #Equivalent IIS tag => Not Applicable.
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                                            }
                                                            if($directiveName eq "Header")
                                                            {
                                                                #Equivalent IIS tag => HttpCustomHeaders
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $directiveValue =~ s/"//g;
                                                                if($directiveValue =~ /^set/)
                                                                {
                                                                    $files[$filecount][HEADER] = $files[$filecount][HEADER] . $directiveValue . "|" ;
                                                                }
                                                            }
                                                            if($directiveName eq "ExpiresActive")
                                                            {   
                                                                #Equivalent IIS tag => HttpExpires
                                                                $directiveValue =~ s/^\s+//;
                                                                $directiveValue =~ s/\s+$//;
                                                                $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                            }
                                                        }
                                                        $numPass = 0;
                                                    }
                                                    else
                                                    {
                                                        my $kk = 0;
                                                        my $jj = 0;
                                                        ++$filecount;                                                        
                                                        for($kk = 0; $kk < $maxColumn;$kk++)
                                                        {
                                                            $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                                        }
                                                        
                                                        $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                                    }
                                                }

                                                $indI++;
                                            }
                                        }
                                    }
                                    if($directiveName eq "FilesMatch")
                                    {
                                        my @file;
                                        my $fileList;
                                        my @fileEntire;
                                        my $temp;
                                        my $counter = 0;
                                        my @Listing;
                                        my $singleEntry;
                                        my @fileEntire;
                                        my @filePath;
                                        my $singleEntry;
                                        my $count = 0;
                                        my $files;
                                        my @tempArray;
                                        my $numPass = 1;
                                        
                                        @Listing = pars_GetDirlistinght("$arrayDir[$Indexi][DIRECTORY]");
                                        my $rootDir;
                                        $rootDir = $arrayDir[$Indexi][DIRECTORY];
                                        foreach $singleEntry (@Listing)
                                        {
                                            
                                            if($singleEntry =~ /:$/)
                                            {
                                                #Dont do anything
                                                $singleEntry =~ s/:$//;
                                                $rootDir = $singleEntry;
                                                chomp($rootDir);                                                
                                            }
                                            elsif($singleEntry =~ /^total/)
                                            {                                                
                                                #Dont do anything                                                
                                            }
                                            elsif($singleEntry =~ /^d/)
                                            {                                                
                                                #Dont do anything                                                
                                            }
                                            elsif($singleEntry eq "")
                                            {                                                
                                                #Dont do anything                                                
                                            }
                                            else
                                            {
                                                $fileEntire[$count] = pars_FileNameSet($singleEntry);
                                                $filePath[$count] = $rootDir;
                                                $count++;
                                            }
                                        }
                                        my $indI = 0;
                                        my $dirValue = $directiveValue;
                                        foreach $temp (@fileEntire)
                                        {                                            
                                            $directiveValue =~ s/"//g;
                                            $directiveValue =~ s/^\s+//;
                                            $directiveValue =~ s/\s+$//;                                            
                                            if($temp =~ /$dirValue/)
                                            {
                                                if($numPass)
                                                {
                                                    $files = $temp;
                                                    $directiveValue =~ s/^\s+//;
                                                    $directiveValue =~ s/\s+$//;
                                                    ++$filecount;
                                                    $files[$filecount][SITENAME] = $arrayDir[$Indexi][SITENAME];
                                                    $files[$filecount][DOCUMENTROOT] = $arrayDir[$Indexi][DOCUMENTROOT];
                                                    $files[$filecount][FILESMATCH] = $files;
                                                    $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                                    $files[$filecount][HOSTNAMELOOKUPS] = "Off";
                                                    $files[$filecount][IDENTITYCHECK] = "Off";
                                                    $files[$filecount][ALLOWOVERRIDE] = "All";
                                                    while (&pars_getNextDirectivehtaccess() == 1)
                                                    {
                                                        if($directiveName eq "/FilesMatch")
                                                        {
                                                            last;
                                                        }
                                                        if($fileMatch)
                                                        {
                                                            if($directiveName eq "/Files")
                                                            {
                                                                
                                                                $fileMatch = 0;
                                                                last;
                                                            }
                                                        }
                                                        if($directiveName eq "Options")
                                                        {
                                                            #Equivalent IIS tag => AccessExecute
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][OPTIONS] = $files[$filecount][OPTIONS] . $directiveValue . " ";
                                                        }
                                                        if($directiveName eq "Order")
                                                        {
                                                            #Equivalent IIS tag => Not applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ORDER] = $directiveValue;
                                                        }
                                                        if($directiveName eq "AddEncoding")
                                                        {
                                                            #Equivalent IIS tag => MimeMap
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ADDENCODING] = $files[$filecount][ADDENCODING] . $directiveValue . "|";
                                                        }
                                                        if($directiveName eq "AddType")
                                                        {
                                                            #Equivalent IIS tag => MimeMap
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $directiveValue . "|";
                                                        }
                                                        if($directiveName eq "AuthName")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][AUTHNAME] = $directiveValue;
                                                        }
                                                        if($directiveName eq "AuthType")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][AUTHTYPE] = $directiveValue;
                                                        }
                                                        if($directiveName eq "AuthUserFile")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            if($directiveValue =~ /^\//)
                                                            {
                                                                $files[$filecount][AUTHUSERFILE] = $directiveValue;
                                                            }
                                                            else
                                                            {
                                                                
                                                                $files[$filecount][AUTHUSERFILE] = $arrayDir[0][SERVERROOT] . $directiveValue;
                                                            }
                                                            
                                                        }
                                                        if($directiveName eq "AuthGroupFile")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            if($directiveValue =~ /^\//)
                                                            {
                                                                $files[$filecount][AUTHGROUPFILE] = $directiveValue;                                                                
                                                            }
                                                            else
                                                            {
                                                                
                                                                $files[$filecount][AUTHGROUPFILE] = $array[0][SERVERROOT] . $directiveValue;
                                                            }
                                                        }
                                                        if($directiveName eq "DefaultType")
                                                        {
                                                            #Equivalent IIS tag => MimeMap
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            
                                                            my $temp = $directiveValue . " " . ".*";
                                                            $files[$filecount][ADDTYPE] = $files[$filecount][ADDTYPE] . $temp . "|";
                                                        }
                                                        if($directiveName eq "Deny")
                                                        {
                                                            #Equivalent IIS tag => MimeMap
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][DENY] = $directiveValue;
                                                        }
                                                        if($directiveName eq "DirectoryIndex")
                                                        {
                                                            #Equivalent IIS tag => EnableDirBrowsing;
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][DIRECTORYINDEX] = $directiveValue;
                                                            $files[$filecount][DIRECTORYINDEX] =~ s/ /,/g;
                                                        }
                                                        if($directiveName eq "ErrorDocument")
                                                        {
                                                            #Equivalent IIS tag => HttpErrors
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ERRORDOCUMENT] = $files[$filecount][ERRORDOCUMENT] . $directiveValue . " ";
                                                        }
                                                        if($directiveName eq "ExpiresActive")
                                                        {
                                                            #Equivalent IIS tag => HttpExpires
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                        }
                                                        if($directiveName eq "HostnameLookups")
                                                        {
                                                            #Equivalent IIS tag => EnableReverseDNS
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][HOSTNAMELOOKUPS] = $directiveValue;
                                                        }
                                                        if($directiveName eq "IdentityCheck")
                                                        {
                                                            #Equivalent IIS tag => LogExtFileUserName
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][IDENTITYCHECK] = $directiveValue;
                                                        }
                                                        if($directiveName eq "AllowOverride")
                                                        {
                                                            #Equivalent IIS tag => Not Applicable.
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][ALLOWOVERRIDE] = $directiveValue;
                                                            
                                                        }
                                                        if($directiveName eq "Header")
                                                        {
                                                            #Equivalent IIS tag => HttpCustomHeaders
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $directiveValue =~ s/"//g;
                                                            if($directiveValue =~ /^set/)
                                                            {
                                                                $files[$filecount][HEADER] = $files[$filecount] . $directiveValue . "|" ;
                                                            }
                                                        }
                                                        if($directiveName eq "ExpiresActive")
                                                        {   
                                                            #Equivalent IIS tag => HttpExpires
                                                            $directiveValue =~ s/^\s+//;
                                                            $directiveValue =~ s/\s+$//;
                                                            $files[$filecount][EXPIRESACTIVE] = $directiveValue;
                                                        }
                                                    }
                                                    $numPass = 0;
                                                }
                                                else
                                                {
                                                    my $kk = 0;
                                                    my $jj = 0;
                                                    ++$filecount;
                                                    for($kk = 0; $kk < $maxColumn;$kk++)
                                                    {
                                                        $files[$filecount][$kk] = $files[($filecount-1)][$kk];
                                                    }
                                                    
                                                    $files[$filecount][DIRECTORY] =  $filePath[$indI];
                                                    $files[$filecount][FILESMATCH] = $temp;
                                                }
                                            }
                                            $indI++;
                                        }
                                    }
                                }
                            }
                            if($tempValue eq "None")
                            {
                                # Dont do anything.
                            }
                        }
                    }
                    else
                    {
                        #*****************************************************************************************                          
                        # The Default value is all
                        # So create a Row in the $arrayDir populating the value read from the .htaccess file
                        #*****************************************************************************************                        
                        my $filenameFtp = $finalPath . "/" . $htaccessfilename;
                        pars_GetFileFromSource($filenameFtp,$htaccessfilename);
                        eval
                        {                            
                            open HTACCESSHANDLE, $htaccessfilename or die 'ERR_FILE_OPEN';                            
                        };
                        if($@)
                        {
                            if($@=~/ERR_FILE_OPEN/)
                            {   
                                # log error and exit tool                                
                                ilog_setLogInformation('INT_ERROR',$htaccessfilename,ERR_FILE_OPEN,__LINE__);       
                                return FALSE;                                
                            }                            
                        }
                        else
                        {
                            ilog_setLogInformation('INT_INFO',$htaccessfilename,MSG_FILE_OPEN,'');
                        }
                        ++$rowDirCount;                        
                        $arrayDir[$rowDirCount][SITENAME] = $array[$Indexi][SITENAME];
                        $arrayDir[$rowDirCount][DIRECTORY] = $finalPath;
                        $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "off";
                        $arrayDir[$rowDirCount][IDENTITYCHECK] = "off";
                        $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
                        
                        while (&pars_getNextDirectivehtaccess() == 1)
                        {
                            $directiveValue =~ s/^\s+//;
                            $directiveValue =~ s/\s+$//;
                            
                            if($directiveName eq "Options")
                            {                                
                                #Equivalent IIS tag => AccessExecute                                
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][OPTIONS] = $arrayDir[$rowDirCount][OPTIONS] . $directiveValue . " ";
                            }
                            if($directiveName eq "Order")
                            {                                
                                #Equivalent IIS tag => Not applicable                                
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][ORDER] = $directiveValue;
                            }
                            if($directiveName eq "AddEncoding")
                            {
                                #Equivalent IIS tag => MimeMap
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][ADDENCODING] = $arrayDir[$rowDirCount][ADDENCODING] . $directiveValue . "|";
                            }
                            if($directiveName eq "AddType")
                            {
                                #Equivalent IIS tag => MimeMap
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][ADDTYPE] = $arrayDir[$rowDirCount][ADDTYPE] . $directiveValue . "|";
                            }
                            if($directiveName eq "AuthGroupFile")
                            {
                                
                                #Equivalent IIS tag => Not Applicable
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][AUTHGROUPFILE] = $directiveValue;
                            }
                            if($directiveName eq "AuthName")
                            {                                
                                #Equivalent IIS tag => Not Applicable
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][AUTHNAME] = $directiveValue;
                            }
                            if($directiveName eq "AuthType")
                            {                                
                                #Equivalent IIS tag => Not Applicable
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][AUTHTYPE] = $directiveValue;
                            }
                            if($directiveName eq "AuthUserFile")
                            {
                                
                                #Equivalent IIS tag => Not Applicable
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][AUTHUSERFILE] = $directiveValue;
                            }
                            if($directiveName eq "DefaultType")
                            {
                                #Equivalent IIS tag => MimeMap
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                
                                my $temp = $directiveValue . " " . ".*";
                                $arrayDir[$rowDirCount][ADDTYPE] = $arrayDir[$rowDirCount][ADDTYPE] . $temp . "|";
                            }
                            if($directiveName eq "Deny")
                            {
                                #Equivalent IIS tag => MimeMap
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][DENY] = $directiveValue;
                            }
                            
                            if($directiveName eq "DirectoryIndex")
                            {                                
                                #Equivalent IIS tag => EnableDirBrowsing;
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][DIRECTORYINDEX] = $directiveValue;
                                $arrayDir[$rowDirCount][DIRECTORYINDEX] =~ s/ /,/g;
                            }
                            if($directiveName eq "ErrorDocument")
                            {
                                #Equivalent IIS tag => HttpErrors
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][ERRORDOCUMENT] = $arrayDir[$rowDirCount][ERRORDOCUMENT] . $directiveValue . " ";
                            }
                            if($directiveName eq "ExpiresActive")
                            {
                                #Equivalent IIS tag => HttpExpires
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][EXPIRESACTIVE] = $directiveValue;
                            }
                            
                            if($directiveName eq "HostnameLookups")
                            {
                                #Equivalent IIS tag => EnableReverseDNS
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = $directiveValue;
                            }
                            if($directiveName eq "IdentityCheck")
                            {
                                #Equivalent IIS tag => LogExtFileUserName
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][IDENTITYCHECK] = $directiveValue;
                                
                            }
                            if($directiveName eq "AllowOverride")
                            {
                                #Equivalent IIS tag => Not Applicable.
                                $directiveValue =~ s/^\s+//;
                                $directiveValue =~ s/\s+$//;
                                $arrayDir[$rowDirCount][ALLOWOVERRIDE] = $directiveValue;
                                
                            }
                        }
                    }
                }
            }
        }
    }
}

#######################################################################################################################
#
# Method Name   : pars_setUserdir
#
# Description   : Populate the 2D array with the Userdir directive values 
#
# Input         : None
#
# OutPut        : None
#
# Status        : None
# 
#######################################################################################################################
sub pars_setUserdir
{
    my $i;                          # Loop Counter. 
    my $tempRowCount = $rowCount;   # to store the Row Count value temporarily.
    my $userFileName = "useradd";   # to store the name of the file containing the users on the machine.
    #********************************************************
    #   To determine the home folder on the machine.
    #   The value is present in the file /etc/default/useradd,
    #   corresponding to the HOME entry Ex : HOME=/home
    #********************************************************
    my $startIndex;
    if(&pars_siteSelected("Default Web Site"))
    {
        $startIndex = 0;
    }
    else
    {
        $startIndex = 1;
    }
    for($i=$startIndex; $i <= $tempRowCount; $i++)
    {
        pars_GetFileFromSource("/etc/default/useradd",$userFileName);
        eval
        {
            
            open USERADD,$userFileName or die 'ERR_FILE_OPEN';
            
        };
        if($@)
        {
            if($@=~/ERR_FILE_OPEN/)
            {   
                # log error and exit tool               
                ilog_setLogInformation('INT_ERROR',$userFileName,ERR_FILE_OPEN,__LINE__);       
                return FALSE;                
            }            
        }
        else
        {
            ilog_setLogInformation('INT_INFO',$userFileName,MSG_FILE_OPEN,'');
        }
        
        my @arry;                   # to store the value of the HOME directive.
        my @Listing;                #to store the value(s) of the FTP listing.
        my $temp;
        my @temp;
        while(<USERADD>)
        {
            @arry = split /=/;
            if($arry[0] eq "HOME")
            {
                chomp($arry[1]);    
                @Listing = `ls -L $arry[1]`; # ftp_Listing($arry[1]);
                last;
            }
        }
        if($array[$i][USERDISABLED] == 0 && $array[$i][USERENABLED]  == 1)
        {           
            next;
        }
        # When USERDIR is neither ENABLED nor disabled
        if($array[$i][USERDIRDISABLED] eq "" && $array[$i][USERDIRENABLED] eq "")
        {
            foreach $temp (@Listing)
            {
                my $finalPath = $arry[1] . "/" . $temp;
                my @dirListing;
                my $continue = 0;
                chomp($temp);
                @dirListing = `ls -L $finalPath`; # ftp_Listing($finalPath);                        
                foreach(@dirListing)
                {
                    chomp($_);
                    if($_ eq $array[$i][USERDIR])
                    {
                        $continue = 1;
                        last;
                    }
                }
                if($continue)
                {
                    $continue = 0;
                    @temp = split / /,$temp;
                    my $userdirName = $array[$i][SITENAME] . "/~" .$temp[$#temp];
                    my $Indexj = 0;
                    my $tempPath = $array[$i][DESTINATIONPATH];
                    $tempPath =~ s/\\$//;
                    # Check for the keyword's disabled and enabled as below
                    ++$rowDirCount;
                    $arrayDir[$rowDirCount][SITENAME] = $array[$i][SITENAME];
                    chomp($arry[1]);
                    chomp($temp[$#temp]);
                    chomp($array[$i][USERDIR]);
                    $arrayDir[$rowDirCount][DIRECTORY] = $arry[1] . "/" .$temp[$#temp] . "/" . $array[$i][USERDIR];
                    $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "Off";
                    $arrayDir[$rowDirCount][IDENTITYCHECK] = "Off";
                    $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
                    $arrayDir[$rowDirCount][DOCUMENTROOT] = $array[$rowCount][DIRECTORY];
                    if($tempPath =~ /\/$/)
                    {
                        $tempPath =~ s/\/$//;
                    }
                    
                    $arrayDir[$rowDirCount][DESTINATIONPATH] = $tempPath . "\\~$temp[$#temp]";
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\\/\//g;
                    $arrayDir[$rowDirCount][USERDIR] = 1;                    
                }
            }
        }
        # When USERDIR is DISABLED followed by blank
        elsif ($array[$i][USERDIRDISABLED] eq "")
        {           
            my @userList = split / /,$array[$i][USERDIRENABLED];            
            foreach $temp (@Listing)
            {
                my $tempUser;
                my $finalPath = $arry[1] . "/" . $temp;
                my @dirListing;
                my $continue = 0;
                chomp($temp);
                @dirListing = `ls -L $finalPath`; # ftp_Listing($finalPath);
                foreach(@dirListing)
                {
                    chomp($_);
                    if($_ eq $array[$i][USERDIR])
                    {                        
                        $continue = 1;
                        last;
                    }
                }

                if($continue)
                {                    
                    $continue = 0;                    
                    foreach $tempUser (@userList)
                    {
                        $temp =~ s/^\s+//;
                        $temp =~ s/\s+$//;
                        $tempUser =~ s/^\s+//;
                        $tempUser =~ s/\s+$//;
                        if($temp eq $tempUser)
                        {                            
                            @temp = split / /,$temp;
                            my $userdirName = $array[$i][SITENAME] . "/~" .$temp[$#temp];
                            my $Indexj = 0;
                            my $tempPath = $array[$i][DESTINATIONPATH];
                            $tempPath =~ s/\\$//;
                            # Check for the keyword's disabled and enabled as below
                            
                            ++$rowDirCount;
                            $arrayDir[$rowDirCount][SITENAME] = $array[$i][SITENAME];
                            chomp($arry[1]);
                            chomp($temp[$#temp]);
                            chomp($array[$i][USERDIR]);
                            $arrayDir[$rowDirCount][DIRECTORY] = $arry[1] . "/" .$temp[$#temp] . "/" . $array[$i][USERDIR];
                            $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "Off";
                            $arrayDir[$rowDirCount][IDENTITYCHECK] = "Off";
                            $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
                            $arrayDir[$rowDirCount][DOCUMENTROOT] = $array[$rowCount][DIRECTORY];
                            if($tempPath =~ /\/$/)
                            {
                                $tempPath =~ s/\/$//;
                            }
                            
                            $arrayDir[$rowDirCount][DESTINATIONPATH] = $tempPath . "\\~$temp[$#temp]";
                            $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\\/\//g;
                            $arrayDir[$rowDirCount][USERDIR] = 1;
                            
                        }
                    }                    
                }
            }
        }       
        
        # When USERDIR is ENABLED followed by blank
        elsif ($array[$i][USERDIRENABLED] eq "")
        {
            foreach $temp (@Listing)
            {
                my $finalPath = $arry[1] . "/" . $temp;
                my @dirListing;
                my $continue = 0;
                chomp($temp);
                @dirListing = `ls -L $finalPath`; # ftp_Listing($finalPath);
                foreach(@dirListing)
                {
                    chomp($_);
                    if($_ eq $array[$i][USERDIR])
                    {
                        $continue = 1;
                        last;
                    }
                }

                if($continue)
                {
                    $continue = 0;
                    my $tempUser;
                    my $continueNow = 1;
                    my @userList = split / /,$array[$i][USERDIRDISABLED];
                    foreach $tempUser (@userList)
                    {
                        if($temp eq $tempUser)
                        {
                            $continueNow = 0;
                            last;
                        }
                    }

                    $temp =~ s/^\s+//;
                    $temp =~ s/\s+$//;
                    $tempUser =~ s/^\s+//;
                    $tempUser =~ s/\s+$//;
                    if($continueNow)
                    {
                        @temp = split / /,$temp;
                        my $userdirName = $array[$i][SITENAME] . "/~" .$temp[$#temp];
                        my $Indexj = 0;
                        my $tempPath = $array[$i][DESTINATIONPATH];
                        $tempPath =~ s/\\$//;
                        # Check for the keyword's disabled and enabled as below                        
                        ++$rowDirCount;
                        $arrayDir[$rowDirCount][SITENAME] = $array[$i][SITENAME];
                        chomp($arry[1]);
                        chomp($temp[$#temp]);
                        chomp($array[$i][USERDIR]);
                        $arrayDir[$rowDirCount][DIRECTORY] = $arry[1] . "/" .$temp[$#temp] . "/" . $array[$i][USERDIR];
                        $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "Off";
                        $arrayDir[$rowDirCount][IDENTITYCHECK] = "Off";
                        $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
                        $arrayDir[$rowDirCount][DOCUMENTROOT] = $array[$rowCount][DIRECTORY];
                        if($tempPath =~ /\/$/)
                        {
                            $tempPath =~ s/\/$//;
                        }
                        
                        $arrayDir[$rowDirCount][DESTINATIONPATH] = $tempPath . "\\~$temp[$#temp]";
                        $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\\/\//g;
                        $arrayDir[$rowDirCount][USERDIR] = 1;                        
                    }
                }
            }   
        }
        eval
        {            
            close USERADD or die 'ERR_FILE_CLOSE';          
        };
        if($@)
        {
            if($@=~/ERR_FILE_CLOSE/)
            {   
                # log 'file close error' and continue                
                ilog_setLogInformation('INT_ERROR',$userFileName,ERR_FILE_CLOSE,__LINE__);                
            }
            
        }
        else
        {
            ilog_setLogInformation('INT_INFO',$userFileName,MSG_FILE_CLOSE,'');
        }
        
        # Delete the UserName/UserPassword file.
        eval
        {            
            unlink($userFileName) or die 'ERR_FILE_DELETE';            
        };
        if($@)
        {
            if($@=~/ERR_FILE_DELETE/)
            {   
                # log error and exit tool
                
                ilog_setLogInformation('INT_ERROR',$userFileName,ERR_FILE_DELETE,__LINE__);     
                return FALSE;                
            }            
        }
        else
        {
            ilog_setLogInformation('INT_INFO',$userFileName,MSG_FILE_DELETE,'');
        }
    }
}

sub pars_defaultsitePath
{
    my @tmpArray;
    my $recoveryFile = $ResourceFile;
    eval
    {        
        open RECOVERYHANDLE ,$recoveryFile or die 'ERR_FILE_OPEN';        
    };
    if($@)
    {
        if($@=~/ERR_FILE_OPEN/)
        {   
            # log error and exit tool           
            ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_OPEN,__LINE__);       
            return FALSE;            
        }        
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_OPEN,'');
    }
    while ($lineContent = <RECOVERYHANDLE>) 
    {
        chomp($lineContent);
        if($lineContent eq "[Default Web Site]")
        {
            while ($lineContent = <RECOVERYHANDLE>) 
            {                   
                if($lineContent =~ /^DestinationPath/)
                {
                    @tmpArray = split /=/,$lineContent;
                    $defaultPath = $tmpArray[1];
                    if($defaultPath =~ /[A-Za-z]:$/)
                    {
                        chomp($defaultPath); 
                        $defaultPath = $defaultPath . "\\\\";                       
                    }
                    elsif($defaultPath =~ /[A-Za-z]:\\$/)
                    {
                        chomp($defaultPath); 
                        $defaultPath = $defaultPath . "\\";                     
                    }
                    chomp($defaultPath); 
                    last;
                }
            }
            eval
            {                   
                close RECOVERYHANDLE or die 'ERR_FILE_CLOSE';           
            };
            if($@)
            {
                if($@=~/ERR_FILE_CLOSE/)
                {
                    # log 'file close error' and continue                   
                    ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_CLOSE,__LINE__);
                }   
            }
            else
            {
                ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_CLOSE,'');
            }
            return 1;
        }
    }
    eval
    {        
        close RECOVERYHANDLE or die 'ERR_FILE_CLOSE';        
    };
    if($@)
    {
        if($@=~/ERR_FILE_CLOSE/)
        {
            # log 'file close error' and continue           
            ilog_setLogInformation('INT_ERROR',$recoveryFile,ERR_FILE_CLOSE,__LINE__);                  
        }        
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$recoveryFile,MSG_FILE_CLOSE,'');
    }
    return 0; 
}

#######################################################################################################################
#
# Method Name   : pars_createXML
#
# Description   : Generate the Config.XML
#
# Input         : None
#
# OutPut        : None
#
# Status        : None
# 
#######################################################################################################################
sub pars_createXML
{
    my $iisXML = xml::doc::->new;
    my $i;
    my $startIndex;
    my $outFileName = &pars_GetSessionFolder() . AMW . &ilog_getSessionName() . FILE_TASKLIST;
    my $sites = &pars_GetSessionFolder() . AMW . &ilog_getSessionName() . FILE_SITES;
    $errorDocument[$errorDocumentCount] = "S" . TASKLIST_DELIM . "Error Document file(s)\n";
    # To create the sites.txt file.
    eval
    {
        open SITES,">$sites" or die 'ERR_FILE_OPEN'; 
        
    };
    if($@)
    {
        if($@=~/ERR_FILE_OPEN/)
        {   
            # log error and exit tool           
            ilog_setLogInformation('INT_ERROR',$sites,ERR_FILE_OPEN,__LINE__);      
            return FALSE;            
        }        
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$sites,MSG_FILE_OPEN,'');
    }
    my $temp; 
    if(&pars_siteSelected("Default Web Site"))
    {
        $startIndex = 0;
    }
    else
    {
        $startIndex = 1;
    }
    for($i = $startIndex;$i <= $rowCount; $i++)
    {
        $temp = $array[$i][SITENAME];
        $temp =~ s/\s+//g;
        print SITES "S /LM/W3SVC/$i\n";
        print SITES "P 80\n";       # Create with Port 80 and override with ServerBinding rom config XML 
        print SITES "N $temp\n";
        $temp = $array[$i][DESTINATIONPATH];
        $temp =~ s/\//\\/g;
        print SITES "H $temp\n";
    }
    
    ## To generate the IISCONFIG.xml file
    ## Config
    $iisXML->addNode("/Config");
    $iisXML->getNode("/Config")->setTagName("configuration");
    $iisXML->getNode("/Config")->setAttrib("xmlns","urn:microsoft-catalog:null-placeholder");   
    ## Config -> MBProperty
    $iisXML->addNode("/Config/MBProperty");
    $iisXML->getNode("/Config/MBProperty")->setTagName("MBProperty");   
    ## Config -> MBProperty -> IIS_Global 
    $iisXML->addNode("/Config/MBProperty/IIS_Global");
    $iisXML->getNode("/Config/MBProperty/IIS_Global")->setTagName("IIS_Global");    
    $iisXML->getNode("/Config/MBProperty/IIS_Global")->setAttrib("Location", ".");
    ## Config -> MBProperty -> Others
    for($i = $startIndex;$i <= $rowCount; $i++)
    {
        $iisXML->addNode("/Config/MBProperty/IIS_SERVER_$i");
        $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setTagName("IIsWebServer");
        $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("Location", "/LM/W3SVC/$i");
        
        if($array[$i][KEEPALIVE] ne "")
        {
            if($array[$i][KEEPALIVE] eq "On")
            {
                $array[$i][KEEPALIVE] = "TRUE";
            }
            elsif($array[$i][KEEPALIVE] eq "Off")
            {
                $array[$i][KEEPALIVE] = "FALSE";    
            }
            
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("AllowKeepAlive", "$array[$i][KEEPALIVE]");
        }
        if($array[$i][IDENTITYCHECK] ne "")
        {
            if($array[$i][IDENTITYCHECK] eq "on" || $array[$i][IDENTITYCHECK] eq "On")
            {
                $array[$i][IDENTITYCHECK] = "LogExtFileDate | LogExtFileTime | LogExtFileClientIp | LogExtFileUserName | LogExtFileServerIp | LogExtFileMethod | LogExtFileUriStem | LogExtFileUriQuery | LogExtFileHttpStatus | LogExtFileServerPort | LogExtFileUserAgent";
            }
            elsif($array[$i][IDENTITYCHECK] eq "off" || $array[$i][IDENTITYCHECK] eq "Off")
            {
                $array[$i][IDENTITYCHECK] = "LogExtFileDate | LogExtFileTime | LogExtFileClientIp | LogExtFileServerIp | LogExtFileMethod | LogExtFileUriStem | LogExtFileUriQuery | LogExtFileHttpStatus | LogExtFileServerPort | LogExtFileUserAgent";    
            }
            
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("LogExtFileFlags", "$array[$i][IDENTITYCHECK]");
        }
        if($array[$i][KEEPALIVETIMEOUT] ne "")
        {
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("ConnectionTimeout", "$array[$i][KEEPALIVETIMEOUT]");
        }
        if($array[$i][LISTENBACKLOG] ne "")
        {
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("ServerListenBacklog", "$array[$i][LISTENBACKLOG]");
        }
        if($array[$i][MAXCLIENTS] ne "")
        {
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("MaxConnections", "$array[$i][MAXCLIENTS]");
        }

        $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("ServerBindings", $ServerBinding{$array[$i][SITENAME]});        
        my @tempMime;
        my $appendValue;
        if($array[$i][ADDENCODING] ne "")
        {
            $array[$i][ADDENCODING] =~ s/\|$//;
            @tempMime = split /\|/, $array[$i][ADDENCODING];            
            my $j;
            my $placeHolder;            
            foreach $placeHolder (@tempMime)
            {
                my @temp;                
                chomp($placeHolder);
                @temp = split /\s+/,$placeHolder;
                for($j=1;$j<=$#temp;$j++)
                {
                    $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                }                
            }
        }
        
        if($array[$i][ADDTYPE] ne "")
        {
            $array[$i][ADDTYPE] =~ s/\|$//;
            @tempMime = split /\|/, $array[$i][ADDTYPE];
            my $j;            
            foreach(@tempMime)
            {
                my @temp;                
                chomp($_);
                @temp = split /\s+/, $_;
                for($j=1;$j<=$#temp;$j++)
                {
                    $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                }
            }
        }

        if($appendValue !~ /\.\*/g)
        {
            $appendValue = $appendValue . ".*" . "," . $array[$i][DEFAULTTYPE] . "\n";            
        }
        if($mimeTypes ne "")
        {
            $appendValue = $appendValue . $mimeTypes;
        }
        if($appendValue ne "")
        {
            $appendValue =~ s/ $//;
            chomp($appendValue);
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("MimeMap", $appendValue);
        }
        
        if($array[$i][AUTHNAME] ne "")
        {
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("Realm", "$array[$i][AUTHNAME]");
        }
        if($array[$i][AUTHTYPE] ne "")
        {
            if($array[$i][AUTHTYPE] eq "Basic")
            {                
                $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("AuthFlags", "AuthBasic");
            }
            elsif($array[$i][AUTHTYPE] eq "Digest")
            {
                $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("AuthFlags", "AuthMD5");
            }
            elsif($array[$i][AUTHTYPE] eq "Basic|Digest")
            {
                $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
            }
            elsif($array[$i][AUTHTYPE] eq "Digest|Basic")
            {
                $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
            }
        }
        if($array[$i][OPTIONS] ne "")
        {
            my @temp;
            @temp = split / /,$array[$i][OPTIONS];
            foreach(@temp)
            {
                if($_ eq "All")
                {
                    $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");
                    $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript | AccessSource | AccessWrite");
                    last;
                }
                elsif($_ eq "Indexes")
                {
                    $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");                    
                }
                elsif($_ eq "ExecCGI")
                {
                    $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript");
                }
            }
        }

        if($array[$i][ERRORDOCUMENT] ne "")
        {
            my @temp = split / /,$array[$i][ERRORDOCUMENT];
            my $k;
            my $append;
            my $string;
            for($k=0; $k<=$#temp; $k = $k + 2)
            {
                if($temp[$k+1] =~ /^http:\/\//)
                {
                    $append = $append . $temp[$k] . ",*" . ",URL," . $temp[$k+1] ."\n";
                }
                elsif($temp[$k+1] =~ /^"/)
                {
                    #NO equivalent mapping found on IIS.
                }
                else
                {                    
                    if(index($temp[$k+1],$array[$i][DOCUMENTROOT]) == -1)
                    {
                        $string = $temp[$k+1];
                        $string =~ s/\//\\/g;
                        $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . $string ."\n";
                        my $tmp;    
                        my $tmp2;
                        my $jk;
                        my $fileName;
                        my @splitAry = split /\//, $temp[$k+1];
                        for($jk = 0; $jk < $#splitAry; $jk++)
                        {
                            $tmp = $tmp . $splitAry[$jk] . "/";
                        }
                        $fileName = $splitAry[$#splitAry];
                        $tmp =~ s/\/$//;
                        $tmp2 = $array[$i][DESTINATIONPATH] . $tmp;
                        $tmp2 =~ s/\//\\/g;
                        $errorDocumentCount++;
                        $errorDocument[$errorDocumentCount] = "D" . TASKLIST_DELIM . $tmp . TASKLIST_DELIM .  $tmp2 . "\n";
                        $errorDocumentCount++;
                        $errorDocument[$errorDocumentCount] = "F" . TASKLIST_DELIM . $fileName . "\n";
                    }
                    else
                    {                        
                        $string = $temp[$k+1];
                        $string =~ s/\//\\/g;
                        $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . pars_getRelativePath($string,$array[$i][DOCUMENTROOT]) ."\n";                        
                    }                   
                }               
            }

            chomp($append);
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("HttpErrors", "$append");
        }
        if($array[$i][DIRECTORYINDEX] ne "")
        {
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("DefaultDoc", "$array[$i][DIRECTORYINDEX]");
        }
        
        if($array[$i][EXPIRESACTIVE] ne "")
        {
            if($array[$i][EXPIRESACTIVE] eq  "on" || $array[$i][EXPIRESACTIVE] eq "On") 
            {
                $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("HttpExpires", "D, 0");
            }
        }

        if($array[$i][HEADER] ne "")
        {
            my @headerArray = split /\|/ , $array[$i][HEADER];
            my @intArray;
            my $tmpArray;
            my $tmpArray2;
            foreach(@headerArray)
            {
                
                $_ =~ s/"//g;
                @intArray = split / /,$_;
                $tmpArray2 = "";
                foreach (@intArray)
                {
                    next if($_ eq $intArray[0]);
                    next if($_ eq $intArray[1]);
                    $tmpArray2 = $tmpArray2 . $_ . " ";
                }
                $tmpArray2 =~ s/ $//;
                $tmpArray = $tmpArray . $intArray[1] . ": " . $tmpArray2 . "\n";
            }
            $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("HttpCustomHeaders", $tmpArray);
        }
        if($array[$i][HOSTNAMELOOKUPS] ne "")
        {
            if($array[$i][HOSTNAMELOOKUPS] eq  "On" || $array[$i][HOSTNAMELOOKUPS] eq  "on")
            {
                $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("EnableReverseDns", "TRUE");
            }
            elsif($array[$i][HOSTNAMELOOKUPS] eq  "Off" || $array[$i][HOSTNAMELOOKUPS] eq  "off")
            {
                $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("EnableReverseDns", "FALSE");
            }
        }
        if($array[$i][SITENAME] ne "")
        {
            if($i == 0 && $array[$i][SERVERNAME] ne "" && !(utf_isValidIP($array[$i][SERVERNAME])))
            {
                $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("ServerComment","$array[$i][SERVERNAME]");
            }
            else
            {
                $iisXML->getNode("/Config/MBProperty/IIS_SERVER_$i")->setAttrib("ServerComment","$array[$i][SITENAME]");
            }
        }
        # Add code to append virtual directories.
        # pass thru all the rows of the directory entries enumerating the directories.
        my $j = 0;
        
        for($j=0; $j <= $rowDirCount; $j++)
        {
            #this part of the code is added to take care of the location for the ROOT entry
            if($arrayDir[$j][SITENAME] eq $array[$i][SITENAME])
            {
                if($arrayDir[$j][DIRECTORY] eq $array[$i][DOCUMENTROOT])
                {
                    $arrayDir[$j][XML] = 1;
                    $iisXML->addNode("/Config/MBProperty/Vdir_$i$j");
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setTagName("IIsWebVirtualDir");
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Location", "/LM/W3SVC/$i/ROOT");
                    
                    if($arrayDir[$j][DIRECTORYINDEX] ne "")
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                    }
                    
                    if($arrayDir[$j][MAXCLIENTS] ne "")
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MaxConnections", "$arrayDir[$j][MAXCLIENTS]");
                    }
                    my @tempMime;
                    my $appendValue;
                    
                    if($arrayDir[$j][ADDENCODING] ne "")
                    {
                        $arrayDir[$j][ADDENCODING] =~ s/\|$//;
                        @tempMime = split /\|/, $arrayDir[$j][ADDENCODING];
                        my $j;
                        
                        foreach(@tempMime)
                        {
                            my @temp;
                            
                            chomp($_);
                            @temp = split /\s+/, $_;
                            for($j=1;$j<=$#temp;$j++)
                            {
                                $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                            }
                        }                        
                    }
                    if($arrayDir[$j][ADDTYPE] ne "")
                    {
                        $arrayDir[$j][ADDTYPE] =~ s/\|$//;
                        @tempMime = split /\|/, $arrayDir[$j][ADDTYPE];
                        my $j;
                        
                        foreach(@tempMime)
                        {
                            my @temp;
                            
                            chomp($_);
                            @temp = split /\s+/, $_;
                            for($j=1;$j<=$#temp;$j++)
                            {
                                $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                            }                            
                        }
                    }

                    if($appendValue ne "")
                    {
                        $appendValue =~ s/ $//;
                        chomp($appendValue);
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MimeMap", $appendValue);
                    }
                    if($arrayDir[$j][OPTIONS] ne "")
                    {
                        my @temp;
                        @temp = split / /,$arrayDir[$j][OPTIONS];
                        foreach(@temp)
                        {
                            if($_ eq "All")
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript | AccessSource | AccessWrite");
                                last;
                            }
                            elsif($_ eq "Indexes")
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");
                                
                            }
                            elsif($_ eq "ExecCGI")
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript");
                            }
                        }                        
                    }
                    
                    if($arrayDir[$j][DIRECTORYINDEX] ne "")
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                    }
                    if($arrayDir[$j][AUTHNAME] ne "")
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Realm", "$arrayDir[$j][AUTHNAME]");
                    }
                    if($arrayDir[$j][AUTHTYPE] ne "")
                    {
                        if($arrayDir[$j][AUTHTYPE] eq "Basic")
                        {   
                            
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic");
                        }
                        elsif($arrayDir[$j][AUTHTYPE] eq "Digest")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthMD5");
                        }
                        elsif($arrayDir[$j][AUTHTYPE] eq "Basic|Digest")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                        }
                        elsif($arrayDir[$j][AUTHTYPE] eq "Digest|Basic")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                        }
                    }
                    if($arrayDir[$j][ERRORDOCUMENT] ne "")
                    {
                        my @temp = split / /,$arrayDir[$j][ERRORDOCUMENT];
                        my $k;
                        my $append;
                        my $string;
                        for($k=0; $k<=$#temp; $k = $k + 2)
                        {
                            if($temp[$k+1] =~ /^http:\/\//)
                            {
                                $append = $append . $temp[$k] . ",*" . ",URL," . $temp[$k+1] ."\n";
                            }
                            elsif($temp[$k+1] =~ /^"/)
                            {
                                #NO equivalent mapping found on IIS.
                            }
                            else
                            {                               
                                if(index($temp[$k+1],$arrayDir[$j][DOCUMENTROOT]) == -1)
                                {
                                    $string = $temp[$k+1];
                                    $string =~ s/\//\\/g;
                                    $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . $string ."\n";
                                    my $tmp;    
                                    my $tmp2;
                                    my $jk;
                                    my $fileName;
                                    my @splitAry = split /\//, $temp[$k+1];
                                    for($jk = 0; $jk < $#splitAry; $jk++)
                                    {
                                        $tmp = $tmp . $splitAry[$jk] . "/";
                                    }
                                    $fileName = $splitAry[$#splitAry];
                                    $tmp =~ s/\/$//;
                                    $tmp2 = $array[$i][DESTINATIONPATH] . $tmp;
                                    $tmp2 =~ s/\//\\/g;
                                    $errorDocumentCount++;
                                    $errorDocument[$errorDocumentCount] = "D" . TASKLIST_DELIM . $tmp . TASKLIST_DELIM .  $tmp2 . "\n";
                                    $errorDocumentCount++;
                                    $errorDocument[$errorDocumentCount] = "F" . TASKLIST_DELIM . $fileName . "\n"; 
                                    
                                }
                                else
                                {
                                    $string = $temp[$k+1];
                                    $string =~ s/\//\\/g;
                                    $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . pars_getRelativePath($string,$array[$i][DOCUMENTROOT]) ."\n";
                                }
                            }                            
                        }

                        chomp($append);
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpErrors", "$append");
                    }
                    
                    if($arrayDir[$j][EXPIRESACTIVE] ne "")
                    {
                        if($arrayDir[$j][EXPIRESACTIVE] eq  "on" || $arrayDir[$j][EXPIRESACTIVE] eq "On")   
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpExpires", "D, 0");
                        }
                    }
                    if($arrayDir[$j][HEADER] ne "")
                    {
                        my @headerArray = split /\|/ , $arrayDir[$j][HEADER];
                        my @intArray;
                        my $tmpArray;
                        my $tmpArray2;
                        foreach(@headerArray)
                        {
                            
                            $_ =~ s/"//g;
                            @intArray = split / /,$_;
                            $tmpArray2 = "";
                            foreach (@intArray)
                            {
                                next if($_ eq $intArray[0]);
                                next if($_ eq $intArray[1]);
                                $tmpArray2 = $tmpArray2 . $_ . " ";
                            }
                            $tmpArray2 =~ s/ $//;
                            $tmpArray = $tmpArray . $intArray[1] . ": " . $tmpArray2 . "\n";
                        }
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpCustomHeaders", $tmpArray);
                    }
                    if($arrayDir[$j][HOSTNAMELOOKUPS] ne "")
                    {
                        
                        if($arrayDir[$j][HOSTNAMELOOKUPS] eq  "On" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "on")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "TRUE");
                        }
                        elsif($arrayDir[$j][HOSTNAMELOOKUPS] eq  "Off" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "off")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "FALSE");
                        }
                        
                    }
                    if($arrayDir[$j][DESTINATIONPATH] ne "")
                    {
                        
                        my $temp = $array[$i][DESTINATIONPATH];
                        $temp =~ s/\//\\/g;
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Path", $temp);
                    }
                }
            }
            my @temp;
            my $k = 0;
            my $dirFlag = 0;
            # Code added to take care of the Alias.
            
            if($array[$i][SITENAME] eq $arrayDir[$j][SITENAME])
            { 
                @temp = split /\²/,$array[$i][ALIAS];
                
                for($k=0;$k<$#temp; $k = $k + 2)
                {
                    
                    my $directoryName;
                    my $tempName;
                    $directoryName = $arrayDir[$j][DIRECTORY];
                    $tempName = $temp[$k+1];
                    $directoryName =~ s/\/$//;
                    $tempName      =~ s/\/$//;
                    
                    if($directoryName eq $tempName)
                    {
                        my $indexI;
                        for($indexI = 0; $indexI <= $aliasDirInd;$indexI++)     
                        {
                            if($array[$i][SITENAME] eq $aliasDir[$indexI][0])
                            {
                                if($tempName eq $aliasDir[$indexI][1])
                                {
                                    $aliasDir[$indexI][2] = 0;
                                }
                            }
                        }

                        #append the IIsWebVirtualDir tag.       
                        $arrayDir[$j][DIRBITSET] = 1;
                        $arrayDir[$j][XML] = 1;
                        $iisXML->addNode("/Config/MBProperty/Vdir_$i$j");
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setTagName("IIsWebVirtualDir");                       
                        my $tem = $temp[$k];
                        $tem =~ s/^\///;
                        $tem =~ s/\/$//;
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Location", "/LM/W3SVC/$i/ROOT/$tem");                      
                        if($arrayDir[$j][DIRECTORYINDEX] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                        }
                        
                        if($arrayDir[$j][MAXCLIENTS] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MaxConnections", "$arrayDir[$j][MAXCLIENTS]");
                        }

                        my @tempMime;
                        my $appendValue;                        
                        if($arrayDir[$j][ADDENCODING] ne "")
                        {
                            $arrayDir[$j][ADDENCODING] =~ s/\|$//;
                            @tempMime = split /\|/, $arrayDir[$j][ADDENCODING];
                            my $j;                            
                            foreach(@tempMime)
                            {   
                                my @temp;                                
                                chomp($_);
                                @temp = split /\s+/, $_;
                                for($j=1;$j<=$#temp;$j++)
                                {
                                    $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                                }                                
                            }                            
                        }

                        if($arrayDir[$j][ADDTYPE] ne "")
                        {
                            $arrayDir[$j][ADDTYPE] =~ s/\|$//;
                            @tempMime = split /\|/, $arrayDir[$j][ADDTYPE];
                            my $j;                            
                            foreach(@tempMime)
                            {   
                                my @temp;                                
                                chomp($_);
                                @temp = split /\s+/, $_;
                                for($j=1;$j<=$#temp;$j++)
                                {
                                    $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                                }
                            }
                        }

                        if($appendValue !~ /\.\*/g)
                        {   
                            $appendValue = $appendValue . ".*,text/plain\n";
                        }       
                        if($appendValue ne "")
                        {
                            $appendValue =~ s/ $//;
                            chomp($appendValue);
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MimeMap", $appendValue);
                        }
                        if($arrayDir[$j][OPTIONS] ne "")
                        {
                            my @temp;
                            @temp = split / /,$arrayDir[$j][OPTIONS];
                            foreach(@temp)
                            {
                                if($_ eq "All")
                                {
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript | AccessSource | AccessWrite");
                                    last;
                                }
                                elsif($_ eq "Indexes")
                                {
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");
                                    
                                }
                                elsif($_ eq "ExecCGI")
                                {
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript");
                                }
                            }                            
                        }
                        if($arrayDir[$j][DIRECTORYINDEX] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                        }
                        if($arrayDir[$j][AUTHNAME] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Realm", "$arrayDir[$j][AUTHNAME]");
                        }
                        if($arrayDir[$j][AUTHTYPE] ne "")
                        {
                            if($arrayDir[$j][AUTHTYPE] eq "Basic")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic");                                
                            }
                            elsif($arrayDir[$j][AUTHTYPE] eq "Digest")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthMD5");
                            }
                            elsif($arrayDir[$j][AUTHTYPE] eq "Basic|Digest")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                            }
                            elsif($arrayDir[$j][AUTHTYPE] eq "Digest|Basic")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                            }
                        }
                        
                        if($arrayDir[$j][ERRORDOCUMENT] ne "")
                        {
                            my @temp = split / /,$arrayDir[$j][ERRORDOCUMENT];
                            my $k;
                            my $append;
                            my $string;
                            for($k=0; $k<=$#temp; $k = $k + 2)
                            {
                                if($temp[$k+1] =~ /^http:\/\//)
                                {
                                    $append = $append . $temp[$k] . ",*" . ",URL," . $temp[$k+1] ."\n";
                                }
                                
                                elsif($temp[$k+1] =~ /^"/)
                                {
                                    #Ignore it now, Not clear on the mapping to the config.xml : to be sorted out later
                                }
                                else
                                {
                                    if(index($temp[$k+1],$arrayDir[$j][DOCUMENTROOT]) == -1)
                                    {
                                        $string = $temp[$k+1];
                                        $string =~ s/\//\\/g;
                                        $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . $string ."\n";
                                        my $tmp;    
                                        my $tmp2;
                                        my $jk;
                                        my $fileName;
                                        my @splitAry = split /\//, $temp[$k+1];
                                        for($jk = 0; $jk < $#splitAry; $jk++)
                                        {
                                            $tmp = $tmp . $splitAry[$jk] . "/";
                                        }
                                        $fileName = $splitAry[$#splitAry];
                                        $tmp =~ s/\/$//;
                                        $tmp2 = $array[$i][DESTINATIONPATH] . $tmp;
                                        $tmp2 =~ s/\//\\/g;
                                        $errorDocumentCount++;
                                        $errorDocument[$errorDocumentCount] = "D" . TASKLIST_DELIM . $tmp . TASKLIST_DELIM .  $tmp2 . "\n";
                                        $errorDocumentCount++;
                                        $errorDocument[$errorDocumentCount] = "F" . TASKLIST_DELIM . $fileName . "\n"; 
                                        
                                    }
                                    else
                                    {
                                        $string = $temp[$k+1];
                                        $string =~ s/\//\\/g;
                                        $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . pars_getRelativePath($string,$array[$i][DOCUMENTROOT]) ."\n";
                                    }
                                }
                            }
                            chomp($append);
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpErrors", "$append");
                        }
                        
                        if($arrayDir[$j][EXPIRESACTIVE] ne "")
                        {
                            if($arrayDir[$j][EXPIRESACTIVE] eq  "on" || $arrayDir[$j][EXPIRESACTIVE] eq "On")   
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpExpires", "D, 0");
                            }
                        }
                        if($arrayDir[$j][HEADER] ne "")
                        {
                            my @headerArray = split /\|/ , $arrayDir[$j][HEADER];
                            my @intArray;
                            my $tmpArray;
                            my $tmpArray2;
                            foreach(@headerArray)
                            {
                                
                                $_ =~ s/"//g;
                                @intArray = split / /,$_;
                                $tmpArray2 = "";
                                foreach (@intArray)
                                {
                                    next if($_ eq $intArray[0]);
                                    next if($_ eq $intArray[1]);
                                    $tmpArray2 = $tmpArray2 . $_ . " ";
                                }
                                $tmpArray2 =~ s/ $//;
                                $tmpArray = $tmpArray . $intArray[1] . ": " . $tmpArray2 . "\n";
                            }
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpCustomHeaders", $tmpArray);
                        }
                        if($arrayDir[$j][HOSTNAMELOOKUPS] ne "")
                        {
                            if($arrayDir[$j][HOSTNAMELOOKUPS] eq  "On" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "on")
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "TRUE");
                            }
                            elsif($arrayDir[$j][HOSTNAMELOOKUPS] eq  "Off" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "off")
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "FALSE");
                            }                            
                        }
                        if($arrayDir[$j][DESTINATIONPATH] ne "")
                        {                           
                            my $temp = $arrayDir[$j][DESTINATIONPATH];
                            $temp =~ s/\//\\/g;
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Path", $temp);
                        }                       
                    }
                }
            }
        }
        # Code added to take care of the ScriptAlias.
        $j = 0;        
        for($j=0; $j <= $rowDirCount; $j++)
        {
            #this part of the code is added to take care of the location for the ROOT entry
            my @temp;
            my $k = 0;          
            if($array[$i][SITENAME] eq $arrayDir[$j][SITENAME])
            {
                @temp = split /\²/,$array[$i][SCRIPTALIAS];                
                for($k=0;$k<$#temp; $k = $k + 2)
                {
                    my $directoryName;
                    my $tempName;
                    $directoryName = $arrayDir[$j][DIRECTORY];
                    $tempName = $temp[$k+1];                    
                    $directoryName =~ s/\/$//;
                    $tempName      =~ s/\/$//;                    
                    if($directoryName eq $tempName)
                    {
                        my $indexI;                        
                        for($indexI = 0; $indexI <= $scriptaliasDirInd;$indexI++)       
                        {
                            if($array[$i][SITENAME] eq $scriptaliasDir[$indexI][0])
                            {                               
                                if($tempName eq $scriptaliasDir[$indexI][1])
                                {
                                    $scriptaliasDir[$indexI][2] = 0;                                    
                                }
                            }
                        }

                        #append the IIsWebVirtualDir tag.       
                        $arrayDir[$j][DIRBITSET] = 1;
                        $arrayDir[$j][XML] = 1;
                        $iisXML->addNode("/Config/MBProperty/Vdir_$i$j");
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setTagName("IIsWebVirtualDir");
                        
                        my $tem = $temp[$k];
                        $tem =~ s/^\///;
                        $tem =~ s/\/$//;
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Location", "/LM/W3SVC/$i/ROOT/$tem");
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript");
                        
                        if($arrayDir[$j][DIRECTORYINDEX] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                        }
                        
                        if($arrayDir[$j][MAXCLIENTS] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MaxConnections", "$arrayDir[$j][MAXCLIENTS]");
                        }

                        my @tempMime;
                        my $appendValue;                        
                        if($arrayDir[$j][ADDENCODING] ne "")
                        {
                            $arrayDir[$j][ADDENCODING] =~ s/\|$//;
                            @tempMime = split /\|/, $arrayDir[$j][ADDENCODING];
                            my $j;
                            
                            foreach(@tempMime)
                            {
                                my @temp;
                                
                                chomp($_);
                                @temp = split /\s+/, $_;
                                for($j=1;$j<=$#temp;$j++)
                                {
                                    $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                                }
                            }
                        }

                        if($arrayDir[$j][ADDTYPE] ne "")
                        {
                            $arrayDir[$j][ADDTYPE] =~ s/\|$//;
                            @tempMime = split /\|/, $arrayDir[$j][ADDTYPE];
                            my $j;
                            
                            foreach(@tempMime)
                            {   
                                my @temp;
                                
                                chomp($_);
                                @temp = split /\s+/, $_;
                                for($j=1;$j<=$#temp;$j++)
                                {
                                    $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                                }                                
                            }                            
                        }

                        if($appendValue !~ /\.\*/g)
                        {
                            $appendValue = $appendValue . ".*,text/plain\n";
                        }

                        if($appendValue ne "")
                        {
                            chomp($appendValue);
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MimeMap", $appendValue);
                        }

                        if($arrayDir[$j][OPTIONS] ne "")
                        {
                            my @temp;
                            @temp = split / /,$arrayDir[$j][OPTIONS];
                            foreach(@temp)
                            {
                                if($_ eq "All")
                                {
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript | AccessSource | AccessWrite");
                                    last;
                                }
                                elsif($_ eq "Indexes")
                                {
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");                                    
                                }
                                elsif($_ eq "ExecCGI")
                                {
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript");
                                }
                            }                            
                        }
                        if($arrayDir[$j][DIRECTORYINDEX] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                        }
                        if($arrayDir[$j][AUTHNAME] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Realm", "$arrayDir[$j][AUTHNAME]");
                        }
                        if($arrayDir[$j][AUTHTYPE] ne "")
                        {
                            if($arrayDir[$j][AUTHTYPE] eq "Basic")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic");                                
                            }
                            elsif($arrayDir[$j][AUTHTYPE] eq "Digest")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthMD5");
                            }
                            elsif($arrayDir[$j][AUTHTYPE] eq "Basic|Digest")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                            }
                            elsif($arrayDir[$j][AUTHTYPE] eq "Digest|Basic")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                            }
                        }

                        if($arrayDir[$j][ERRORDOCUMENT] ne "")
                        {
                            my @temp = split / /,$arrayDir[$j][ERRORDOCUMENT];
                            my $k;
                            my $append;
                            my $string;
                            for($k=0; $k<=$#temp; $k = $k + 2)
                            {
                                if($temp[$k+1] =~ /^http:\/\//)
                                {
                                    $append = $append . $temp[$k] . ",*" . ",URL," . $temp[$k+1] ."\n";
                                }
                                
                                elsif($temp[$k+1] =~ /^"/)
                                {
                                    #Ignore it now, Not clear on the mapping to the config.xml : to be sorted out later
                                }
                                else
                                {
                                    if(index($temp[$k+1],$arrayDir[$j][DOCUMENTROOT]) == -1)
                                    {
                                        $string = $temp[$k+1];
                                        $string =~ s/\//\\/g;
                                        $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . $string ."\n";
                                        my $tmp;    
                                        my $tmp2;
                                        my $jk;
                                        my $fileName;
                                        my @splitAry = split /\//, $temp[$k+1];
                                        for($jk = 0; $jk < $#splitAry; $jk++)
                                        {
                                            $tmp = $tmp . $splitAry[$jk] . "/";
                                        }
                                        $fileName = $splitAry[$#splitAry];
                                        $tmp =~ s/\/$//;
                                        $tmp2 = $array[$i][DESTINATIONPATH] . $tmp;
                                        $tmp2 =~ s/\//\\/g;
                                        $errorDocumentCount++;
                                        $errorDocument[$errorDocumentCount] = "D" . TASKLIST_DELIM . $tmp . TASKLIST_DELIM .  $tmp2 . "\n";
                                        $errorDocumentCount++;
                                        $errorDocument[$errorDocumentCount] = "F" . TASKLIST_DELIM . $fileName . "\n";
                                    }
                                    else
                                    {
                                        $string = $temp[$k+1];
                                        $string =~ s/\//\\/g;
                                        $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . pars_getRelativePath($string,$array[$i][DOCUMENTROOT]) ."\n";
                                    }
                                }
                            }
                            chomp($append);
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpErrors", "$append");                            
                        }
                        
                        if($arrayDir[$j][EXPIRESACTIVE] ne "")
                        {
                            if($arrayDir[$j][EXPIRESACTIVE] eq  "on" || $arrayDir[$j][EXPIRESACTIVE] eq "On")   
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpExpires", "D, 0");
                            }
                        }

                        if($arrayDir[$j][HEADER] ne "")
                        {
                            my @headerArray = split /\|/ , $arrayDir[$j][HEADER];
                            my @intArray;
                            my $tmpArray;
                            my $tmpArray2;
                            foreach(@headerArray)
                            {                                
                                $_ =~ s/"//g;
                                @intArray = split / /,$_;
                                $tmpArray2 = "";
                                foreach (@intArray)
                                {
                                    next if($_ eq $intArray[0]);
                                    next if($_ eq $intArray[1]);
                                    $tmpArray2 = $tmpArray2 . $_ . " ";
                                }
                                $tmpArray2 =~ s/ $//;
                                $tmpArray = $tmpArray . $intArray[1] . ": " . $tmpArray2 . "\n";
                            }
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpCustomHeaders", $tmpArray);
                        }
                        if($arrayDir[$j][HOSTNAMELOOKUPS] ne "")
                        {                           
                            if($arrayDir[$j][HOSTNAMELOOKUPS] eq  "On" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "on")
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "TRUE");
                            }
                            elsif($arrayDir[$j][HOSTNAMELOOKUPS] eq  "Off" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "off")
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "FALSE");
                            }                            
                        }
                        if($arrayDir[$j][DESTINATIONPATH] ne "")
                        {                           
                            my $temp = $arrayDir[$j][DESTINATIONPATH];
                            $temp =~ s/\//\\/g;
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Path", $temp);
                        }                       
                    }
                }
                
                #for USERDIR setting to be migrated into XML.               
                if($arrayDir[$j][USERDIR] == 1)
                {
                    #append the IIsWebVirtualDir tag.       
                    $arrayDir[$j][DIRBITSET] = 1;
                    $arrayDir[$j][XML] = 1;
                    $iisXML->addNode("/Config/MBProperty/Vdir_$i$j");
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setTagName("IIsWebVirtualDir");
                    my @tem;
                    @tem = split /\//,$arrayDir[$j][DESTINATIONPATH];
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Location", "/LM/W3SVC/$i/ROOT/$tem[$#tem]");
                    if($arrayDir[$j][DIRECTORYINDEX] ne "")
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                    }
                    
                    if($arrayDir[$j][MAXCLIENTS] ne "")
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MaxConnections", "$arrayDir[$j][MAXCLIENTS]");
                    }
                    my @tempMime;
                    my $appendValue;
                    if($arrayDir[$j][ADDENCODING] ne "")
                    {
                        $arrayDir[$j][ADDENCODING] =~ s/\|$//;
                        @tempMime = split /\|/, $arrayDir[$j][ADDENCODING];
                        my $j;
                        foreach(@tempMime)
                        {   
                            my @temp;                            
                            chomp($_);
                            @temp = split /\s+/, $_;
                            for($j=1;$j<=$#temp;$j++)
                            {
                                $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                            }                            
                        }                        
                    }

                    if($arrayDir[$j][ADDTYPE] ne "")
                    {
                        @tempMime = split /|/, $arrayDir[$j][ADDTYPE];
                        my $j;
                        foreach(@tempMime)
                        {
                            my @temp;
                            
                            chomp($_);
                            @temp = split /\s+/, $_;
                            for($j=1;$j<=$#temp;$j++)
                            {
                                $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                            }                            
                        }
                    }

                    if($appendValue ne "")
                    {
                        $appendValue =~ s/ $//;
                        chomp($appendValue);
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MimeMap", $appendValue);
                    }
                    if($arrayDir[$j][DIRECTORYINDEX] ne "")
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                    }
                    if($arrayDir[$j][AUTHNAME] ne "")
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Realm", "$arrayDir[$j][AUTHNAME]");
                    }
                    if($arrayDir[$j][AUTHTYPE] ne "")
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "$arrayDir[$j][AUTHTYPE]");
                    }
                    
                    if($arrayDir[$j][ERRORDOCUMENT] ne "")
                    {
                        my @temp = split / /,$arrayDir[$j][ERRORDOCUMENT];
                        my $k;
                        my $append;
                        my $string;
                        for($k=0; $k<=$#temp; $k = $k + 2)
                        {
                            if($temp[$k+1] =~ /^http:\/\//)
                            {
                                $append = $append . $temp[$k] . ",*" . ",URL," . $temp[$k+1] ."\n";
                            }
                            
                            elsif($temp[$k+1] =~ /^"/)
                            {
                                #Ignore it now, Not clear on the mapping to the config.xml : to be sorted out later
                            }
                            else
                            {
                                if(index($temp[$k+1],$arrayDir[$j][DOCUMENTROOT]) == -1)
                                {
                                    $string = $temp[$k+1];
                                    $string =~ s/\//\\/g;
                                    $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . $string ."\n";
                                    my $tmp;    
                                    my $tmp2;
                                    my $jk;
                                    my $fileName;
                                    my @splitAry = split /\//, $temp[$k+1];
                                    for($jk = 0; $jk < $#splitAry; $jk++)
                                    {
                                        $tmp = $tmp . $splitAry[$jk] . "/";
                                    }
                                    $fileName = $splitAry[$#splitAry];
                                    $tmp =~ s/\/$//;
                                    $tmp2 = $array[$i][DESTINATIONPATH] . $tmp;
                                    $tmp2 =~ s/\//\\/g;
                                    $errorDocumentCount++;
                                    $errorDocument[$errorDocumentCount] = "D" . TASKLIST_DELIM . $tmp . TASKLIST_DELIM .  $tmp2 . "\n";
                                    $errorDocumentCount++;
                                    $errorDocument[$errorDocumentCount] = "F" . TASKLIST_DELIM . $fileName . "\n"; 
                                    
                                }
                                else
                                {
                                    $string = $temp[$k+1];
                                    $string =~ s/\//\\/g;
                                    $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . pars_getRelativePath($string,$array[$i][DOCUMENTROOT]) ."\n";
                                }
                            }
                        }

                        chomp($append);
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpErrors", "$append");
                        
                    }
                    
                    if($arrayDir[$j][EXPIRESACTIVE] ne "")
                    {
                        if($arrayDir[$j][EXPIRESACTIVE] eq  "on" || $arrayDir[$j][EXPIRESACTIVE] eq "On")   
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpExpires", "D, 0");
                        }
                    }
                    if($arrayDir[$j][HEADER] ne "")
                    {
                        my @headerArray = split /\|/ , $arrayDir[$j][HEADER];
                        my @intArray;
                        my $tmpArray;
                        my $tmpArray2;
                        foreach(@headerArray)
                        {
                            $_ =~ s/"//g;
                            @intArray = split / /,$_;
                            $tmpArray2 = "";
                            foreach (@intArray)
                            {
                                next if($_ eq $intArray[0]);
                                next if($_ eq $intArray[1]);
                                $tmpArray2 = $tmpArray2 . $_ . " ";
                            }
                            $tmpArray2 =~ s/ $//;
                            $tmpArray = $tmpArray . $intArray[1] . ": " . $tmpArray2 . "\n";
                        }
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpCustomHeaders", $tmpArray);
                    }
                    if($arrayDir[$j][HOSTNAMELOOKUPS] ne "")
                    {
                        
                        if($arrayDir[$j][HOSTNAMELOOKUPS] eq  "On" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "on")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "TRUE");
                        }
                        elsif($arrayDir[$j][HOSTNAMELOOKUPS] eq  "Off" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "off")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "FALSE");
                        }
                    }
                    if($arrayDir[$j][DESTINATIONPATH] ne "")
                    {
                        
                        my $temp = $arrayDir[$j][DESTINATIONPATH];
                        $temp =~ s/\//\\/g;
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Path", $temp);
                    }                    
                } 
            }
        }

        # Code added to take care of IIsWebDirectory
        for($j = 0; $j <= $rowDirCount; $j++)
        {
            if($arrayDir[$j][XML] != 1)
            {
                if($array[$i][SITENAME] eq $arrayDir[$j][SITENAME])
                {
                    my $temp;
                    if($arrayDir[$j][DIRECTORY] ne $array[$i][DOCUMENTROOT])
                    {
                        $temp = pars_getRelativePath($arrayDir[$j][DIRECTORY],$array[$i][DOCUMENTROOT]);
                        $iisXML->addNode("/Config/MBProperty/Vdir_$i$j");
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setTagName("IIsWebDirectory");
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Location", "/LM/W3SVC/$i/ROOT$temp");
                        if($arrayDir[$j][DIRECTORYINDEX] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                        }
                        
                        if($arrayDir[$j][MAXCLIENTS] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MaxConnections", "$arrayDir[$j][MAXCLIENTS]");
                        }
                        my @tempMime;
                        my $appendValue;
                        
                        if($arrayDir[$j][ADDENCODING] ne "")
                        {
                            $arrayDir[$j][ADDENCODING] =~ s/\|$//;
                            @tempMime = split /\|/, $arrayDir[$j][ADDENCODING];
                            my $j;
                            
                            foreach(@tempMime)
                            {   
                                my @temp;
                                
                                chomp($_);
                                @temp = split /\s+/, $_;
                                for($j=1;$j<=$#temp;$j++)
                                {
                                    $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                                }                                
                            }                            
                        }

                        if($arrayDir[$j][ADDTYPE] ne "")
                        {
                            $arrayDir[$j][ADDTYPE] =~ s/\|$//;
                            @tempMime = split /\|/, $arrayDir[$j][ADDTYPE];
                            my $j;
                            
                            foreach(@tempMime)
                            {   
                                my @temp;                                
                                chomp($_);
                                @temp = split /\s+/, $_;
                                for($j=1;$j<=$#temp;$j++)
                                {
                                    $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                                }
                            }
                        }
                        
                        if($appendValue !~ /\.\*/g)
                        {
                            $appendValue = $appendValue . ".*,text/plain\n";
                        }
                        if($appendValue ne "")
                        {
                            $appendValue =~ s/ $//;
                            chomp($appendValue);
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("MimeMap", $appendValue);
                        }
                        if($arrayDir[$j][OPTIONS] ne "")
                        {
                            my @temp;
                            @temp = split / /,$arrayDir[$j][OPTIONS];
                            foreach(@temp)
                            {
                                if($_ eq "All")
                                {
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript | AccessSource | AccessWrite");
                                    last;
                                }
                                elsif($_ eq "Indexes")
                                {
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");
                                    
                                }
                                elsif($_ eq "ExecCGI")
                                {
                                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript");
                                }
                            }
                        }
                        if($arrayDir[$j][DIRECTORYINDEX] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("DefaultDoc", "$arrayDir[$j][DIRECTORYINDEX]");
                        }
                        if($arrayDir[$j][AUTHNAME] ne "")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("Realm", "$arrayDir[$j][AUTHNAME]");
                        }
                        if($arrayDir[$j][AUTHTYPE] ne "")
                        {
                            if($arrayDir[$j][AUTHTYPE] eq "Basic")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic");                                
                            }
                            elsif($arrayDir[$j][AUTHTYPE] eq "Digest")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthMD5");
                            }
                            elsif($arrayDir[$j][AUTHTYPE] eq "Basic|Digest")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                            }
                            elsif($arrayDir[$j][AUTHTYPE] eq "Digest|Basic")
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                            }
                        }
                        
                        if($arrayDir[$j][ERRORDOCUMENT] ne "")
                        {
                            my @temp = split / /,$arrayDir[$j][ERRORDOCUMENT];
                            my $k;
                            my $append;
                            my $string;
                            for($k=0; $k<=$#temp; $k = $k + 2)
                            {
                                if($temp[$k+1] =~ /^http:\/\//)
                                {
                                    $append = $append . $temp[$k] . ",*" . ",URL," . $temp[$k+1] ."\n";
                                }
                                
                                elsif($temp[$k+1] =~ /^"/)
                                {
                                    #Ignore it now, Not clear on the mapping to the config.xml : to be sorted out later
                                }
                                else
                                {
                                    if(index($temp[$k+1],$arrayDir[$j][DOCUMENTROOT]) == -1)
                                    {
                                        $string = $temp[$k+1];
                                        $string =~ s/\//\\/g;
                                        $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . $string ."\n";
                                        my $tmp;    
                                        my $tmp2;
                                        my $jk;
                                        my $fileName;
                                        my @splitAry = split /\//, $temp[$k+1];
                                        for($jk = 0; $jk < $#splitAry; $jk++)
                                        {
                                            $tmp = $tmp . $splitAry[$jk] . "/";
                                        }
                                        $fileName = $splitAry[$#splitAry];
                                        $tmp =~ s/\/$//;
                                        $tmp2 = $array[$i][DESTINATIONPATH] . $tmp;
                                        $tmp2 =~ s/\//\\/g;
                                        $errorDocumentCount++;
                                        $errorDocument[$errorDocumentCount] = "D" . TASKLIST_DELIM . $tmp . TASKLIST_DELIM .  $tmp2 . "\n";
                                        $errorDocumentCount++;
                                        $errorDocument[$errorDocumentCount] = "F" . TASKLIST_DELIM . $fileName . "\n";
                                    }
                                    else
                                    {
                                        $string = $temp[$k+1];
                                        $string =~ s/\//\\/g;
                                        $append = $append . $temp[$k] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . pars_getRelativePath($string,$array[$i][DOCUMENTROOT]) ."\n";
                                    }
                                }
                            }

                            chomp($append);
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpErrors", "$append");
                        }
                        
                        if($arrayDir[$j][EXPIRESACTIVE] ne "")
                        {
                            if($arrayDir[$j][EXPIRESACTIVE] eq  "on" || $arrayDir[$j][EXPIRESACTIVE] eq "On")   
                            {                                
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpExpires", "D, 0");
                            }
                        }
                        if($arrayDir[$j][HEADER] ne "")
                        {
                            my @headerArray = split /\|/ , $arrayDir[$j][HEADER];
                            my @intArray;
                            my $tmpArray;
                            my $tmpArray2;
                            foreach(@headerArray)
                            {                                
                                $_ =~ s/"//g;
                                @intArray = split / /,$_;
                                $tmpArray2 = "";
                                foreach (@intArray)
                                {
                                    next if($_ eq $intArray[0]);
                                    next if($_ eq $intArray[1]);
                                    $tmpArray2 = $tmpArray2 . $_ . " ";
                                }
                                $tmpArray2 =~ s/ $//;
                                $tmpArray = $tmpArray . $intArray[1] . ": " . $tmpArray2 . "\n";
                            }
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("HttpCustomHeaders", $tmpArray);
                        }
                        if($arrayDir[$j][HOSTNAMELOOKUPS] ne "")
                        {
                            if($arrayDir[$j][HOSTNAMELOOKUPS] eq  "On" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "on")
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "TRUE");
                            }
                            elsif($arrayDir[$j][HOSTNAMELOOKUPS] eq  "Off" || $arrayDir[$j][HOSTNAMELOOKUPS] eq  "off")
                            {
                                $iisXML->getNode("/Config/MBProperty/Vdir_$i$j")->setAttrib("EnableReverseDns", "FALSE");
                            }                            
                        }
                    }                    
                }                
            }
        }

        # Code added to take care of IIsWebFile
        my $l = 0;
        my $k = 0;
        $k = $rowDirCount;
        ++$k;
        for($l = 0; $l <= $filecount; $l++)
        {
            if($array[$i][SITENAME] eq $files[$l][SITENAME])
            {
                my $temp;
                if(index($files[$l][DIRECTORY],$files[$l][DOCUMENTROOT]) != 0)  
                {
                    
                    $temp = $files[$l][DIRECTORY];
                    $temp = $temp . "/" . $files[$l][FILESMATCH];
                }
                else
                {                    
                    $temp = pars_getRelativePath($files[$l][DIRECTORY],$files[$l][DOCUMENTROOT]);
                    $temp = $temp . "/" . $files[$l][FILESMATCH];
                }
                
                $iisXML->addNode("/Config/MBProperty/Vdir_$i$k");
                $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setTagName("IIsWebFile");
                $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("Location", "/LM/W3SVC/$i/ROOT$temp");
                if($files[$l][OPTIONS] ne "")
                {
                    my @temp;
                    @temp = split / /,$files[$l][OPTIONS];
                    foreach(@temp)
                    {
                        if($_ eq "All")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript | AccessSource | AccessWrite");
                            last;
                        }
                        elsif($_ eq "Indexes")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("DirBrowseFlags","EnableDirBrowsing | EnableDefaultDoc");                            
                        }
                        elsif($_ eq "ExecCGI")
                        {
                            $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript");
                        }
                    }
                }

                my @tempMime;
                my $appendValue;
                if($files[$l][ADDENCODING] ne "")
                {
                    $files[$l][ADDENCODING] =~ s/\|$//;
                    @tempMime = split /\|/, $files[$l][ADDENCODING];
                    
                    my $j;
                    my $placeHolder;
                    
                    foreach $placeHolder (@tempMime)
                    {
                        my @temp;                        
                        chomp($placeHolder);
                        @temp = split /\s+/,$placeHolder;
                        for($j=1;$j<=$#temp;$j++)
                        {
                            $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                        }                        
                    }
                }
                
                if($files[$l][ADDTYPE] ne "")
                {
                    $files[$l][ADDTYPE] =~ s/\|$//;
                    @tempMime = split /\|/, $files[$l][ADDTYPE];
                    my $j;
                    
                    foreach(@tempMime)
                    {
                        my @temp;                        
                        chomp($_);
                        @temp = split /\s+/, $_;
                        for($j=1;$j<=$#temp;$j++)
                        {
                            $appendValue = $appendValue . $temp[$j] . "," . $temp[0] ."\n"; 
                        }
                    }
                }

                if($appendValue !~ /\.\*/g)
                {
                    $appendValue = $appendValue . ".*,text/plain\n";
                    
                }
                if($appendValue ne "")
                {
                    $appendValue =~ s/ $//;
                    chomp($appendValue);
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("MimeMap", $appendValue);
                }
                if($files[$l][EXPIRESACTIVE] ne "")
                {
                    if($files[$l][EXPIRESACTIVE] eq  "on" || $files[$l][EXPIRESACTIVE] eq "On") 
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("HttpExpires", "D, 0");
                    }
                }
                if($files[$l][AUTHNAME] ne "")
                {
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("Realm", "$files[$l][AUTHNAME]");
                }
                if($files[$l][AUTHTYPE] ne "")
                {
                    if($files[$l][AUTHTYPE] eq "Basic")
                    {   
                        
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("AuthFlags", "AuthBasic");
                        
                    }
                    elsif($files[$l][AUTHTYPE] eq "Digest")
                    {
                        
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("AuthFlags", "AuthMD5");
                    }
                    elsif($files[$l][AUTHTYPE] eq "Basic|Digest")
                    {
                        
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                    }
                    elsif($files[$l][AUTHTYPE] eq "Digest|Basic")
                    {
                        
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("AuthFlags", "AuthBasic|AuthMD5");
                    }
                }

                if($files[$l][ERRORDOCUMENT] ne "")
                {                   
                    my @temp = split / /,$files[$l][ERRORDOCUMENT];
                    my $kk;
                    my $append;
                    my $string;
                    for($kk=0; $kk<=$#temp; $kk = $kk + 2)
                    {
                        if($temp[$kk+1] =~ /^http:\/\//)
                        {
                            $append = $append . $temp[$kk] . ",*" . ",URL," . $temp[$kk+1] ."\n";
                        }
                        elsif($temp[$kk+1] =~ /^"/)
                        {
                            #NO equivalent mapping found on IIS.
                        }
                        else
                        {                            
                            if(index($temp[$kk+1],$files[$l][DOCUMENTROOT]) == -1)
                            {
                                $string = $temp[$kk+1];
                                $string =~ s/\//\\/g;
                                $append = $append . $temp[$kk] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . $string ."\n";
                                my $tmp;    
                                my $tmp2;
                                my $jk;
                                my $fileName;
                                my @splitAry = split /\//, $temp[$kk+1];
                                for($jk = 0; $jk < $#splitAry; $jk++)
                                {
                                    $tmp = $tmp . $splitAry[$jk] . "/";
                                }
                                $fileName = $splitAry[$#splitAry];
                                $tmp =~ s/\/$//;
                                $tmp2 = $array[$i][DESTINATIONPATH] . $tmp;
                                $tmp2 =~ s/\//\\/g;
                                $errorDocumentCount++;
                                $errorDocument[$errorDocumentCount] = "D" . TASKLIST_DELIM . $tmp . TASKLIST_DELIM .  $tmp2 . "\n";
                                $errorDocumentCount++;
                                $errorDocument[$errorDocumentCount] = "F" . TASKLIST_DELIM . $fileName . "\n";                                 
                            }
                            else
                            {                                
                                $string = $temp[$kk+1];
                                $string =~ s/\//\\/g;
                                $append = $append . $temp[$kk] . ",*" . ",FILE," .  $array[$i][DESTINATIONPATH] . pars_getRelativePath($string,$array[$i][DOCUMENTROOT]) ."\n";
                            }                            
                        }                        
                    }

                    chomp($append);
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("HttpErrors", "$append");                    
                }

                if($files[$l][HEADER] ne "")
                {
                    my @headerArray = split /\|/ , $files[$l][HEADER];
                    my @intArray;
                    my $tmpArray;
                    my $tmpArray2;
                    foreach(@headerArray)
                    {                        
                        $_ =~ s/"//g;
                        @intArray = split / /,$_;
                        $tmpArray2 = "";
                        foreach (@intArray)
                        {
                            next if($_ eq $intArray[0]);
                            next if($_ eq $intArray[1]);
                            $tmpArray2 = $tmpArray2 . $_ . " ";
                        }
                        $tmpArray2 =~ s/ $//;
                        $tmpArray = $tmpArray . $intArray[1] . ": " . $tmpArray2 . "\n";
                    }

                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("HttpCustomHeaders", $tmpArray);
                }
                if($files[$l][EXPIRESACTIVE] ne "")
                {
                    if($files[$l][EXPIRESACTIVE] eq  "on" || $files[$l][EXPIRESACTIVE] eq "On") 
                    {
                        $iisXML->getNode("/Config/MBProperty/Vdir_$i$k")->setAttrib("HttpExpires", "D, 0");
                    }
                }
                
                ++$k;
            }
        }

        my $indexI;
        my $IndL = $k;
        ++$IndL;
        for($indexI = 0; $indexI <= $aliasDirInd;$indexI++)     
        {
            if($aliasDir[$indexI][0] eq $array[$i][SITENAME])
            {
                if($aliasDir[$indexI][2] == 1)
                {
                    ++$rowDirCount;
                    if(index($aliasDir[$indexI][1],$array[$i][DOCUMENTROOT]) != 0)  
                    {
                        $arrayDir[$rowDirCount][TASKLIST]  = 1;
                        $arrayDir[$rowDirCount][DESTINATIONPATH] = $array[$i][DESTINATIONPATH] . $aliasDir[$indexI][DIRECTORY]; 
                    }
                    else
                    {
                        my $temp;
                        $temp = pars_getRelativePath($aliasDir[$indexI][DIRECTORY],$array[$i][DOCUMENTROOT]);
                        $arrayDir[$rowDirCount][DESTINATIONPATH] = $array[$i][DESTINATIONPATH] . $temp;
                    }
                    
                    $arrayDir[$rowDirCount][SITENAME] = $array[$i][SITENAME];
                    $arrayDir[$rowDirCount][DIRECTORY] = $aliasDir[$indexI][1];
                    $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "Off";
                    $arrayDir[$rowDirCount][IDENTITYCHECK] = "Off";
                    $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
                    $arrayDir[$rowDirCount][ACCESSFILENAME] = $array[$i][ACCESSFILENAME];
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\\/\//g;
                    $arrayDir[$rowDirCount][DOCUMENTROOT] = $array[$i][DOCUMENTROOT];
                    $arrayDir[$rowDirCount][DEFAULTTYPE] = "text/plain";
                    $iisXML->addNode("/Config/MBProperty/Vdir_$i$IndL");
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$IndL")->setTagName("IIsWebVirtualDir");
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$IndL")->setAttrib("Location", "/LM/W3SVC/$i/ROOT$aliasDir[$indexI][3]");
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\//\\/g;
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\/$//;
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$IndL")->setAttrib("Path",$arrayDir[$rowDirCount][DESTINATIONPATH]);
                    $IndL++;                    
                }       
            }
        }

        for($indexI = 0; $indexI <= $scriptaliasDirInd;$indexI++)       
        {
            if($scriptaliasDir[$indexI][0] eq $array[$i][SITENAME])
            {
                if($scriptaliasDir[$indexI][2] == 1)
                {
                    ++$rowDirCount;
                    if(index($scriptaliasDir[$indexI][1],$array[$i][DOCUMENTROOT]) != 0)    
                    {
                        $arrayDir[$rowDirCount][TASKLIST]  = 1;
                        $arrayDir[$rowDirCount][DESTINATIONPATH] = $array[$i][DESTINATIONPATH] . $scriptaliasDir[$indexI][DIRECTORY]; 
                    }
                    else
                    {
                        my $temp;
                        $temp = pars_getRelativePath($scriptaliasDir[$indexI][DIRECTORY],$array[$i][DOCUMENTROOT]);
                        $arrayDir[$rowDirCount][DESTINATIONPATH] = $array[$i][DESTINATIONPATH] . $temp;                         
                    }
                    
                    $arrayDir[$rowDirCount][SITENAME] = $array[$i][SITENAME];
                    $arrayDir[$rowDirCount][DIRECTORY] = $scriptaliasDir[$indexI][1];                   
                    $arrayDir[$rowDirCount][HOSTNAMELOOKUPS] = "Off";
                    $arrayDir[$rowDirCount][IDENTITYCHECK] = "Off";
                    $arrayDir[$rowDirCount][ALLOWOVERRIDE] = "All";
                    $arrayDir[$rowDirCount][ACCESSFILENAME] = $array[$i][ACCESSFILENAME];
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\\/\//g;
                    $arrayDir[$rowDirCount][DOCUMENTROOT] = $array[$i][DOCUMENTROOT];
                    $arrayDir[$rowDirCount][DEFAULTTYPE] = "text/plain";                    
                    $iisXML->addNode("/Config/MBProperty/Vdir_$i$IndL");
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$IndL")->setTagName("IIsWebVirtualDir");
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$IndL")->setAttrib("Location", "/LM/W3SVC/$i/ROOT$scriptaliasDir[$indexI][3]");
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$IndL")->setAttrib("AccessFlags", "AccessExecute | AccessRead | AccessScript");
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\//\\/g;
                    $arrayDir[$rowDirCount][DESTINATIONPATH] =~ s/\/$//;
                    $iisXML->getNode("/Config/MBProperty/Vdir_$i$IndL")->setAttrib("Path",$arrayDir[$rowDirCount][DESTINATIONPATH]);
                    $IndL++;                    
                }       
            }
        }
    }

    my $path = &pars_GetSessionFolder() . AMW . &ilog_getSessionName() . FILE_IISCONFIG;
    $iisXML->saveAs("$path");
    eval
    {        
        close SITES or die 'ERR_FILE_CLOSE';
    };
    if($@)
    {
        if($@=~/ERR_FILE_CLOSE/)
        {
            # log 'file close error' and continue
            ilog_setLogInformation('INT_ERROR',$sites,ERR_FILE_CLOSE,__LINE__);            
        }        
    }
    else
    {
        ilog_setLogInformation('INT_INFO',$sites,MSG_FILE_CLOSE,'');
    }
}

#######################################################################################################################
#
# Method Name   : pars_getRelativePath
#
# Description   : To get the relative path
#
# Input         : None
#
# OutPut        : None
#
# Status        : None
# 
#######################################################################################################################
sub pars_getRelativePath
{
    my ($FullPath,$RootPath) = @_;
    return substr($FullPath,length($RootPath),length($FullPath));
}

#######################################################################################################################
#
# Method Name   : pars_ReadServerBindings
#
# Description   : Reads the Recovery File and Populates the ServerBindings Hash
#
# Input         : Recovery File Path
#
# OutPut        : None
#######################################################################################################################
sub pars_ReadServerBindings
{
    my $strRecFilePath = shift;    
    my $retVal;                     # Common return value holder    
    my $LineContent;                # Current Line
    my @Columns;                    # Column Split up 
    my @Sites;                      # List of Sites
    my $Site;                       # Current Site    
    my @Ports;                      # List of Listening Ports
    my $Port;                       # Current Port    
    my @DefaultIPs;                 # List of Listening Ports
    my %SiteIPs;                    # List of Sites and their IPs
    my $SiteIP;                     # IPs of Current Site    
    my %HostHeaders;                # List of Host Headers for each site
    my $HostHeader;                 # Host Header of Current Site
    my $NotASite;                   # Is Current Tag a site    
    # Open Recovery File for Processing
    $retVal = open(FSERVERBIND, $strRecFilePath);
    if (!$retVal)
    {
        print "Unable to open recovery file";
        return 0;
    }
    
    # Read Recovery File Sequentially
    while($LineContent = <FSERVERBIND>)
    {
        $NotASite = 0;
        #******************************************
        #   Process Port Information ...
        #******************************************
        
        if ($LineContent =~ /^\[LISTEN\]/ )
        {
            $NotASite = 1;
            while($LineContent = <FSERVERBIND>)
            {
                next if ($LineContent !~ /\w/);
                last if ($LineContent =~ /^\[.+\]/ );                
                chomp($LineContent);                
                @Columns = split /=/ , $LineContent;                
                if ($Columns[1] =~ /\./)
                {
                    push(@DefaultIPs,$Columns[1]);
                }    
                else
                {
                    push(@Ports,$Columns[1]);
                }
            }
        }
        
        #******************************************
        #   Process IP Information ...
        #******************************************
        if ($LineContent =~ /^\[IP_INFORMATION\]/ )
        {
            $NotASite = 1;
            while($LineContent = <FSERVERBIND>)
            {
                next if ($LineContent !~ /\w/);
                last if ($LineContent =~ /^\[.+\]/ );                
                chomp($LineContent);                
                @Columns = split /\|/ , $LineContent;                
                @Sites = split /,/ , $Columns[0];                
                foreach $Site (@Sites)
                {
                    $SiteIPs{$Site} .=  $SiteIPs{$Site} ? ",".$Columns[2] :$Columns[2];
                }
            }
        }

        #******************************************
        #   Process NameVirtualHost Information ...
        #******************************************
        
        if ($LineContent =~ /^\[NAME_VIRTUAL_HOST\]/ )
        {
            $NotASite = 1;
            while($LineContent = <FSERVERBIND>)
            {
                next if ($LineContent !~ /\w/);
                last if ($LineContent =~ /^\[.+\]/ );                
                chomp($LineContent);                
                @Columns = split / / , $LineContent;                
                $HostHeaders{$Columns[0]} = $LineContent;
            }
        }

        $NotASite = 1 if ($LineContent =~ /^\[USER_DIR\]/ );
        #******************************************
        #   Enumerate Sites ...
        #******************************************
        
        if (!$NotASite)
        {
            if ($LineContent =~ /^\[.+\]/ )
            {
                chomp($LineContent);            
                $LineContent =~ s /\[//g;
                $LineContent =~ s /\]//g;
                $ServerBinding{$LineContent} = "";
            }
        }
    }

    #***********************************************
    #   Assemble ServerBinding string 
    #***********************************************
    if (scalar(@Ports) <= 0)
    {
        push(@Ports,"80");
    }
    else
    {
        push(@DefaultIPs,"");
    }
    
    foreach $Site (keys %ServerBinding)   
    {
        if (exists($SiteIPs{$Site}))
        {
            @Columns = split /,/ , $SiteIPs{$Site};
        }
        else
        {
            if (scalar(@DefaultIPs) <= 0)
            {
                @Columns = ("");           
            }
            else
            {
                @Columns = @DefaultIPs;           
            } 
        }
        
        foreach $SiteIP (@Columns)
        { 
            # Convert "*" to blank
            $SiteIP =~ s/\*//;
            #******************************************************
            #   If IP is specified with Port then add host headers 
            #******************************************************
            if ($SiteIP =~ /:/)
            {
                if (exists($HostHeaders{$Site}))
                {
                    foreach $HostHeader (split(/ /,$HostHeaders{$Site}))
                    {
                        $ServerBinding{$Site} .= "$SiteIP:$HostHeader \n";
                    }
                }
                else
                {
                    $ServerBinding{$Site} .= "$SiteIP: \n";
                }
                next;
            }
            #******************************************************
            #   Otherwise repeat for every Port its listening 
            #******************************************************            
            # For Every Port
            foreach $Port (@Ports)
            {
                
                if ($Port =~ /:/)
                {
                    if ($SiteIP eq "") 
                    {
                        $ServerBinding{$Site} .= "$Port:$HostHeader \n";
                    }
                    next;
                }
                
                # For Every HostHeader                
                if (exists($HostHeaders{$Site}))
                {
                    foreach $HostHeader (split(/ /,$HostHeaders{$Site}))
                    {
                        $ServerBinding{$Site} .= "$SiteIP:$Port:$HostHeader \n";
                    }
                }
                else
                {
                    $ServerBinding{$Site} .= "$SiteIP:$Port: \n";
                }
            }
        }
    }
}

sub pars_GetSiteBinding
{
    return $ServerBinding{$_};
}

sub pars_FileNameSet
{
    my $strng = shift;
    chomp($strng);
    my @str;
    @str = split /\s+/,$strng;
    my $i=0; 
    my $ret;    
    foreach(@str)
    {
        $i++;
        if($i > 8)
        {
            $ret = $ret . $_ . " ";
        }
    }

    chomp($ret);
    $ret =~ s/ $//;
    return $ret;
}

#######################################################################################################################
#
# Method Name   : pars_GetMimeTypes
#
# Description   : The method is used to migrate the mime-types by parsing the file 
#                 specified by TypesConfig directive. 
#
# Input         : ftp path of mime-types file
#
# Return        : ( True, IIS style Mime-Map) on success
#                 ( False, "") on failure;   
#######################################################################################################################
sub pars_GetMimeTypes
{
    my $strMimeFile = shift;
    my $currentLine;
    my @Content;
    my $mimeType;
    my $FileExt;
    my $mimeMap;
    my $ret;
    my $localFile;    
    $mimeMap = "";
    $localFile = &pars_GetSessionFolder().MIME_TYPES_FILE;
    $ret = pars_GetFileFromSource($strMimeFile,$localFile);
    if (!$ret)
    {
        #ERROR : in write file
        $ret = ilog_displayandLog(ERR_CRITICAL . ERR_OPENING_MIME_FILE . " [$strMimeFile] ","","EXT_ERROR",ERR_CRITICAL . ERR_OPENING_MIME_FILE . " [$strMimeFile] ","", __LINE__);
        if(!$ret)
        {   
            $ret=ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
        }

        return ($ret,"");   
    }
    
    $ret = open(MIMEFILE,$localFile);
    if (!$ret)
    {
        #ERROR : in write file
        $ret = ilog_displayandLog(ERR_CRITICAL . ERR_OPENING_MIME_FILE . " [$localFile] ","","EXT_ERROR",ERR_CRITICAL . ERR_OPENING_MIME_FILE . " [$localFile] ","", __LINE__);
        if(!$ret)
        {   
            $ret=ilog_print(1,ERR_INTERNAL_ERROR_CONSOLE.__LINE__);
        }

        return ($ret,"");   
    } 
    
    &utf_DeleteOnExit($localFile);
    
    while($currentLine = <MIMEFILE>)
    {
        chomp($currentLine);
        $currentLine =~ s/^[\s\t\n]+//;     # ltrim        
        next if (!$currentLine);            # ignore blanks       
        next if ($currentLine =~ /^\#/);    # ignore comments       
        $currentLine =~ s/[\s\t]+/ /;       # tighten string
        @Content = split /\s/,$currentLine;        
        $mimeType = shift(@Content);
        foreach $FileExt (@Content)
        {
            $mimeMap .= ".$FileExt,$mimeType\n\t\t\t";
        }
    }
    
    return (1,$mimeMap);
}

sub pars_ValidateAliasName
{   
    my $aliasName = shift;
    my $specialChar = "[\\:*?<>|]";
    if($aliasName !~ /$specialChar/)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}
#######################################################################################################################
1;
