#!/usr/bin/perl
# Comment.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::Model::Filesystem::Comment;
use strict;
use warnings;
use base qw(Blog::Model::Filesystem::Item);

sub uri {
    my $self = shift;
    my $parent = $self->{parent};

    return "comments/". $self->path;
}


1;

