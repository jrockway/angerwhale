#!/usr/bin/perl
# tag_cloud.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::WWW::Mechanize::Catalyst qw(Angerwhale);
use Test::More qw(no_plan);
use strict;
use warnings;
use URI;

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/tags');

# sometimes tag cloud links link back to this page instead of the
# right page.  test all links to make sure they don't go here.

my @links = $mech->followable_links();
foreach my $link (@links){
    my $url  = $link->url;
    my $text = $link->text;
    
    if($url =~ m{/tags/.*}){
	my $should = URI->new(qq{http://localhost/tags/$text});
	is($url, $should->as_string, "$text link is $should");
    }
}
