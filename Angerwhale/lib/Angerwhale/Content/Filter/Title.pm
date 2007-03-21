# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Title;
use strict;
use warnings;

=head2 filter

Guesses a title from the name of the article if a title
isn't already in the metadata.

=cut

sub filter {
    return 
      sub {
          my $self = shift;
          my $context = shift;
          my $item = shift;
          my $title = $item->metadata->{title};
          
          my $name = $item->metadata->{name};
          if ( !$title ) {
              $title = $name;
              $title =~ s{[.]\w+$}{};
          }
          $item->metadata->{title} = $title;

          return $item;
      }
  }
1;

