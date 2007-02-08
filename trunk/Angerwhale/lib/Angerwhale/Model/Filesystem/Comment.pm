#!/usr/bin/perl
# Comment.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::Model::Filesystem::Comment;
use strict;
use warnings;
use base qw(Angerwhale::Model::Filesystem::Item);
use Class::C3;
use Carp;
use Scalar::Util qw(blessed);
=head1 Filesystem::Article

Represents a C<Filesystem::Item> that's a comment (not an Article).

=head1 METHODS

=head2 new

Create a comment, see C<Filesystem::Item::new> for details.

=head2 uri

Return the URI of this comment.

=cut

sub new {
    my ($class, $args) = @_;
    croak 'Comments must have a parent'
      if !blessed $args->{parent} || 
	!$args->{parent}->isa('Angerwhale::Model::Filesystem::Item');

    $class->next::method($args);
}

sub uri {
    my $self = shift;
    return 'comments/'. $self->path;
}


1;

