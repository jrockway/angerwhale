#!/usr/bin/perl
# OpenOffice.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Format::OpenOffice;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self  = \my $scalar;
    bless $self, $class;
}

sub can_format {
    my $self    = shift;
    my $request = shift;

    return 100 if($request =~ /sxw/);
}

sub types {
    my $self = shift;
    return 
      ({type       => 'sxw', 
       description => 'OpenOffice.org Writer Document'});
    
}

sub format {
    die "Broken.";
}

sub format_text {
    die "No.";
}

1;
