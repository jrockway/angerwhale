# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Encoding;
use strict;
use warnings;
use Encode;

sub filter {
    my $encoding = shift;
    return
      sub {
          my $self    = shift;
          my $context = shift;
          my $item    = shift;

          # see if the item knows its own encoding (XXX)
          if ($item->metadata->{encoding}) {
              $encoding = $item->metadata->{encoding};
          }
          
          # decode data
          my $text = $item->data;
          $text = Encode::decode($encoding, $text, 1) 
            unless utf8::is_utf8($text);
          $item->data($text);
          
          # decode metadata
          my %metadata = %{$item->metadata||{}};
          foreach (keys %metadata) {
              my $data = $metadata{$_};
              $data = Encode::decode($encoding, $data, 1)
                unless utf8::is_utf8($data);
              $metadata{$_} = $data;
          }
          $item->metadata(\%metadata);

          return $item;
      };
}

1;

