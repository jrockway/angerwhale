package Angerwhale::Controller::Login;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Angerwhale::Challenge;
use YAML::Syck;

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

    eval {
        my $input = $c->request->param('login');

        my $ctx = Crypt::GpgME->new;
        my ($result, $nonce_data) = $ctx->verify($input);
    
        my $fpr = $result->{signatures}[0]{fpr};
        my $sig_ok = $result->{signatures}[0]{summary}[0] eq 'valid';
        
        $c->log->debug("keyid $fpr is logging in");
        
        my $challenge = Load($nonce_data)
          or die "couldn't deserialize request";
        my $nonce = delete $c->session->{nonce};
        
        my $nonce_ok = ( $nonce == $challenge );
        $c->log->debug("$fpr: nonce verified OK (was $challenge)")
          if $nonce_ok;
        $c->log->debug("$fpr: Signature was valid")
          if $sig_ok;
        
        die "bad nonce" if !$nonce_ok;
        die "bad sig"   if !$sig_ok;
        
        my $user = $c->model('UserStore')->get_pgp_user($fpr);
    
        # the session store refuses to store things if they get to big
        delete $user->{public_key};
        
        $c->session->{user} = $user;
        $c->log->debug(
            "successful login for " . $user->fullname . "($fpr)" );
        $c->flash( message => "You are now logged in as ". $user->fullname );
        $c->response->redirect( $c->uri_for('/') );
    };
    
    if($@){
        $c->flash( error => 'You could not be logged in.' );
        $c->res->redirect( $c->uri_for('/login') );
        $c->detach;
    };
}

sub login :Path {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'login.tt';
    $c->forward('nonce');
}

sub logout : Local {
    my ($self, $c) = @_;
    $c->delete_session('logout');
    $c->res->redirect($c->uri_for('/'));
}

1;

__END__

=head1 NAME

Angerwhale::Controller::Login - Handles logins

=head1 SYNOPSIS

See L<Angerwhale>

=head1 ACTIONS

=head2 nonce

Generate a textual challenge.

=head2 process

Process a signed challenge, and log the user in if the challenge is
valid.

=cut

=head2 login

Render the login page

=cut

=head2 logout

Delete the current session and user

=cut

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.
