#!/usr/bin/perl
# Anonymous.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Angerwhale::User::Anonymous;
use strict;
use warnings;
use base qw(Angerwhale::User);

sub new {
    my $class = shift;
    my $self = {};
    
    return bless $self, $class;
}

sub nice_id {
    return 0;
}

sub id {
    return 0;
}

sub fullname {
    return "Anonymous Coward";
}

sub email {
    return q{};
}

			
1;

