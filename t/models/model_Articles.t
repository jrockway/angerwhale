#!perl
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 25;
use Test::MockObject;
use Test::Exception;
use Directory::Scratch;
use Angerwhale::Model::Articles;
use Angerwhale::Test::Application;
use YAML::Syck qw(LoadFile);
use strict;
use warnings;

my $cache = Test::MockObject->new;
my $log   = Test::MockObject->new;
my $tmp   = Directory::Scratch->new;
my $c     = Angerwhale::Test::Application::context();
my $config    = { base => $tmp->mkdir('articles'),
                  %{$c->config||{}} # resource file, etc.
                };
$c->set_always( 'config',  $config );
$c->set_always( 'uri',     'test' );
$c->mock( 'uri_for', sub { my $a = $_[1]; $a =~ s{^/}{}; $a} );
$cache->set_always( 'get', undef );
$cache->set_always( 'set', undef );
$log->set_always('debug', undef);
$c->set_always( 'cache',   $cache );
$c->set_always( 'log', $log);

$tmp->mkdir('articles/test category');
my $fs = Angerwhale::Model::Articles->COMPONENT($c, {});
isa_ok( $fs, 'Angerwhale::Model::Articles' );
$c->set_always( 'model', $fs );

$tmp->touch( 'articles/An Article', "This is a test article." );

my @lines = (
    "=pod\n", "This is a test.  This is a test.\n",
    "=head2 FOO\n", "\n", "This is a new paragraph.\n"
);
$tmp->touch( 'articles/Another Article.pod', @lines );

my @categories = $fs->get_categories;
is( scalar @categories, 1, 'one category' );
my $category = $categories[0];
is( $category, 'test category', 'right name' );

my @articles = sort $fs->get_articles;
is( scalar @articles, 2, "two articles" );

my $article;
foreach my $a (@articles) {
    $article = $a;
    last if $article->title =~ /Another/;
}

isa_ok( $article, 'Angerwhale::Content::Article' );
is( $article->title, 'Another Article', 'title is correct' );
is( scalar $article->categories, 0, 'not in any categories yet' );
is( $article->uri, 'articles/Another%20Article.pod', 'uri is correct' );
is(
   $article->checksum,
   '63b08321fa7c7daf4c01eb86e5fdd231',
   "checksum is right"
  );
is( $article->name, 'Another Article.pod', 'name is correct' );
is( $article->type, 'pod', q{plain ol' documentation} );
my $id;
ok( $id = $article->id, 'article has a GUID' );
ok( $article->creation_time == $article->modification_time, 'crtime = mtime' );
is( $article->signed, undef, 'no digital signature' );
ok( $article->summary =~ /This is a test/,          'summary exists' );
ok( $article->text    =~ /This is a new paragraph/, 'full text exists' );
is( $article->comment_count, 0, 'no comments yet' );

lives_ok (sub {
        $article->add_comment( 'Test comment', 'This comments is a test comment.',
            0, 'text' );
}, 'added a comment without triggering a FATAL ERROR!!!!!!! :)' );


$article = $fs->get_article('Another Article.pod');
is( $article->id, $id, 'copy of article has same GUID' );

is( $article->comment_count, 1, 'comment number is correct' );
is( scalar @{$article->children||[]}, 1, 'comment actually exists' );

dies_ok (sub {
        $article->add_comment( 'Test comment', '', 0, 'text' );
}, 'adding comment without body fails');

is( $article->comment_count, 1, 'post failed' );

dies_ok (sub {
        $article->add_comment( '', 'This comment is a test comment.', 0, 'text' );
}, 'adding comment without title fails');

is( $article->comment_count, 1, 'post failed' );
