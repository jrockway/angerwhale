#!/usr/bin/perl
# Signature.pm<2> 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Signature;
use strict;
use warnings;
use Crypt::OpenPGP;
use Angerwhale::User::Anonymous;

=head1 METHODS

=head2 check_signature($message)

Checks the OpenPGP signature on $message.  Returns the user object if
the signature is valid, undefined otherwise.  Raises an exception on
error.

=cut

sub check_signature : Private {
    my ($self, $message) = @_;
    my $c = $self->context;
    
    my $keyserver = $c->model('UserStore')->keyserver;
    
    my $pgp    = Crypt::OpenPGP->new( KeyServer => $keyserver );
    my $key_id = $pgp->verify( Data => $message );
    
    die $pgp->errstr if $key_id == 0; # error
    return if !defined $key_id;       # bad signature
    return $c->model('UserStore')->get_user_by_id($key_id); # good signature
}

=head2 signed_text($message)

Given PGP-signed $message, returns the plaintext of that message.
Throws an exception on error.

=cut

sub signed_text : Private {
    my ($self, $message) = @_;
    my $c = $self->context;
    
    my $pgp = Crypt::OpenPGP->new();
    die "broken";
    #return Crypt::OpenPGP->
}

# returns the real_key_id of the PGP signature
# you might want to validate the signature first; this routine doesn't do that
# see signed() below.
sub signor {
    my $self = shift;
    my $sig = Angerwhale::Signature->new($self->raw_text(1));
    return $sig->get_key_id;
}

sub _cached_signature {
    my $self = shift;
    return eval { get_attribute($self->location, 'signed') };
}

sub _cache_signature {
    my $self = shift;
    # set the "signed" attribute	
    set_attribute($self->location, 'signed', "yes");
}

# returns true if the signature is good, false otherwise
# 1 means the signature was checked against a current key and file
# 2 means "signed=yes" was read as an attribute (from cache)
# 0 means BAD SIGNATURE!
# undef means not signed

sub signed {
    my $self = shift;

    return if $self->raw_text eq $self->raw_text(1);

    my $result = eval {
	my $sig = Angerwhale::Signature->new($self->raw_text(1));

	# XXX: Crypt::OpenPGP is really really slow, so cache the result
	my $signed = $self->_cached_signature;

	if(defined $signed && $signed eq "yes"){
	    # good signature
	    return 2;
	}
	
	if($sig->verify){
	    # and fix the author info if needed
	    $self->_cache_signature;
	    $self->_fix_author($sig->get_key_id);
	    return 1;
	}
	else {
	    die "Bad signature";
	}
    };    
    if($@){
	#"Problem checking signature on ". $self->uri. ": $@";
	return 0;
    }
    
    return $result;
}

# if a user posts a comment with someone else's key, ignore the login
# and base the author on the signature

sub _fix_author {
    my $self   = shift;
    my $id     = shift;
    my $nice_key_id = unpack("H*", $id);
    
    set_attribute($self->location, 'author', $nice_key_id);
}

1;
