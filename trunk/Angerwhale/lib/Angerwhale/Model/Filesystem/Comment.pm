#!/usr/bin/perl
# Comment.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Angerwhale::Model::Filesystem::Comment;
use strict;
use warnings;
use base qw(Angerwhale::Model::Filesystem::Item);

sub uri {
    my $self = shift;
    my $parent = $self->{parent};

    return "comments/". $self->path;
}


1;

