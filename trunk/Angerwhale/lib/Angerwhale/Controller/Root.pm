package Angerwhale::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use URI;
use HTTP::Date;
use Digest::MD5 qw(md5_hex);
use Encode;

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

Handle caching

=head2 default

global 404 page

=cut

sub auto : Private {
    my ($self, $c) = @_;
    $c->stash->{root} = $c->model('Filesystem');
    $c->stash->{user} = $c->session->{user};

    # conditions when we want to ignore the cache
    return 1 
      if keys %{$c->flash||{}} > 0;
    
    return 1
      if $c->request->uri->as_string =~ m{/login};
    
    return 1
      if $c->request->uri->as_string =~ m{/static/};

    return 1
      if 'GET' ne $c->request->method &&
	'HEAD' ne $c->request->method;
    
    # now we can deal with the cache
    # check to see if this page is cached
    my $key  = $c->model('Filesystem')->revision;
    $key .= ":". $c->request->uri->as_string;
    $key .= "@". $c->session->{user}->nice_id if $c->session->{user};
    
    $c->response->headers->header('ETag' => qq{"$key"});
    my $document;
    if( $document = $c->cache->get($key) ){

	$c->response->headers($document->{headers});
	$c->response->headers->header('Last-Modified' => 
				      time2str($document->{mtime}));
	
	# check for conditional requests
	my $cond_date = $c->req->header( 'If-Modified-Since' );
	my $cond_etag = $c->req->header( 'If-None-Match' );
	if( $cond_date || $cond_etag ) {
	    
	    # if both headers are present, both must match
	    my $do_send_304 = 1;
	    $do_send_304 = (str2time($cond_date) >= $document->{mtime})
	      if( $cond_date );
	    $do_send_304 &&= ($cond_etag eq qq{"$key"})
	      if( $cond_etag );
	    
	    if( $do_send_304 ) {
		no warnings 'uninitialized';
		$c->debug("304 not modified on ". $c->request->uri.
			  " etag:'$cond_etag' date:'$cond_date'");
		$c->res->status( 304 );
		$c->detach();
	    }
	}
	
	$c->debug("serving ". $c->request->uri ." from cache $key");
	$c->response->body($document->{body})
	  unless 'HEAD' eq $c->request->method;
	
	$c->detach();
    }
    
    $c->stash->{cache_key} = $key;
    return 1;
}
  
=head2 blog

Render the main blog page, and blog archives at
L<http://blog/yyyy/mm/dd>.

=cut

sub blog : Path('/') {
    my ( $self, $c, @date ) = @_;
    $c->stash->{page}     = 'home';
    $c->stash->{title}    = $c->config->{title} || 'Blog';
    $c->stash->{category} = '/';
    
    $c->forward('/categories/show_category', [@date]);
}

sub default : Private {
    my ($self, $c, @args) = @_;
    if(@args == 3){
	$c->forward('blog', [@args]);
    }
    else {
	$c->response->redirect($c->uri_for('/'));
    }
}

=head2 end

Global end action (except for L<Angerwhale::Model::Feeds>).  Renders
template and caches result if possible.

=cut


# global ending action
sub end : Private {
    my ($self, $c) = @_;
    
    #  not implemented yet
    # my $requested_type = $c->stash->{requested_type};
    
    #    if($c->debug){
    # 	my $res = $c->response->body;
    # 	$c->forward('Angerwhale::View::Dump');
    # 	print {*STDERR} $c->response->body;
    #    }

    return if $c->response->status != 200; # don't cache server errors

    if(!($c->response->body || $c->response->redirect)){

	if(defined $c->config->{'html'} && 1 == $c->config->{'html'}){
	    # work around mech's inability to handle "XML"
	    $c->response->content_type('text/html; charset=utf-8');
	}
	else {
	    $c->response->content_type('application/xhtml+xml; charset=utf-8');
	}
	return if('HEAD' eq $c->request->method);
	
 	$c->stash->{generated_at} = time();
 	my $articles = $c->stash->{articles};
 	my $article  = $c->stash->{article};

	if($c->stash->{cache_key}){
	    _cache($c, $c->stash->{cache_key});
	}
	else {
	    # not a page we know how to cache
	    $c->forward('Angerwhale::View::HTML');
	}
    }

    return;
}


sub _article_uniq_id {
    my $article = shift;
    # articles depend on:
    # tags
    # categories
    # contents (and mtime by association)
    # # of comments (to avoid traversing the entire comment tree)
    no warnings;
    return $article->comment_count.
      '|'. $article->checksum.
      '|'. $article->tags.
      '|'. $article->categories.
      '|'. $article->comment_count;
}

sub _cache {
    my $c   = shift;
    my $key = shift;
    my $document;
    $c->debug("caching $key");
    $c->forward('Angerwhale::View::HTML');
    $c->response->headers->header('ETag' => qq{"$key"});
    $document = { mtime   => time(),
		  headers => $c->response->headers,
		  body    => $c->response->body };

    $c->cache->set($key, $document);
    
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
