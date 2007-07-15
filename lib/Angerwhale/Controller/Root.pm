package Angerwhale::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Time::Local;

# this was auto-generated and is apparently essential
__PACKAGE__->config->{namespace} = q{};

=head1 NAME

Angerwhale::Controller::Root - Root Controller for this Catalyst based application

=head1 SYNOPSIS

See L<Angerwhale>.

=head1 DESCRIPTION

Root Controller for this Catalyst based application.

=head1 METHODS

=cut

=head2 auto

Setup some global variables.

=cut

sub auto : Private {
    my ( $self, $c ) = @_;
    $c->stash->{root} = $c->model('Articles');
    $c->stash->{user} = $c->session->{user};
    return 1;
}

=head2 blog

Render the main blog page (category '/').

=cut

sub blog : Path Args(0)  {
    my ( $self, $c, @date ) = @_;
    $c->stash->{page} = 'home';
    
    $c->forward( '/categories/show_category', ['/', @date] );
}

=head2 archives

dispatch to a date-based archive page for the main category, or show
404 if the format is wrong

=cut

sub archives : Local Args(3) {
    my ( $self, $c, $y, $m, $d ) = @_;
    
    $c->detach( '/categories/show_category', ['/', $y, $m, $d] )
      if(eval { timelocal(0, 0, 0, $d, $m-1, $y) });
    
    $c->detach('/not_found'); # invalid date, 404
}

=head2 not_found

Generic 404 not found page

=cut

sub not_found : Private {
    my ($self, $c) = @_;
    $c->stash(template => 'error.tt');
    $c->response->status(404);
    $c->detach('/end');
}

=head2 default

404

=cut

sub default : Private {
    $_[1]->detach('/not_found');
}

=head2 exit

Exit for profiling tests

=cut

sub exit : Local {
    my ($self, $c) = @_;
    if ($ENV{ANGERWHALE_EXIT_OK}) {
        exit(0);
    }
    else {
        $c->stash( template => 'error.tt' );
        $c->res->status (403); # forbidden
    }
}

=head2 end

Global end action (except for L<Angerwhale::Model::Feeds>).  Renders
template and caches result if possible.

=cut

# global ending action
sub end : Private {
    my ( $self, $c ) = @_;

    return if $c->response->body;
    return if $c->response->redirect;
    return if 304 == $c->response->status; # no body
    
    if ( defined $c->config->{'html'} && 1 == $c->config->{'html'} ) {
        # work around mech's inability to handle "XML"
        $c->response->content_type('text/html; charset=utf-8');
    }
    else {
        $c->response->content_type('application/xhtml+xml; charset=utf-8');
    }
    return if ( 'HEAD' eq $c->request->method );
    
    $c->stash->{generated_at} = time();
    $c->forward('Angerwhale::View::HTML');
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
