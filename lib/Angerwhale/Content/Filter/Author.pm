# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Author;
use strict;
use warnings;
use Angerwhale::User::Anonymous;

=head2 filter

Adds author information.

=cut

sub filter {
    return
      sub {
          my $self = shift;
          my $context = shift;
          my $item = shift;

          my $id = $item->metadata->{raw_author} = $item->metadata->{author};
          my $author = eval {
              $context->model('UserStore')->get_user_by_nice_id($id)
                if $id;
          };
          $author ||= Angerwhale::User::Anonymous->new;
          $item->metadata->{author} = $author;
          return $item;
      };
}


1;

