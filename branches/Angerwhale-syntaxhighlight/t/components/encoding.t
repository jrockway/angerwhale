#!/usr/bin/perl
# encoding.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 15;
use Test::MockObject::Extends;
use Directory::Scratch;
use strict;
use warnings;
use utf8;
use Encode;
use File::Attributes qw(set_attribute);
use File::Attributes::Recursive qw(get_attribute_recursively);

use ok 'Angerwhale::Model::Filesystem::Item::Components::Encoding';

my $wide = '日本語';
my $tmp  = Directory::Scratch->new;
my $test = bless {}, 'Angerwhale::Model::Filesystem::Item::Components::Encoding'; 
$test = Test::MockObject::Extends->new($test);
$test->set_always('base', $tmp->base. q{});
$test->encoding('euc-jp');

ok(utf8::is_utf8($wide), '[sanity] is test string utf8'); #2

my $octets = Encode::encode('euc-jp', $wide);
my $octets_copy = "$octets";
ok(!utf8::is_utf8($octets), 'euc-jp is not utf8');

$test->from_encoding($octets);
isnt($octets, $octets_copy, 'conversion changed something?');
ok(utf8::is_utf8($octets), 'got utf8 back');
is($octets, $wide, 'got the right thing');

$test->to_encoding($octets);
is($octets, $octets_copy, 'conversion changed everything back');
ok(!utf8::is_utf8($octets), 'should not be unicode chars now'); 

my $foo = $tmp->mkdir('foo');
set_attribute($foo, 'encoding', 'iso-2022-jp');
$tmp->mkdir('foo/bar');
my $file = $tmp->touch('foo/bar/baz');
ok(-e $file, "foo/bar/baz exists as $file");

# foo has the encoding, but we're going to pass baz
my $encoding = get_attribute_recursively($file, "$tmp", 'encoding');  
is($encoding, 'iso-2022-jp', 'F::A::R works :)');

$octets = Encode::encode('iso-2022-jp', $wide);
$octets_copy = "$octets";

$test->from_encoding($octets, $file);
isnt($octets, $octets_copy, 'conversion changed something?');
ok(utf8::is_utf8($octets), 'got utf8 back');
is($octets, $wide, 'got the right thing');

$test->to_encoding($octets, $file);
is($octets, $octets_copy, 'conversion changed everything back');
ok(!utf8::is_utf8($octets), 'should not be unicode chars now');



