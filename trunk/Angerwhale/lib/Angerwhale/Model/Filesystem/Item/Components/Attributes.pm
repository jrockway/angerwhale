#!/usr/bin/perl
# Attributes.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Attributes;
use strict;
use warnings;
use File::Attributes qw(list_attributes set_attribute get_attribute);

sub list_attributes {
    my $self = shift;
    return list_attributes($self->location, @_);
}

sub set_attribute {
    my $self = shift;
    return set_attribute($self->location, @_);
}

sub get_attribute {
    my $self = shift;
    return get_attribute($self->location, @_);
}

1;
