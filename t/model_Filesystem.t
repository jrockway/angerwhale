#!/usr/bin/perl
# model_Filesystem.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 8;
use Test::MockObject;
use Directory::Scratch;
use Blog::Model::Filesystem;
use YAML;

my $c = Test::MockObject->new;

my $config = {};
$c->set_always('config', $config);
$c->set_always('uri'   , 'test' ); 

my $tmp  = Directory::Scratch->new;
my $base = $tmp->mkdir('articles');
$config->{base} = $base;

$tmp->mkdir('articles/test category');

my $fs = Blog::Model::Filesystem->new($c);
isa_ok($fs, 'Blog::Model::Filesystem');

$tmp->touch('articles/An Article', "This is a test article.");
$tmp->touch('articles/Another Article.pod', <<"ARTICLE");

=head1 POD test

This is a test of the POD formatting engine, which should exist.

=head2 FOO

=head2 BAR

=head2 BAZ

=head1 OTHER NOTES

This is a good test of POD formatters, too, because while this I<looks>
like POD, it's actually a heredoc!  Confusing!

ARTICLE

my @categories = $fs->get_categories;
is(scalar @categories, 1, 'one category');
my $category = $categories[0];
is($category, 'test category', 'right name');

my @articles = sort $fs->get_articles;
is(scalar @articles, 2, "two articles");

my $article;
foreach my $a (@articles){
    $article = $a;
    last if $article->title =~ /Another/;
}

isa_ok($article, 'Blog::Model::Filesystem::Article');
is($article->title, 'Another Article', 'title is correct');
is($article->categories, (), 'not in any categories yet');
is($article->uri, 'articles/Another%20Article.pod');
