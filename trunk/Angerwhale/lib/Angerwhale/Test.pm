#!/usr/bin/perl
# Test.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Test;
use strict;
use warnings;
use Directory::Scratch;

=head1 NAME

Angerwhale::Test - Test Angerwhale

=head1 METHODS

Subclasses Test::WWW::Mechanize::Catalyst.

=head2 import

Import the module, setup config, create tmp basedir.

=head2 tmp

Return Directory::Scratch object representing temp dir.

=cut

my $tmp;
sub import {
    my $class = shift;
    my %config = @_;
    
    $tmp = Directory::Scratch->new;
    $ENV{"ANGERWHALE_base"} = $tmp->base;
    foreach my $key (keys %config){
        $ENV{"ANGERWHALE_$key"} = $config{$key};
    }
    return $class;
}

sub new {
    require Test::WWW::Mechanize::Catalyst;
    Test::WWW::Mechanize::Catalyst->import(qw|Angerwhale|);
    our @ISA = ('Test::WWW::Mechanize::Catalyst');
    my $class = shift;
    return $class->NEXT::new(@_);
}

sub tmp {
    return $tmp;
}

1;
