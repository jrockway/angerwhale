# Signature.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Signature;
use strict;
use warnings;
use Crypt::OpenPGP;
use Crypt::OpenPGP::Message;
use Angerwhale::User::Anonymous;
use File::Attributes qw(get_attribute set_attribute);
use Carp;
use YAML::Syck;

=head1 METHODS

=head2 signor

Returns the key id of the message's signor, or 0 if the message is not
signed.

=cut

sub signor {
    my $self = shift;
    my ( $data, $sig ) = $self->_signed_text( $self->raw_text(1) );
    return $sig->key_id;
}

=head2 signed

Returns true if the signature is good, false otherwise.

More detail:

=over 4

=item C<1> 

means the signature was actually checked

=item C<2>

means "signed=yes" was read as an attribute from cache

=item C<0>

BAD SIGNATURE!

=item C<undef>

message was not signed

=back

=cut

sub signed {
    my $self     = shift;
    my $raw_text = $self->raw_text(1);
    return if $self->raw_text eq $raw_text;

    my $result = eval {

        # XXX: Crypt::OpenPGP is really really slow, so cache the result
        my $signed = $self->_cached_signature;

        if ( defined $signed && $signed eq "yes" ) {

            # good signature
            return 2;
        }

        my $id;
        if ( $id = $self->_check_signature( $self->raw_text(1) ) ) {

            # and fix the author info if needed
            $self->_cache_signature;
            $self->_fix_author($id);
            return 1;
        }
        else {
            die "Bad signature";
        }
    };
    if ($@) {

        #"Problem checking signature on ". $self->uri. ": $@";
        return 0;
    }

    return $result;
}

=head2 _check_signature($message)

Checks the OpenPGP signature on $message.  Returns the real (binary)
key id if the signature is valid.  Raises an exception on error.

B<Warning: slow.>  It is best to cache the result, if possible.

=cut

sub _check_signature {
    my ( $self, $message ) = @_;
    my $keyserver = $self->userstore->keyserver;
    my $pgp       = Crypt::OpenPGP->new(
        KeyServer       => $keyserver,
        AutoKeyRetrieve => 1
    );
    my ( $id, $sig ) = $pgp->verify( Signature => $message );

    die $pgp->errstr    if !defined $id;
    return $sig->key_id if $id;
    return 0;    # otherwise
}

=head2 signed_text($message)

Given PGP-signed $message, returns the plaintext of that message.
Throws an exception on error.

In array context, returns an list (data, signature), where data is a
Crypt::OpenPGP::PlainText and signature isa Crypt::OpenPGP::Signature
ora Crypt::OpenPGP::OnePassSig.

=cut

sub _signed_text {
    my ( $self, $message ) = @_;
    my ( $data, $sig );
    
    my $msg = Crypt::OpenPGP::Message->new( Data => $message )
      or croak "Reading message failed: " . Crypt::OpenPGP::Message->errstr;

    my @pieces = $msg->pieces;
    if ( ref( $pieces[0] ) eq 'Crypt::OpenPGP::Compressed' ) {
        $data = $pieces[0]->decompress
          or die "Decompression error: " . $pieces[0]->errstr;
        $msg = Crypt::OpenPGP::Message->new( Data => $data )
          or die "Reading decompressed data failed: "
          . Crypt::OpenPGP::Message->errstr;
        @pieces = $msg->pieces;
    }

    if ( ref( $pieces[0] ) eq 'Crypt::OpenPGP::OnePassSig' ) {
        ( $data, $sig ) = @pieces[ 1, 2 ];
    }
    elsif ( ref( $pieces[0] ) eq 'Crypt::OpenPGP::Signature' ) {
        ( $sig, $data ) = @pieces[ 0, 1 ];
    }
    else {
        croak "unable to read signature";
    }

    return ( $data, $sig ) if wantarray;
    return $data->{data};    # otherwise, just the data
}

=head1 _cached_signature

Returns the cached signature; true for "signature ok", false for
"signature not ok" (or no signature).

=cut

sub _cached_signature {
    my $self = shift;
    return eval { get_attribute( $self->location, 'signed' ) };
}

=head1 _cached_signature

Sets the cached signature to true.

=cut

sub _cache_signature {
    my $self = shift;

    # set the "signed" attribute
    set_attribute( $self->location, 'signed', "yes" );
}

# if a user posts a comment with someone else's key, ignore the login
# and base the author on the signature

sub _fix_author {
    my $self        = shift;
    my $id          = shift;
    my $nice_key_id = unpack( "H*", $id );

    set_attribute( $self->location, 'author', $nice_key_id );
}

1;
