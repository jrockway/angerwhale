#!/usr/bin/perl
# User.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::User;
use strict;
use warnings;
use Crypt::OpenPGP::Keyserver;

# id is Crypt::OpenPGP's format, i.e. the hex value packed into
# 'H*'.  ($id = pack 'H*', hex "cafebabe") for 0xcafebabe
sub new {
    my ($class, $id, $key) = @_;
    my $self = {};
    
    $self->{id} = $id || die "specify id";
    
    if($key){
	$self->{key} = $key;
    }
    else {
	$self->{key} = _refresh_key($id);
    }
    
    die "no key" if !$self->{key};
    
    return bless $self, $class;
}

sub _refresh_key {
    my $key_id = shift;
    my $ks = Crypt::OpenPGP::KeyServer->new(Server => "pgp.mit.edu");
    my $kb = $ks->find_keyblock_by_keyid($key_id);
    return $kb;
}

sub public_key {
    my $self = shift;
    return (_refresh_key($self->{id}) || $self->{key} || die "no key");
}

sub fullname {
    my $self = shift;
    return 'Anonymous Coward';
}

sub id {
    my $self = shift;
    return unpack('H*', $self->{id});
}

sub photo {
    die "nyi";
}



1;
