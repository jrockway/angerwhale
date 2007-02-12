#!/usr/bin/perl
# VirtualComment.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::ContentItem::VirtualComment;
use strict;
use warnings;
use base 'Angerwhale::ContentItem';

=head1 NAME

Angerwhale::VirtualComment - a comment that doesn't exist on disk, but
is a child of a real comment or article.

=cut

sub new {
    my $class = shift;
    my $args  = shift;
    bless $args => $class;
}

sub comment_dir {
    return;
}

sub parent {
    my $self = shift;
    return $self->{parent};
}

sub title {
    my $self = shift;
    return $self->{title};
}

sub creation_time {
    return time();
}

sub modification_time {
    return time();
}

sub raw_text {
    my $self = shift;
    return $self->{raw_text};
}

sub type {
    my $self = shift;
    return $self->{type};
}

sub author {
    my $self = shift;
    return $self->{author};
}

sub comments {
    my $self = shift;
    return @{$self->{comments}||[]};
}

sub comment_count {
    my $self = shift;
    return scalar $self->comments;
}

sub add_comment {
    return; # no.
}

sub post_uri {
    return "I don't know.";
}

1;
