#!/usr/bin/perl
# model_Filesystem.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 15;
use Test::MockObject;
use Directory::Scratch;
use Blog::Model::Filesystem;
use YAML;
use strict;
use warnings;

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

my @lines = ("=pod",
	     "This is a test.  This is a test.",
	     "=head2 FOO",
	     "",
	     "This is a new paragraph.");
$tmp->touch('articles/Another Article.pod',@lines);

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
diag $config->{base};

isa_ok($article, 'Blog::Model::Filesystem::Article');
is($article->title, 'Another Article', 'title is correct');
is($article->categories, (), 'not in any categories yet');
is($article->uri, 'articles/Another%20Article.pod');
is($article->checksum, '6e311f8f18ef958cdc7df6fd044defc8', "checksum is right");
is($article->name, 'Another Article.pod', 'name is correct');
is($article->type, 'pod', q{plain ol' documentation});
ok($article->id, 'article has a GUID');
ok($article->creation_time == $article->modification_time, 'crtime = mtime');
is($article->signed, undef, 'no digital signature');
die $article->summary;
ok($article->summary =~ /This is a test/, 'summary exists');
ok($article->text =~ /This is a new paragraph/, 'full text exists');
is($article->comment_count, 0, 'no comments yet');

eval {
    $article->add_comment('Test comment',
			  'This comments is a test comment.',
			  0, 'text');
};
ok(!$@, 'added a comment without triggering a FATAL ERROR!!!!!!! :)');

is($article->comment_count, 1, 'comment stuck');
