package xml::doc;

use strict;
use xml::node;

sub new 
{
    shift; # ignore invocant
    bless { @_ };
}

sub addNode
{
   my ($this,$location) = @_;
   $this->{$location."/"} = xml::node::->new;
}

sub getNode
{
   my ($this,$location) = @_;
   return $this->{$location."/"};
}

sub getData
{
    my $this = shift;
    my @nodes = sort(keys %$this);
    my $prev = "/";
    my @stack;
    my $popVal; 
      
    push @stack, $prev;                         # Stack-Bottom Marker...
    foreach my $location (@nodes)
    {
        if (index($location,$prev,0) == 0)      #*****************************
        {                                       # Keep  Pushing the nodes into
            push @stack, $location;             # the stack if they are childs
            #print "\n{@stack}\n";               #*****************************
        }
        else
        {
           while(index($location,peek(@stack),0) != 0)
           {                                        #*************************
                $popVal= pop(@stack);               # Else Pop out and process 
                #print "\n{@stack}\n";               # child  nodes from stack.
                $this->link(peek(@stack),$popVal);  #*************************

           }                                    
           push @stack, $location;              
           #print "\n{@stack}\n";                      
        }
        $prev = $location;        
    }

    # unwind all
    while(peek(@stack) ne "/")                  #***************************** 
    {                                           # Process all left out child  
        $popVal= pop(@stack);                   # nodes from the stack ...
        #print "\n{@stack}\n";                   #*****************************
        $this->link(peek(@stack),$popVal);
    }
    return $this->{$popVal}->getData();
}

sub saveAs
{
    my ($this,$path) = @_;
    my $ret = open XMLFILE, ">$path";
	return 0 if ($ret == 0);	
    print XMLFILE $this->getData();
	close XMLFILE;
    return 1;
}

# return the top most item of a stack (without poping)
sub peek            
{
    my @stack = @_;
    return $stack[$#stack];
}

# links parent and child nodes
sub link
{
    my ($this,$parent,$child) = @_;

    return if ($parent eq "/");
    
    #print "\nLinking <$parent> to <$child>";
    $this->{$parent}->setContent($this->{$child}->getData());
}

1;