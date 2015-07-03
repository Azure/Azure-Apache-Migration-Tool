#-------------------------------------------------------------------------------
#Method Name        :        main_getCurrentLibFolder
#Description        :        gets the current working folder						 
#Input              :        NA
#Output             :        NA
#Return				:		 returns the current working folder
#-------------------------------------------------------------------------------
use Cwd;
use wsmk_constants;		 
sub main_getCurrentLibFolder                                                  
{                                                                             
    my		$libFolder = cwd;                                             
    my 		$filename;	
    if($^O eq WINDOWS)                                                  
    {        
        
        $fileName = "./".FILE_PERLPRESENT;
        eval{open(FH,"<$fileName") or die ERR_FILE_OPEN;};
        if($@ =~ ERR_FILE_OPEN)
        { 
            system('cls');
            print "For correct operation of the Kit, it needs to be run from WSMK.BAT file\n";
            exit;
        }

        $libFolder =~ tr/\//\\/;         #change the current directory
        $libFolder  = $libFolder."\\lib\\";        
    }                                                                     
    else
    {         
        $libFolder  = $libFolder."\/lib\/";                           
    }                                                                     
}

#-------------------------------------------------------------------------------
#Method Name        :        main_validatePerlVersion
#Description        :        determines and validates the PERL Version						 
#Input              :        NA
#Output             :        NA
#Return				:		 returns the version number
#-------------------------------------------------------------------------------
sub main_validatePerlVersion
{
	my $perlVersion;
	$perlVersion = $];
	#get the current PERL version
	if($perlVersion =~ /5/)
	{
		if($perlVersion =~ /6/)
		{return 1;}
		else
		{
			main_dispIncorrectPerl();
			return 0;
		}
	}
    else
    {
        main_dispIncorrectPerl();
        return 0;
    }	
}

#-------------------------------------------------------------------------------
#Method Name        :        main_dispIncorrectPerl
#Description        :        display Error message - incorrect PERL version
#Input              :        NA
#Output             :        NA
#-------------------------------------------------------------------------------
sub main_dispIncorrectPerl
{
    if($^O eq WINDOWS)                                                  
    {        
        system('cls');
        print ERR_INCORRECT_PERL_VERSION;
    }
    else
    {
        system("clear");
        print ERR_INCORRECT_PERL_VERSION;
    }
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	wrk_changeLocalDir
#Description	: 	Method to change the current working directory
#Input			:	1. $Path = Path to set the current working directory to
#Output			:	
#Return Value   :	boolean	0 : If Path not present/Cannot access
#					boolean 1 : If Path valid
#-----------------------------------------------------------------------------------------------
sub wrk_changeLocalDir
{
	my $directoryPath;								#Directory path to be changed to
	my $retchdir;									#Return value of chdir
	$directoryPath = shift;
	$retchdir = chdir $directoryPath;
	($retchdir == 0) ? return 0:return 1;
}
1;
