#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 7;

use Directory::Scratch;
use Angerwhale::Content::Provider::Filesystem;

my $tmp = Directory::Scratch->new;
my $articles = Angerwhale::Content::Provider::Filesystem->
  new({root => "$tmp"});

isa_ok($articles, 'Angerwhale::Content::Provider::Filesystem');

$tmp->mkdir('category1');
$tmp->mkdir('category2');
$tmp->mkdir('category3');

$tmp->touch('article1');
$tmp->touch('article2');
$tmp->touch('article3');

my $article1 = $articles->get_article('article1');
isa_ok($article1, 'Angerwhale::Content::Filesystem::Item');
is_deeply($article1->metadata->{categories}, [], 'not in any');

$tmp->link('article2' => 'category2/article2');
my $article2 = $articles->get_article('article2');
isa_ok($article2, 'Angerwhale::Content::Filesystem::Item');
is_deeply($article2->metadata->{categories}, ['category2'], 'in a category');


$tmp->link('article3' => "category$_/article3") for 1..3;
my $article3 = $articles->get_article('article3');
isa_ok($article3, 'Angerwhale::Content::Filesystem::Item');
my @categories = sort @{$article3->metadata->{categories}||[]};
is_deeply(\@categories, [sort map { "category$_" } 1..3], 'in all categories');
