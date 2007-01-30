#!/usr/bin/perl
# follow_feed_links.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
use Test::WWW::Mechanize::Catalyst qw(Angerwhale);
use Test::More qw(no_plan);
use strict;
use warnings;
use Test::YAML::Valid qw(-Syck);

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/feeds');

my @links = $mech->followable_links();
while (my $link = shift @links) {
    my $url  = $link->url;
    if($url =~ m{/feeds/.*}){
	$mech->get_ok($link, "get $url");
	my $content = $mech->content;

	if($url =~ /yaml$/){
	    # YAML feed
	    is($mech->ct, 'text/x-yaml', 'content type is YAML');
	    
	  SKIP:
	    {
		skip "No content returned", 1 if !$content;
		yaml_string_ok($content, "no YAML errors on feed $url");
	    }
	}
	
	else {
	    # must be XML
	    like($mech->ct, qr{application/(rss|atom)[+]xml}, 
		 'content type is feedlike (rss|atom)+xml');
	    like($content, qr{^<[?]xml}, 'starts with an XML declaration');
	}
    }
}

END { die "TESTS DID NOT COMPLETE!!!!" if @links }
