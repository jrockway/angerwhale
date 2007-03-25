#!/usr/bin/env perl
# encoding.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 12;
use Directory::Scratch;
use strict;
use warnings;
use utf8;
use Encode;
use File::Attributes qw(set_attribute);
use File::Attributes::Recursive qw(get_attribute_recursively);
use Angerwhale::Test::Application;

my $tmp  = Directory::Scratch->new;
my $articles = model('Articles',
                     { args => { storage_class => 'Filesystem',
                                 storage_args  => { root => $tmp->base }}});

my $wide = '日本語';

# start by testing various non-unicode charsets
# preview comment first
ok( utf8::is_utf8($wide), '[sanity] is test string utf8' );
my $octets = Encode::encode( 'euc-jp', $wide );
my $octets_copy = "$octets";
ok( !utf8::is_utf8($octets), 'euc-jp is not utf8' );
my $test = $articles->preview(title    => 'test', 
                              type     => 'text',
                              body     => $octets, # use the euc-jp octets 
                              encoding => 'euc-jp');

my $body = $test->plain_text;
ok( utf8::is_utf8($body), 'processed body is utf8');
isnt( $body, $octets_copy, 'conversion changed something?' );

## now try a file on the filesystem, with the encoding specified
## in a parent directory

undef $octets;
undef $octets_copy;
undef $test;
undef $body;

$octets = Encode::encode( 'iso-2022-jp', $wide );
$octets_copy = "$octets";
set_attribute( $tmp->base, 'encoding', 'iso-2022-jp' );
$tmp->touch('article', $octets);

my $encoding = get_attribute_recursively( $tmp->exists("article"), $tmp->base, 
                                          'encoding' );
is( $encoding, 'iso-2022-jp', 'F::A::R works' );

$test = $articles->get_article('article');
$body = $test->plain_text;
chomp($body);

isnt( $body, $octets_copy, 'conversion changed something?' );
ok( utf8::is_utf8($body), 'got utf8 back' );
is( $body, $wide, 'got the right thing' );

## finally, a utf8 preview comment
undef $octets;
undef $octets_copy;
undef $test;
undef $body;


$test = $articles->preview(title    =>  $wide, 
                           type     => 'text',
                           body     =>  $wide,
                           # LIE, this should be ignored!
                           encoding => 'us-ascii', 
                          );

my $title = $test->title;
$body = $test->plain_text;
chomp $body;

ok(utf8::is_utf8($title), 'title is utf8');
ok(utf8::is_utf8($body), 'body is utf8');
is($title, $wide, 'title is right');
is($body, $wide, 'body is right');

