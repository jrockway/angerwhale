#!/usr/bin/perl
# Comment.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::ContentItem::Comment;
use strict;
use warnings;
use base qw(Angerwhale::ContentItem);
use Class::C3;
use Carp;
use Scalar::Util qw(blessed);
use Angerwhale::Format;

=head1 NAME

Angerwhale::ContentItem::Comment - Represents a C<ContentItem> that's
a comment (not an Article).

=head1 METHODS

=head2 new

Create a comment, see L<Angerwhale::ContentItem> for details.

=head2 uri

Return the URI of this comment.

=cut

sub new {
    my ( $class, $args ) = @_;
    croak 'Comments must have a parent'
      if !blessed $args->{parent}
      || !$args->{parent}->isa('Angerwhale::ContentItem');

    my $self = $class->next::method($args);
    return $self;
}

sub uri {
    my $self = shift;
    return 'comments/' . $self->path;
}

1;

