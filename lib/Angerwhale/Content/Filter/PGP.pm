package Angerwhale::Content::Filter::PGP;
use Crypt::GpgME;
use Encode;
use strict;
use warnings;

=head2 filter

Convert PGP-encoded body to plain text equivalent, and store raw text
in the metadata area as C<raw_text>.

If the signature is valid, set the C<author> metadata item
appropriately.

=cut

sub filter {
    return 
      sub {
          my $self = shift;
          my $context = shift;
          my $item = shift;

          my $ctx = Crypt::GpgME->new;
          my $result;
          my $text;
          eval {
              # PGP wants octets, not characters
              my $data = $item->data;
              $data = Encode::encode('utf8', $data);
              ($result, $text) = $ctx->verify($data);
              $text = Encode::decode('utf8', $text);
          };

          if($text){
              $item->metadata->{raw_text} = $item->data;
              $item->data($text);
          }
          
          return $item;
      };
}

1;
