#!/usr/bin/perl
# Anonymous.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::User::Anonymous;
use Blog::User;
use base qw(Blog::User);

sub new {
    my $class = shift;
    my $self = {};
    
    return bless $self, $class;
}

sub id {
    return 0;
}

sub fullname {
    return "Anonymous Coward";
}

sub email {
    return "example@example.com";
}

			
1;

