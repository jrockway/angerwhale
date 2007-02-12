#!/usr/bin/perl
# Comment.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::Model::Filesystem::Comment;
use strict;
use warnings;
use base qw(Angerwhale::Model::Filesystem::Item);
use Class::C3;
use Carp;
use Scalar::Util qw(blessed);
use Angerwhale::Format;

=head1 Filesystem::Article

Represents a C<Filesystem::Item> that's a comment (not an Article).

=head1 METHODS

=head2 new

Create a comment, see C<Filesystem::Item::new> for details.

=head2 uri

Return the URI of this comment.

=cut

sub new {
    my ( $class, $args ) = @_;
    croak 'Comments must have a parent'
      if !blessed $args->{parent}
      || !$args->{parent}->isa('Angerwhale::Model::Filesystem::Item');

    my $self = $class->next::method($args);

    if($self->type =~ /virtual/){
        warn "debug: virtual comment";
        $self = Angerwhale::Format::format($self->raw_text, $self->type);
    }

    return $self;
}

sub uri {
    my $self = shift;
    return 'comments/' . $self->path;
}

1;

