#!/usr/bin/env perl
# follow_feed_links.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
use Test::More;
use strict;
use warnings;
use Test::YAML::Valid qw(-Syck);
use Test::JSON;
use Angerwhale::Test;

my $mech = Angerwhale::Test->new;
$mech->article("Article $_") for (1..20);
$mech->tmp->mkdir("category $_") for (1..2);
$mech->tmp->link("Article 1", "category 1/Article 1");
$mech->tmp->link("Article $_", "category 2/Article $_") for (1..15);

$mech->get('http://localhost/feeds');
# how many tests?
my @links = $mech->followable_links();
@links = grep { $_->url =~ m{/feeds/} } @links;
plan tests => 4 * @links + 1;

while ( my $link = shift @links ) {
    my $url = $link->url;
    $mech->get_ok( $link, "get $url" );
    my $content = $mech->content;

    $mech->content_like(qr/^.+$/s, 'feed is non-empty');
    
    if ( $url =~ /yaml$/ ) {
        # YAML feed
        is( $mech->ct, 'text/x-yaml', 'content type is YAML' );
        yaml_string_ok( $content, "no YAML errors on feed $url" );
    } 
    
    elsif ($url =~ /json$/ ) {
        # JSON feed
        is( $mech->ct, 'application/json', 'content type is JSON' );
        is_valid_json ( $content, "no JSON errors on feed $url" );
    } 
    else {
        # must be XML
        like(
             $mech->ct,
             qr{application/(rss|atom)[+]xml},
             'content type is feedlike (rss|atom)+xml'
            );
        like( $content, qr{^<[?]xml}, 'starts with an XML declaration' );
    }
}

END { is(scalar @links, 0, 'no more links left') }
