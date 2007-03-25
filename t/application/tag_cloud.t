#!/usr/bin/env perl
# tag_cloud.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 23;
use strict;
use warnings;
use URI;
use Angerwhale::Test;
use File::Attributes;

my $mech = Angerwhale::Test->new;
my @words = qw|foo bar baz quux red orange yellow 
                     green blue indigo violet|;

foreach my $word (@words){
    $mech->article($word);
    my $file = $mech->tmp->exists($word);
    my $i = 1;
    foreach my $tag (@words) {
        File::Attributes::set_attribute($file, "tags.$tag", int rand 10);
        last if rand() < 1/(15-$i++)
    }
}

# sometimes tag cloud links link back to this page instead of the
# right page.  test all links to make sure they don't go here.
$mech->get_ok('http://localhost/tags');
my @links = $mech->followable_links();

foreach my $link (@links) {
    my $url  = $link->url;
    my $text = $link->text;
    
    if ( $url =~ m{/tags/.*} ) {
        my $should = URI->new(qq{http://localhost/tags/$text});
        is( $url, $should->as_string, "$text link is $should" );
    }
}
