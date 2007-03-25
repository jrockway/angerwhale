# PGPAuthor.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::PGP;
use Angerwhale::Signature;
use Crypt::OpenPGP;
use Encode;
use strict;
use warnings;

=head2 filter

Convert PGP-encoded body to plain text equivalent, and store raw text
in the metadata area as C<raw_text>.

If the signature is valid (or cached), set the C<author> metadata item
appropriately.

=cut

sub filter {
    return 
      sub {
          my $self = shift;
          my $context = shift;
          my $item = shift;

          my $text;
          eval {
              # PGP wants octets, not characters
              my $data = $item->data;
              $data = Encode::encode('utf8', $data) if utf8::is_utf8($data);
              $text = Angerwhale::Signature->_signed_text($data);
              $text = Encode::decode('utf8', $text) if !utf8::is_utf8($text);
          };
          
          if($text){
              $item->metadata->{raw_text} = $item->data;
              $item->data($text);
          }
          else {
              return $item; # we're done.  nothing to do.
          }

          if($item->metadata->{raw_author} &&
             $item->metadata->{signed} eq 'yes'){
              # signature is cached, so restore user without checking sig
              $item->metadata->{author} = 
                $context->model('UserStore')->
                  get_user_by_nice_id($item->metadata->{raw_author});

              $item->metadata->{signor} =
                pack( "H*", $item->metadata->{raw_author});
          }
          else {
              # no cached signature, check the signature
              my $author =
                get_user_signature($item->metadata->{raw_text},
                                   $context->model('UserStore'));
              
              if(!$author){
                  # bad signature!
                  $item->metadata->{author} = Angerwhale::User::Anonymous->new;
              }
              else {
                  # good signature
                  # cache the signature so we don't have to verify again
                  $item->store_attribute('signed', 'yes');
                  $item->store_attribute('author',  unpack( "H*", $author));
                  $item->metadata->{raw_author} = $item->metadata->{author};
                  
                  # setup the "inflated" author
                  $item->metadata->{author} =
                    $context->model('UserStore')->
                      get_user_by_real_id($author);

                  $item->metadata->{signor} = $author;
              }
          }
          
          return $item;
      };
}

=head2 get_user_signature

Returns keyid of signature, or false if the signature is invalid.

=cut

sub get_user_signature {
    my ($message, $userstore) = @_;
    my $keyserver = $userstore->keyserver;
    my $pgp       = Crypt::OpenPGP->new(
                                        KeyServer       => $keyserver,
                                        AutoKeyRetrieve => 1
                                       );
    
    my ( $id, $sig ) = $pgp->verify( Signature => $message );
    
    die $pgp->errstr    if !defined $id;
    return $sig->key_id if $id;
    return 0;    # otherwise
}

1;
