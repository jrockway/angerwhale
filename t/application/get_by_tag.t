#!/usr/bin/env perl
# get_by_tag.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use Test::More;
use strict;
use warnings;
use Angerwhale::Test;
use Angerwhale::Test::Application;

local $SIG{__WARN__} = sub {}; # blah blah blah

my $mech = Angerwhale::Test->new;
$mech->article('This is a test article');

my $ok = eval {
    $mech->get('http://localhost/');
};
plan 'skip_all' => 'TT is broken' if !$ok;
plan tests => 26;

my $articles = model('Articles', 
                     {args => { storage_class => 'Filesystem',
                                storage_args  => { root => $mech->tmp->base }}});

my $article = $articles->get_article('This is a test article');

ok($article, 'got article');
is($article->title, 'This is a test article', 'title is test');

# singular and list
$article->add_tag('footag');
$article->add_tag('bartag', 'tagtag');

# sidebar
$mech->get_ok('http://localhost/tags');
$mech->content_contains('footag');
$mech->content_contains('bartag');
$mech->content_contains('tagtag');
$mech->content_unlike(qr/\bfaketag\b/);

# tag cloud (XXX: has sidebar too!)
$mech->get_ok('http://localhost/tags');
$mech->content_contains('footag');
$mech->content_contains('bartag');
$mech->content_contains('tagtag');
$mech->content_unlike(qr/\bfaketag\b/);

# check for article on tag page
$mech->get_ok('http://localhost/tags/footag');
$mech->content_contains('This is a test article');
$mech->get_ok('http://localhost/tags/bartag');
$mech->content_contains('This is a test article');
$mech->get_ok('http://localhost/tags/tagtag');
$mech->content_contains('This is a test article');
$mech->get_ok('http://localhost/tags/faketag');
$mech->content_unlike(qr'This is a test article');

# now try compound page
$mech->get_ok('http://localhost/tags/footag/bartag');
$mech->content_contains('footag and bartag');
$mech->content_contains('This is a test article');

$mech->get_ok('http://localhost/tags/footag/bartag/faketag');
$mech->content_contains('footag, bartag, and faketag');
$mech->content_unlike(qr'This is a test article');
