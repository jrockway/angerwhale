# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Author;
use strict;
use warnings;
use Angerwhale::User::Anonymous;

=head2 filter

Adds author information.

=cut

# XXX: todo; real users :)
sub filter {
    return
      sub {
          my $self = shift;
          my $context = shift;
          my $item = shift;
          $item->metadata->{raw_author} = $item->metadata->{author};
          $item->metadata->{author} = Angerwhale::User::Anonymous->new;
          return $item;
      };
}


1;

