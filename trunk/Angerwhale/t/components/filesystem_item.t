#!/usr/bin/perl
# filesystem_item.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 11;
use Test::MockObject;
use Directory::Scratch;

use ok 'Angerwhale::Model::Filesystem::Item';

my $tmp  = Directory::Scratch->new; 
my $c    = Test::MockObject->new;
$c->set_always('config', {encoding => 'utf8'});

my $path = $tmp->touch('article.txt', 
		       "This is an article.", "I hope you like it.");

my $args = { location => $path, base => "$tmp", context => $c };
my $item = Angerwhale::Model::Filesystem::Item->new($args);

ok($item, 'created an item');
is($item->context, $c, 'context stuck');
is($item->location, $path, 'location stuck');
is($item->base, "$tmp", 'base stuck');
ok(!$item->parent, 'no parent');

is($item->title, 'article', 'correct title');
is($item->name, 'article.txt', 'correct filename');
is($item->type, 'txt', 'correct type');
like($item->raw_text, qr/is an article/, 'body is ok');

ok(!$item->signed, 'no signature that I can see...');

