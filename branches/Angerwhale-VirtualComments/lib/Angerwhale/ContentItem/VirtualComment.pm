#!/usr/bin/perl
# VirtualComment.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::ContentItem::VirtualComment;
use strict;
use warnings;
use Angerwhale::User::Anonymous;
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

# XXX: fixme

sub cache {
    use Test::MockObject;
    my $cache = Test::MockObject->new;
    $cache->set_always('get' => undef);
    $cache->set_always('set' => undef);
    return $cache;
}

sub id {
    my $self = shift;
    return $self->{guid};
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
    my $self = shift;
    return $self->{ctime};
}

sub modification_time {
    my $self = shift;
    return $self->{mtime};
}

sub raw_text {
    my $self = shift;
    return $self->NEXT::raw_text($_[0], $self->{raw_text});
}

sub type {
    my $self = shift;
    return $self->{type};
}

sub signor {
    my $self = shift;
    return $self->{author}->{key_id};
}

sub _fix_author {}
sub _cache_signature {}

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

sub uri {
    my $self = shift;
    return $self->{uri};
}

1;
