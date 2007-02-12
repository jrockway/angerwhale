#!/usr/bin/perl
# Captcha.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Controller::Captcha;
use base 'Catalyst::Controller';
use GD::SecurityImage;

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
  
sub captcha_uri : Private {
    my ($self, $c) = @_;
    return if $c->stash->{user}; # XXX user
    return if $c->session->{got_captcha};
    return $c->uri_for('/captcha/captcha');
}
  
sub check_captcha : Private {
    my ($self, $c, $guess) = @_;

    return unless ref $c->session->{captcha};
    
    if($c->session->{got_captcha} || $c->session->{captcha}->{rnd} == $guess){
        $c->session->{got_captcha} = 1; # only need to guess one per session
        return 1;
    }
    return;
}
  
1;
