# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::URI;
use strict;
use warnings;

=head2 filter

Adds URLs for posting comments, viewing replies, etc. to the metadata.

=cut

sub filter {
    return 
      sub {
          my $self = shift;
          my $context = shift;
          my $item = shift;

          my $path = $item->metadata->{path};
          my $name = $item->metadata->{name};
          
          my $me;
          if ($item->metadata->{comment}) {
              $me = $item->metadata->{uri} = "comments/$path";
          }
          else {
              $item->metadata->{uri} = "articles/$name";
          }
          
          $path ||= $item->id;
          $item->metadata->{post_uri}   = "comments/post/$path";
          
          if ($me) {
              $me =~ s{/[^/]+$}{};
              $item->metadata->{parent_uri} = $me;
          }
          
          return $item;
      };
}

1;

