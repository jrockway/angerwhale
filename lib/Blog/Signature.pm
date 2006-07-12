#!/usr/bin/perl
# Signature.pm
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::Signature;
use strict;
use warnings;

use Crypt::OpenPGP;
use Crypt::OpenPGP::Message;
use Crypt::OpenPGP::KeyServer;
use Crypt::OpenPGP::Signature;

use Data::Dumper;

sub new {
    my ($class, $data) = @_;
    my $self = {};
    $self->{data} = $data;
    $self->{pgp} = Crypt::OpenPGP->new(KeyServer => "stinkfoot.org", 
				       AutoKeyRetrieve => 1);
    
    my ($msg_data, $sig) =  _decode($self);
    
    $self->{decoded_data} = $msg_data;
    $self->{decoded_sig}  = $sig;

    return bless $self, $class;
}

sub _decode {
    my $self = shift;
    my ($data, $sig);
    
    my $in_data = $self->{data};
    my $pgp = $self->{pgp};
    my $msg = Crypt::OpenPGP::Message->new(  Data => $in_data ) or
      die "Reading message failed: ". Crypt::OpenPGP::Message->errstr;

    my @pieces = $msg->pieces;
    if (ref($pieces[0]) eq 'Crypt::OpenPGP::Compressed') {
	$data = $pieces[0]->decompress or
	  die "Decompression error: " . $pieces[0]->errstr;
	$msg = Crypt::OpenPGP::Message->new( Data => $data ) or
	  die"Reading decompressed data failed: " .
	    Crypt::OpenPGP::Message->errstr;
	@pieces = $msg->pieces;
    }
    if (ref($pieces[0]) eq 'Crypt::OpenPGP::OnePassSig') {
	($data, $sig) = @pieces[1,2];
    } 
    elsif (ref($pieces[0]) eq 'Crypt::OpenPGP::Signature') {
	($sig, $data) = @pieces[0,1];
    } 
    else {
	die "unable to read signature";
    }
    
    return ($data, $sig);
}

sub get_key_id {
    my $self = shift;
    return $self->{key_id} if $self->{key_id};

    my $sig = $self->{decoded_sig};
    my $key_id = $sig->key_id;
    $self->{key_id} = $key_id;
    return $key_id;
}

sub get_signed_data {
    my $self = shift;
    return $self->{decoded_data}->{data}. "\n"; # newline keeps YAML happy
}

# cut-n-pasted from Crypt::OpenPGP, then modified slightly :(
# let me use this space to comment that Crypt::OpenPGP's API is bad
sub verify {
    my $self = shift;
    my $pgp = $self->{pgp};
    
    my ($data, $sig);

    my $msg = Crypt::OpenPGP::Message->new( Data => $self->{data} ) or
      die "Reading signature failed: " .
	Crypt::OpenPGP::Message->errstr;

    my @pieces = $msg->pieces;

    if (ref($pieces[0]) eq 'Crypt::OpenPGP::Compressed') {
        $data = $pieces[0]->decompress or
	  die "Decompression error: " . $pieces[0]->errstr;
        $msg = Crypt::OpenPGP::Message->new( Data => $data ) or
	  die "Reading decompressed data failed: " .
	    Crypt::OpenPGP::Message->errstr;

        @pieces = $msg->pieces;
    }
    
    if (ref($pieces[0]) eq 'Crypt::OpenPGP::OnePassSig') {
        ($data, $sig) = @pieces[1,2];
    } 
    elsif (ref($pieces[0]) eq 'Crypt::OpenPGP::Signature') {
        ($sig, $data) = @pieces[0,1];
    } 
    else {
        die "unable to read signature";
    }
    
    die "no data found" if !$data;

    
    my($cert, $kb);
    my $key_id = $sig->key_id;
    my $ring = $pgp->pubrings->[0];
    unless ($ring && ($kb = $ring->find_keyblock_by_keyid($key_id))) {
	my $cfg = $pgp->{cfg};
	if ($cfg->get('AutoKeyRetrieve') && $cfg->get('KeyServer')) {
	    
	    my $server = 
	      Crypt::OpenPGP::KeyServer->new(Server => 
					     $cfg->get('KeyServer'));
	    
	    $kb = $server->find_keyblock_by_keyid($key_id);
	}
	return $pgp->error("Could not find public key with KeyID " .
			   unpack('H*', $key_id))
	  unless $kb;
    }
        
    $cert = $kb->signing_key;

## pgp2 and pgp5 do not trim trailing whitespace from "canonical text"
## signatures, only from cleartext signatures. So we first try to verify
## the signature using proper RFC2440 canonical text, then if that fails,
## retry without trimming trailing whitespace.
## See:
##   http://cert.uni-stuttgart.de/archive/ietf-openpgp/2000/01/msg00033.html
    my($dgst, $found);
    for (1, 0) {
        local $Crypt::OpenPGP::Globals::Trim_trailing_ws = $_;
        $dgst = $sig->hash_data($data) or
            return $pgp->error( $sig->errstr );
        $found++, last if substr($dgst, 0, 2) eq $sig->{chk};
    }
    
    return 0 unless $found; # failed validation;
    
    my $valid = $cert->key->public_key->verify($sig, $dgst) ?
      ($kb && $kb->primary_uid ? $kb->primary_uid : 1) : 0;
    
    return $valid;
}



1;
