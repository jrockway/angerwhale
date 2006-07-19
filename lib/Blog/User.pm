#!/usr/bin/perl
# User.pm
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::User;
use strict;
use warnings;
use Crypt::OpenPGP::KeyServer;
use Crypt::OpenPGP::KeyRing;
use Carp;

# id is Crypt::OpenPGP's format, i.e. the hex value packed into
# 'H*'.  ($id = pack 'H*', hex "cafebabe") for 0xcafebabe
sub new {
    my ($class, $id) = @_;
    my $self = {};
    die "specify id" if !$id;
    $self->{nice_id} = unpack('H*', $id);
    $self = bless $self, $class;    
    
    $self->refresh;
    return $self;
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
    return $self->{nice_id};
}

sub key {
    my $self = shift;
    my $ks = Crypt::OpenPGP::KeyServer->new(Server => "stinkfoot.org");
    my $kb = $ks->find_keyblock_by_keyid($self->id);
    
    # try to get the key if we don't have it

    if(!$kb){
	carp "No public key found for ". $self->nice_id;
    }
    
    return $kb;
}

sub public_key {
    my $self = shift;
    my $key  = shift;

    return $self->{public_key} if $self->{public_key};
    return $key->save_armoured;
}

sub key_fingerprint {
    my $self   = shift;
    my $key    = shift;
    return $self->{fingerprint} if $self->{fingerprint};
    
    my $signer = $key->signing_key;
    return unpack 'H*', $signer->fingerprint;
}

sub fullname {
    my $self = shift;
    my $key  = shift;
    return $self->{fullname} if $self->{fullname};

    my $name = eval {
	my @uids = @{$key->{pkt}->{'Crypt::OpenPGP::UserID'}};
	my $uid = $uids[0]->id; # XXX: best idea?
	$uid =~ s/\s*<.+>\s*//g;
	$uid =~ s/\s*[(].+[)]\s*//g;
	return ($self->{fullname} = $uid);
    };
    return "Unknown Name" if($@);
    return $name;
}

sub email {
    my $self = shift;
    my $key  = shift;
    return $self->{email} if defined $self->{email};

    my @uids = @{$key->{pkt}->{"Crypt::OpenPGP::UserID"}};
    my $uid = $uids[0]->id; # XXX: best idea?
    $uid =~ s/<(.+)>//g;
    return $1;
}

sub photo {
    die "nyi";
}

sub refresh {
    # doesn't do anything anymore
    my $self = shift;
    my $key  = $self->key; # throws a good error on E_KEYNOTFOUND
    $self->{public_key}  = $self->public_key($key);
    $self->{fullname}    = $self->fullname($key);
    $self->{email}       = $self->email($key);
    $self->{fingerprint} = $self->key_fingerprint($key);
#    $self->{photo} = $self->photo($key);
}

1;
