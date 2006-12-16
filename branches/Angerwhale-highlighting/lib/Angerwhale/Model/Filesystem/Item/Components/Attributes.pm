#!/usr/bin/perl
# Attributes.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Attributes;
use strict;
use warnings;

sub list_attributes {
    my $self = shift;
    return File::Attributes::list_attributes($self->location, @_);
}

sub set_attribute {
    my $self = shift;
    return File::Attributes::set_attribute($self->location, @_);
}

sub get_attribute {
    my $self = shift;
    return File::Attributes::get_attribute($self->location, @_);
}

1;
