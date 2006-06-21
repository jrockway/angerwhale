#!/usr/bin/perl
# User.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::User;
use strict;
use warnings;
use Crypt::OpenPGP::KeyServer;
use Crypt::OpenPGP::KeyRing;
use Carp qw(cluck);
use YAML;

# id is Crypt::OpenPGP's format, i.e. the hex value packed into
# 'H*'.  ($id = pack 'H*', hex "cafebabe") for 0xcafebabe
sub new {
    my ($class, $id, $key) = @_;
    my $self = {};
    die "specify id" if !$id;
    $self->{niceid} = unpack('H*', $id);
    
#    if($key){
#	$self->{key} = $key;
#    }
#    else {
#	$self->{key} = _refresh_key($id);
#    }
#    
#    die "no key" if !$self->{key};
    
    return bless $self, $class;
}

=head2 id

Returns the ID of the key as a 64-bit integer (actually, it returns
the binary representation of that integer as a string of eight bytes)

=cut

sub id {
    my $self = shift;
    my $id = pack('H*', $self->nice_id);
}

=head2 nice_id

Returns the ID of the key as a 64-bit hexadecimal representation
(i.e. 0x0f00b412cafebabe).  The last four octets are what users think
the OpenPGP key id is.

=cut

sub nice_id {
    my $self = shift;
    return $self->{niceid};
}

sub refresh {
    my $self = shift;
    $self->refresh_key;
    $self->fullname;
}

sub refresh_key {
    my $self = shift;
    my $key_id = $self->id;
    my $ks = Crypt::OpenPGP::KeyServer->new(Server => "stinkfoot.org");
    my $kb = $ks->find_keyblock_by_keyid($key_id);
    $self->{public_key} = $kb;
    return $kb;
}

sub key {
    my $self = shift;
    
    # try to get the key if we don't have it
    if(!$self->{public_key}){
	$self->{public_key} = $self->refresh_key;
    }

    # see if we have it
    if(!$self->{public_key}){
	die "No public key found.";
    }
    
    return $self->{public_key};
}

sub public_key {
    my $self = shift;
    my $key = $self->key;
    return $key->save_armoured;
}

sub key_fingerprint {
    my $self = shift;
    my $key = $self->key;
    my $signer = $key->signing_key;
    return unpack 'H*', $signer->fingerprint;
}

sub fullname {
    my $self = shift;
    if($self->{fullname}){
	return $self->{fullname};
    }
    else {
	my $key = $self->key;
	my @uids = @{$key->{pkt}->{"Crypt::OpenPGP::UserID"}};
	my $uid = $uids[0]->id; # XXX: best idea?
	$uid =~ s/\s*<.+>\s*//g;
	$uid =~ s/\s*[(].+[)]\s*//g;
	return ($self->{fullname} = $uid);
    }
}

sub email {
    my $self = shift;
    my $key = $self->key;
    my @uids = @{$key->{pkt}->{"Crypt::OpenPGP::UserID"}};
    my $uid = $uids[0]->id; # XXX: best idea?
    $uid =~ s/<(.+)>//g;
    return $1;
}

sub photo {
    die "nyi";
}

# BUG:
# I wish YAML::Syck would call these for me, but I have to remember
# to call them each time.

sub freeze {
    my $self = shift;
    my $key = $self->{public_key};
    $self->{public_key} = $key->save_armoured if $key;
}

sub thaw {
    my $self = shift;
    my $key = $self->{public_key};
    my $ring = Crypt::OpenPGP::KeyRing->new( Data => $key )
      or die Crypt::OpenPGP::KeyRing->errstr;
    $key = $ring->find_keyblock_by_index(0);
    $self->{public_key} = $key;
}

1;
