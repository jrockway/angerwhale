#!/usr/bin/perl
# GUID.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::GUID;
use strict;
use warnings;
use Data::GUID;
use File::Attributes qw(get_attribute set_attribute);

sub id {
    my $self = shift;
    my $path = (-l $self->location) ? readlink($self->location) 
                                    : $self->location;
    my $guid;
    eval {
	$guid = get_attribute($self->location, 'guid');
	$guid = Data::GUID->from_string($guid);
    };
    return $guid->as_string if(!$@ && $guid->as_string);
      
    $guid = Data::GUID->new;
    
    eval { set_attribute($self->location, 'guid', $guid->as_string) };
    die "Problem setting guid on $path: $@" if $@;
    
    return $guid->as_string;
}

1; # magic true value
