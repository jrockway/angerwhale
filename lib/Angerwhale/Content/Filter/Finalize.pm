# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Finalize;
use strict;
use warnings;
use Angerwhale::Content::FinalizedItem;

=head2 filter

Returns a filter that will wrap an item in a FinalizedItem class.

=cut

sub filter {
    return
      sub {
          my $self   = shift;
          my $context= shift;
          my $item   = shift;
          
          return Angerwhale::Content::FinalizedItem->new($item);
      };
}

1;

