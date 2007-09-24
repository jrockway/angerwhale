#!/usr/bin/env perl
# tag_cloud.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 40;
use strict;
use warnings;
use URI::Escape qw(uri_escape_utf8);
use Angerwhale::Test;
use File::Attributes qw(set_attribute);
use utf8;
use Encode;

my $mech = Angerwhale::Test->new;
my @words = qw|foo bar baz quux red orange yellow 日本語
                     green blue indigo violet things-i-like|;

word:
foreach my $word (@words){
    $mech->article(Encode::encode('utf-8', $word));
    my $file = $mech->tmp->exists($word);
    my $i = 1;
    
    foreach my $tag (@words) {
        set_attribute($file, "tags.$tag", 1);
    }
}

# sometimes tag cloud links link back to this page instead of the
# right page.  test all links to make sure they don't go here.
$mech->get_ok('http://localhost/tags');
my @links = $mech->followable_links();
my %seen; # each link should be seen 2x
foreach my $link (@links) {
    my $url  = $link->url;
    my $text = $link->text;
    
    if ( $url =~ m{/tags/} ) {
        utf8::decode($url);
        utf8::decode($text);

        my $should = uri_escape_utf8($text);
        $should = "http://localhost/tags/$should";
        is( $url, $should,
            Encode::encode('utf-8',"$text link is $should" ));
        $seen{$text}++;
    }
}

foreach my $word (@words) {
    is($seen{$word}, 2, 
       Encode::encode('utf-8', "$word seen twice"));
}
