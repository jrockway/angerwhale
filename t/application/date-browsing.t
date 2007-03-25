#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 40;
use File::Attributes qw(set_attribute);
use Angerwhale::Test;

my $mech = Angerwhale::Test->new;
my $tmp  = $mech->tmp;

# prepare 15 posts, each posted one day apart
my $now = time();
for (1..15) {
    my $i = 16 - $_;
    my $title = "Article $i";
    $tmp->touch($title, "This is article $i.  "x100); # avoid mini posts
    my $filename = $tmp->exists($title);
    set_attribute($filename, 'creation_time', 
                  $now - (86_400 * ($_-1)));
}

$mech->get_ok('http://localhost/', 'get index page');

# first page is 15, 14, 13, 12, 11
$mech->content_contains("Article 15");
$mech->content_contains("Article 14");
$mech->content_contains("Article 13");
$mech->content_contains("Article 12");
$mech->content_contains("Article 11");
$mech->content_unlike(qr/Article 10/, 'no article 10 yet');
$mech->content_unlike(qr/Newer articles/, 'no newer posts');

# go to next page (10, ..., 6)
$mech->follow_link_ok({text_regex => qr/Older articles/}, 'get older posts (10-6)');
$mech->content_unlike(qr/Article 11/, 'no article 11 now');
$mech->content_contains("Article 10");
$mech->content_contains("Article 9");
$mech->content_contains("Article 8");
$mech->content_contains("Article 7");
$mech->content_contains("Article 6");
$mech->content_unlike(qr/Article 5/, 'no article 5 yet');

# go to next page
$mech->follow_link_ok({text_regex => qr/Older articles/}, 'get older posts (5-1)');
$mech->content_unlike(qr/Article 6/, 'no article 6 now');
$mech->content_contains("Article 5");
$mech->content_contains("Article 4");
$mech->content_contains("Article 3");
$mech->content_contains("Article 2");
$mech->content_contains("Article 1");
$mech->content_unlike(qr/Older articles/, 'no older posts');

# now go back up
$mech->follow_link_ok({text_regex => qr/Newer articles/}, 'get newer posts (10-6)');
$mech->content_unlike(qr/Article 11/, 'no article 11 yet');
$mech->content_contains("Article 10");
$mech->content_contains("Article 9");
$mech->content_contains("Article 8");
$mech->content_contains("Article 7");
$mech->content_contains("Article 6");
$mech->content_unlike(qr/Article 5/, 'no article 5 anymore');

# and back to the main page
$mech->follow_link_ok({text_regex => qr/Newer articles/}, 'get newer posts (10-6)');
$mech->content_contains("Article 15");
$mech->content_contains("Article 14");
$mech->content_contains("Article 13");
$mech->content_contains("Article 12");
$mech->content_contains("Article 11");
$mech->content_unlike(qr/Article 10/, 'no article 10 anymore');
$mech->content_unlike(qr/Newer articles/, 'no newer posts');
