# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Checksum;
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

=head2 filter

Caclulates the checksum of (hopefully) decoded text, and adds
the checksum to the metadata section of the item.

=cut

sub filter {
    return 
      sub {
          my $self    = shift;
          my $context = shift;
          my $item    = shift;
          my $text    = $item->data;
          utf8::encode($text) if utf8::is_utf8($text);
          $item->metadata->{checksum} = md5_hex($text);
          return $item;
      };
}

1;

