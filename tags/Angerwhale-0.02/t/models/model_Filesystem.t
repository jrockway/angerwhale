#!/usr/bin/perl
# model_Filesystem.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 19;
use Test::MockObject;
use Directory::Scratch;
use Angerwhale::Model::Filesystem;
use YAML::Syck;
use strict;
use warnings;

my $c = Test::MockObject->new;
my $cache = Test::MockObject->new;
my $config = {};
$c->set_always('config', $config);
$c->set_always('uri'   , 'test' ); 
$cache->set_always('get', undef);
$cache->set_always('set', undef);
$c->set_always('cache', $cache);

my $tmp  = Directory::Scratch->new;
my $base = $tmp->mkdir('articles');
$config->{base} = $base;

$tmp->mkdir('articles/test category');

my $fs = Angerwhale::Model::Filesystem->new($c);
isa_ok($fs, 'Angerwhale::Model::Filesystem');
$c->set_always('model', $fs);

$tmp->touch('articles/An Article', "This is a test article.");

my @lines = ("=pod\n",
	     "This is a test.  This is a test.\n",
	     "=head2 FOO\n",
	     "\n",
	     "This is a new paragraph.\n");
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

isa_ok($article, 'Angerwhale::Model::Filesystem::Article');
is($article->title, 'Another Article', 'title is correct');
is($article->categories, (), 'not in any categories yet');
is($article->uri, 'articles/Another Article.pod');
is($article->checksum, '63b08321fa7c7daf4c01eb86e5fdd231', "checksum is right");
is($article->name, 'Another Article.pod', 'name is correct');
is($article->type, 'pod', q{plain ol' documentation});
ok($article->id, 'article has a GUID');
ok($article->creation_time == $article->modification_time, 'crtime = mtime');
is($article->signed, undef, 'no digital signature');
ok($article->summary =~ /This is a test/, 'summary exists');
ok($article->text =~ /This is a new paragraph/, 'full text exists');
is($article->comment_count, 0, 'no comments yet');

eval {
    $article->add_comment('Test comment',
			  'This comments is a test comment.',
			  0, 'text');
};
ok(!$@, 'added a comment without triggering a FATAL ERROR!!!!!!! :)');
diag($@) if $@;

is($article->comment_count, 1, 'comment stuck');
