# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::URI;
use strict;
use warnings;

sub filter {
    return 
      sub {
          my $self = shift;
          my $context = shift;
          my $item = shift;

          my $path = $item->metadata->{path};
          my $name = $item->metadata->{name};

          warn "path is $path, $name is name";

          if ($item->metadata->{comment}) {
              $item->metadata->{uri} = 
                $context->uri_for("/comments/$path");
          }
          else {
              $item->metadata->{uri} =
                $context->uri_for("/articles/$name");
          }
          
          $item->metadata->{post_uri} = 
            $context->uri_for("/comments/post/$path");
          
          return $item;
      };
}

1;

