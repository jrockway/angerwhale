#!/usr/bin/perl
# User.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::User;
use strict;
use warnings;

sub new {
    my ($class, $args) = @_;
    return bless $args, $class;
}

sub fullname {
    my $self = shift;
    return 'Anonymous Coward';
}

sub id {
    my $self = shift;
    return '0x13371337';
}

sub email {
    my $self = shift;
    return 'nobody@example.com';
}

1;
