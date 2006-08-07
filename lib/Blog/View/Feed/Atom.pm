#!/usr/bin/perl
# Atom.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
package Blog::View::Feed::Atom;

use strict;
use base qw(Blog::View::Feed);
use XML::Atom::SimpleFeed;

sub process {
    my ($self, $c) = @_;
    my @header;
    my $feed = XML::Atom::SimpleFeed->
      new(
	  title     => ($c->config->{title} || 'Blog'). ' Atom Feed',
	  id        => 'angerwhale:'. $c->req->base,
	  link      => $c->req->base,
	  subtitle  => $c->config->{description} || 'Atom Feed',
	  generator => {version => $c->config->{VERSION},
			name    => 'AngerWhale',
			uri     => 'http://www.jrock.us/'},
	 );
    
    foreach my $item ($self->prepare_items($c)){
	my @data;
	push @data, (title  => $item->{title});
	push @data, (author => $item->{author});
	push @data, (id => 'urn:guid:'. $item->{guid});
	push @data, (link => $item->{uri});
	eval {
	    foreach my $category (@{$item->{categories}}){
		push @data, (category => 
			     {term   => $category,
			      scheme => $c->uri_for('/categories/')});
	    }
	};
	push @data, (updated   => $item->{modified});
	push @data, (content => { type => 'xhtml',
				  content => $item->{xhtml}});
	$feed->add_entry(@data);
    }
    
    $c->response->content_type('application/atom+xml');    
    my $output = $feed->as_string;
    $c->response->body($output);
    return $output;
}

sub stash_rss_header {
    my ($self, $c) = @_;
    

    return;
}

1;

__END__
