#----------------------------------------------------------------------------------------------
#Script Name 		:	aamt_userInterface.pm
#Description	    : 	Package is used to define methods used for User Interface
use strict;
use aamt_constants;

#-----------------------------------------------------------------------------------------------
#Method Name	:	ui_printLine
#Description	: 	Used to print a line on the UI with variable length
#Input			:	1.	width of the line
#Output			:	
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ui_printline
{
    my $linewidth = shift;
    if($linewidth eq "")
    {
        $linewidth = DEFAULTWIDTH - 1;
    }
    
    print "-" x $linewidth;
    print "\n";
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ui_Title
#Description	: 	Used to print the title on the UI
#Input			:	 
#Output			:	
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ui_Title
{
	ui_printline();
	print TITLE1;
	print TITLE2;
	ui_printline();
	print TITLE3;
	ui_printline();
	print "Press Enter key to continue ...";
    <>;	
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ui_clearScreen
#Description	: 	Used to clear screen 
#Input			:
#Output			:	
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ui_clearScreen
{
    my $OSType = $^O;
    if($OSType eq WINDOWS)
    {
        ui_clearScreenWindows();
    }
    elsif($OSType eq LINUX)
    {
        ui_clearScreenLinux();
    }
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ui_clearScreenWindows
#Description	: 	Used to clear screen on a Windows box
#Input			:	
#Output			:	
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ui_clearScreenWindows
{
	# clear screen on windows
	system ('cls');
}

#-----------------------------------------------------------------------------------------------
#Method Name	:	ui_clearScreenLinux
#Description	: 	Used to clear screen on a Linux box
#Input			:	
#Output			:	
#Return Value   :	boolean	
#-----------------------------------------------------------------------------------------------
sub ui_clearScreenLinux
{
	system("clear");
}

sub ui_printBanner
{
    my $strBanner = shift;
    
    ui_clearScreen();
    ui_printline();
	print TITLE1;
	print TITLE2;
	ui_printline();
    
    if ($strBanner)
    {
        print "\n\n";
        ui_printline();
	    print $strBanner;
	    ui_printline();
    }
}   
1;
