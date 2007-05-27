# User.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::User;
use strict;
use warnings;
use Crypt::OpenPGP::KeyServer;
use Crypt::OpenPGP::KeyRing;
use Carp;

=head1 SYNOPSIS

Don't create an instance of this class directly; it's returned from
the UserStore when you need a user.

=head1 ACCESSORS

=head2 id

Returns the ID of the key as a 64-bit integer (actually, it returns
the binary representation of that integer as a string of eight bytes)

=cut

sub id {
    my $self = shift;
    my $id = pack( 'H*', $self->nice_id );
}

=head2 nice_id

Returns the ID of the key as a 64-bit hexadecimal representation
(i.e. 0x0f00b412cafebabe).  The last four octets are what users think
the OpenPGP key id is.

=cut

sub nice_id {
    my $self = shift;
    return $self->{nice_id};
}

=head2 _keyserver

Returns the name of the keyserver to refresh the key from.  Set when
initialized by UserStore.

=cut

sub _keyserver {
    my $self      = shift;
    my $keyserver = shift;
    $self->{keyserver} = $keyserver if $keyserver;
    return $self->{keyserver};
}

=head2 key

Returns the Crypt::OpenPGP::Keyblock representing the user's public
key.

B<NOTE>: Using this causes crashes, at least on my system during
testing.  Be careful.

=cut

sub key {
    my $self = shift;
    my $ks   = Crypt::OpenPGP::KeyServer->new( Server => $self->_keyserver );
    my $kb   = $ks->find_keyblock_by_keyid( $self->id );

    # try to get the key if we don't have it

    if ( !$kb ) {
        carp "No public key found for " . $self->nice_id;
    }

    return $kb;
}

=head2 public_key

Returns the ACSII-armoured OpenPGP public key block.

=cut

sub public_key {
    my $self = shift;
    my $key  = shift;

    return $self->{public_key} if $self->{public_key};
    return $key->save_armoured;
}

=head2 key_fingerprint

Returns the 160-bit key fingerprint as a lowercase hex string.  (Same
as what keyservers and GPG call the fingerprint.)

=cut

sub key_fingerprint {
    my $self = shift;
    my $key  = shift;
    return $self->{fingerprint} if $self->{fingerprint};

    my $signer = $key->signing_key;
    return unpack 'H*', $signer->fingerprint;
}

=head2 fullname

Returns the full name associated with the primary UID.

=cut

sub fullname {
    my $self = shift;
    my $key  = shift;
    return $self->{fullname} if $self->{fullname};

    my $name = eval {
        my @uids = @{ $key->{pkt}->{'Crypt::OpenPGP::UserID'} };
        my $uid = $uids[0]->id;    # XXX: best idea?
        $uid =~ s/\s*<.+>\s*//g;
        $uid =~ s/\s*[(].+[)]\s*//g;
        return ( $self->{fullname} = $uid );
    };
    return "Unknown Name" if ($@);
    return $name;
}

=head2 email

Returns the e-mail address associated with the primary UID.

=cut

sub email {
    my $self = shift;
    my $key  = shift;
    return $self->{email} if defined $self->{email};

    my @uids = @{ $key->{pkt}->{"Crypt::OpenPGP::UserID"} };
    my $uid  = $uids[0]->id;                                   # XXX: best idea?
    $uid =~ s/<(.+)>//g;
    return $1;
}

=head2 photo

Returns the first photo block in the key.  NOT IMPLEMENTED.

=cut

sub photo {
    die "nyi";
}

=head2 refresh

Refreshes the key from the network.

=cut

sub refresh {

    # doesn't do anything anymore
    my $self = shift;
    my $key  = $self->key;    # throws a good error on E_KEYNOTFOUND
    $self->{public_key}  = $self->public_key($key);
    $self->{fullname}    = $self->fullname($key);
    $self->{email}       = $self->email($key);
    $self->{fingerprint} = $self->key_fingerprint($key);

    #    $self->{photo} = $self->photo($key);
}

# only for testing
sub _new {
    my ( $class, $id ) = @_;
    my $user = {};
    die 'specify id' if !$id;
    $user->{nice_id} = unpack( 'H*', $id );
    $user = bless $user, $class;
    $user->_keyserver('subkeys.pgp.net');
    $user->refresh;
    return $user;
}

1;
