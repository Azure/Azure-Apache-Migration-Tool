package xml::attrib;

use strict;

sub new 
{
    shift; # ignore invocant
    bless { @_ };
}

sub setAttrib
{
    my ($this,$attrib,$value) = @_;
    $this->{$attrib} = $value;    
}

sub getAttrib 
{
    my ($this,$attrib) = shift;
    return $this->{$attrib};
}

sub getData
{
    my $this = shift;
	my $key;
	my $retVal = "";
    foreach $key (keys %$this)
    {
        $retVal = $retVal."\n\t".$key." = \"".$this->{$key}."\"";
    }  
    return $retVal;
}

1;