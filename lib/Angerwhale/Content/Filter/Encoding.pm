# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Encoding;
use strict;
use warnings;
use Encode;

=head2 filter($app)

Reads the encoding from the metadata, and converts the encoded
data to a perl character string.  Defaults to utf-8 if no 
other encoding is specified in the application config
or in the article metadata.

=cut

sub filter {
    my $class = shift;
    my $application = shift;
    my $encoding = $application->config->{encoding} || 'utf-8';
    
    return
      sub {
          my $self    = shift;
          my $context = shift;
          my $item    = shift;

          # see if the item knows its own encoding (XXX)
          if ($item->metadata->{encoding}) {
              $encoding = $item->metadata->{encoding};
          }
          else {
              $item->metadata->{encoding} = $encoding;
          }
          
          # decode data
          my $text = $item->data;
          $text = Encode::decode($encoding, $text, 1) 
            unless utf8::is_utf8($text);
          $item->data($text);

          return $item;
      };
}

1;

