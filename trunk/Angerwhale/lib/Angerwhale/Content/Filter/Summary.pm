# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Summary;
use strict;
use warnings;

my $ELIPSIS = "\x{2026}";

sub filter {
    return
      sub {
          my $self = shift;
          my $context = shift;
          my $item = shift;
          
          my $summary = $item->metadata->{formatted}{text} || q{};
          
          my @words = split /\s+/, $summary;
          $item->metadata->{words}   = scalar @words;
          
          if ( @words > 10 ) {
              @words = @words[ 0 .. 9 ];
              $summary = join q{ }, @words;
              $summary .= " $ELIPSIS";
          }
          
          $item->metadata->{summary} = $summary;
      };
}
1;

