package Blog::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use URI;

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
	    $c->log->debug("got user $uid, ". $c->stash->{user}->fullname);
	};
	if ($@){
	    $c->log->debug("Failed to restore session $sid: $@");
	    $c->response->cookies->{sid} = {value   => q{},
					    expires => -1};

	}
    }
    $c->stash->{root} = $c->model('Filesystem');

    
    # not implemented yet, sort of
#     # update type information
#     my $uri = $c->request->uri->path;
#     if($uri =~ /(\/?)(.*)[.]([a-zA-Z]+)$/){
# 	my $slash = $1;
# 	my $path  = $2;
# 	my $type  = $3;
	
# 	# save the type
# 	$c->stash->{requested_type} = $type;

# 	# fix the URI
# 	my $uri = $c->request->uri->as_string;
# 	$uri =~ s{[.]$type}{};
	
# 	$c->request->{uri}  = URI->new($uri);

# 	# fix the path
# 	$c->request->{path} = $path;

# 	# fix the arguments
# 	#$path =~ m{/(.+)[.]$type};
# 	#$c->{request}->{arguments}->[-1] = "foo";

#     }


    return 1;
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

# global ending action

sub end : Private {
    my ($self, $c) = @_;

    # not implemented yet
    my $requested_type = $c->stash->{requested_type};
    
    #$c->forward('Blog::View::Dump');
    #print {*STDERR} $c->response->body;

    if(!($c->response->body || $c->response->redirect)){
	$c->response->content_type('text/html');    
	$c->forward('Blog::View::HTML');
    }
    
    return;
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
