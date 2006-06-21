package Blog::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Blog::Controller::Root - Root Controller for this Catalyst based application

=head1 SYNOPSIS

See L<Blog>.

=head1 DESCRIPTION

Root Controller for this Catalyst based application.

=head1 METHODS

=cut

=head2 default

=cut

sub auto : Private {
    my ($self, $c) = @_;

    my $sid = $c->request->cookie("sid");
    if(defined $sid){
	eval {
	    $sid = $sid->value;
	    $c->log->debug("got session cookie $sid");
	    my $uid = $c->model('NonceStore')->unstore_session($sid);
	    $c->stash->{user} = $c->model("UserStore")->
	      get_user_by_nice_id($uid);
	    $c->log->debug("got user $uid, ". $c->stash->{user}->nice_id);
	};
	if ($@){
	    $c->log->debug("Failed to restore session $sid: $@");
	}
    }
    $c->stash->{root} = $c->model('Filesystem');
}

sub blog : Path('') {
    my ( $self, $c ) = @_;
    
    $c->stash->{page}     = "home";
    $c->stash->{title}    = "Blog";
    $c->stash->{category} = "/";
    $c->forward("/categories/show_category");
}

sub default : Private {
    my ($self, $c) = @_;
    $c->response->redirect('/');
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
