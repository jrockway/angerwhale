#!/usr/bin/perl
# Wiki.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Blog::Format::Wiki;
use strict;
use warnings;
use Text::WikiFormat;

sub new {
    my $class = shift;
    my $self  = \my $scalar;
    bless $self, $class;
}

sub can_format {
    my $self    = shift;
    my $request = shift;
    
    return 100 if $request eq 'wiki';
    return 10; # catch-all
}

sub types {
    my $self = shift;
    return 
      ({type        => 'wiki', 
       description => 'Text::WikiFormat formatted text'});
}

sub format {
    my $self = shift;
    my $text = shift;
    my $type = shift;
    
    $text =~ s/&/&amp;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/</&lt;/g;
    
    return Text::WikiFormat::format($text);
}

1;

__END__

