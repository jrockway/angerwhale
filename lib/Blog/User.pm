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
    my ($class, $id, $key) = @_;
    my $self = {};
    die "specify id" if !$id;
    $self->{niceid} = unpack('H*', $id);
    $self = bless $self, $class;
    
    if($key){
	$self->{public_key} = $key;
    }
    
    die "no key" if !$self->key;
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
    return $self->{niceid};
}

sub refresh {
    my $self = shift;
    return $self->refresh_key;
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
	carp "No public key found for ". $self->nice_id;
    }
    
    return $self->{public_key};
}

sub public_key {
    my $self = shift;
    my $key = $self->key;
    return $key->save_armoured;
}

sub key_fingerprint {
    my $self   = shift;
    my $key    = $self->key;
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


1;
