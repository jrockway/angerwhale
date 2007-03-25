# Captcha.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Controller::Captcha;
use strict;
use warnings;
use base 'Catalyst::Controller';
use GD::SecurityImage;
use HTTP::Date;

=head1 NAME

Angerwhale::Controller::Captcha - generate and validate captchas

=head1 METHODS

=head2 gen_captcha

Generate a security image and store it in the session

=cut

sub gen_captcha : Private {
    my ($self, $c) = @_;
    my($image, $type, $rnd) = GD::SecurityImage->new(height => 20, 
                                                     width => 80, 
                                                     scramble => 0,
                                                     lines => 2,
                                                     gd_font => 'Large',)
      ->random->create->out;
    
    $c->session->{captcha} = { image => $image,
                               type  => $type,
                               rnd   => $rnd,
                             };
}

=head2 captcha

Return the captcha to the browser

=cut


sub captcha : Path {
    my ($self, $c) = @_;

    $c->forward('gen_captcha') unless ref $c->session->{captcha};
    
    $c->response->body($c->session->{captcha}->{image});
    $c->response->content_type('image/'. $c->session->{captcha}->{type});    
    $c->res->headers->expires( time() );
    $c->res->headers->header( 'Last-Modified' => HTTP::Date::time2str );
    $c->res->headers->header( 'Pragma'        => 'no-cache' );
    $c->res->headers->header( 'Cache-Control' => 'no-cache' );
    $c->detach();
}
  
=head2 captcha_uri

Return the URI for the captcha, or nothing if the user has 
already used the captcha successfully, or he's logged in.

=cut

sub captcha_uri : Private {
    my ($self, $c) = @_;
    return if $c->stash->{user}; # XXX user
    return if $c->session->{got_captcha};
    return $c->uri_for('/captcha/captcha');
}
  
=head2 check_captcha($guess)

Returns true if the guess is the text in the captcha.

=cut

sub check_captcha : Private {
    my ($self, $c, $guess) = @_;

    return unless ref $c->session->{captcha};
    
    if($c->session->{got_captcha} || $c->session->{captcha}->{rnd} eq $guess){
        $c->session->{got_captcha} = 1; # only need to guess one per session
        return 1;
    }
    return;
}
  
1;
