package Angerwhale::Controller::Login;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Angerwhale::Challenge;
use Crypt::OpenPGP;
use YAML::Syck;

# XXX: HACK, HACK, HACK ... !
use Angerwhale::ContentItem::Components::Signature;

=head1 NAME

Angerwhale::Controller::Login - Handles logins

=head1 SYNOPSIS

See L<Angerwhale>

=head2 nonce

Generate a textual challenge.

=head2 process

Process a signed challenge, and log the user in if the challenge is
valid.

=cut

sub nonce : Local {
    my ( $self, $c ) = @_;

    my $nonce =
      Angerwhale::Challenge->new( { uri => $c->request->base->as_string } );
    $c->session->{nonce} = $nonce;    # for verifier
    $c->stash->{nonce}   = $nonce;    # for template

    if ( !$c->stash->{template} ) {
        $c->response->content_type('text/plain');
        $c->response->body($nonce);
    }

    return;
}

sub process : Local {
    my ( $self, $c ) = @_;
    my $input     = $c->request->param('login');
    my $keyserver = $c->model('UserStore')->keyserver;

    my $nonce_data = 
      eval {
          Angerwhale::ContentItem::Components::Signature->_signed_text($input);
      };
    
    if ( !$nonce_data ) {
        $c->flash( error => "I couldn't read the signature.  Try again?" );
        $c->res->redirect( $c->uri_for('/login') );
        $c->detach();
    }

    my $pgp = Crypt::OpenPGP->new(
        KeyServer       => $keyserver,
        AutoKeyRetrieve => 1
    );
    my ( $long_id, $sig ) = $pgp->verify( Signature => $input );
    if ( !$nonce_data || !$sig ) {
        $c->flash( error => 'There was a problem verifying the signature.' );
        $c->res->redirect( $c->uri_for('/login') );
        $c->detach();
    }

    my $sig_ok      = $sig && $long_id;
    my $key_id      = $sig->key_id;
    my $nice_key_id = "0x" . substr( unpack( "H*", $key_id ), -8, 8 );

    $c->log->debug("keyid $nice_key_id ($long_id) is presumably logging in");

    eval {
        my $challenge = Load($nonce_data)
          or die "couldn't deserialize request";
        my $nonce = $c->session->{nonce};
        $c->session->{nonce} = undef;

        my $nonce_ok = ( $nonce == $challenge );
        $c->log->debug("$nice_key_id: nonce verified OK (was $challenge)")
          if $nonce_ok;
        $c->log->debug("$nice_key_id: Signature was valid")
          if $sig_ok;

        die "bad nonce" if !$nonce_ok;
        die "bad sig"   if !$sig_ok;
    };

    if ($@) {
        $c->log->debug("Failed login for $nice_key_id: $@");
        $c->response->body("You cheating scum!  You are NOT $nice_key_id!");
        return;
    }

    my $user;
    eval {
        $user = $c->model('UserStore')->get_user_by_real_id($key_id);
        $c->model('UserStore')->refresh_user($user);
    };
    if ($@) {
        $c->flash( error => 'Your data could not be loaded from a keyserver.'
              . '  Please push your key to one and try again.' );
        $c->res->redirect( $c->uri_for('/login') );
        $c->detach();
    }
    $c->session->{user} = $user;
    $c->log->debug(
        "successful login for " . $user->fullname . "($nice_key_id)" );
    $c->response->redirect( $c->uri_for('/') );
}

=head2 index

Render the login page

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'login.tt';
    $c->forward('nonce');
}

=head2 logout

Delete the current session and user

=cut

sub logout : Local {
    my ($self, $c) = @_;
    $c->delete_session('logout');
    $c->res->redirect($c->uri_for('/'));
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
