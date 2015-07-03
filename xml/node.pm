package xml::node;

use strict;
use xml::attrib;

sub new 
{
    shift; # ignore invocant
    bless { @_, attrib => xml::attrib::->new };
}


sub setTagName 
{
    my ($this,$tag) = @_;
    $this->{tagName} = $tag;
}

sub getTagName 
{
    my $this = shift;
    $this->{tagName};
}

sub setContent 
{
    my ($this,$content) = @_;
    $this->{content} .= $content;
}

sub getContent 
{
    my $this = shift;
    $this->{content};
}

sub setAttrib
{
    my ($this,$attrib,$value) = @_;
    $this->{attrib}->setAttrib($attrib,$value);    
}

sub getAttrib
{
    my ($this,$attrib) = @_;
    return $this->{attrib}->getAttrib($attrib);    
}

sub getData
{
    my $this = shift;
    return "\n<".$this->{tagName}.$this->{attrib}->getData()."\n\t>\n\t".$this->{content}."\n</".$this->{tagName}.">\n";
}

1;