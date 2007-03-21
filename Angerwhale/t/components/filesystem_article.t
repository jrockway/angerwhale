#!/usr/bin/perl
# filesystem_article.t
# Copyright (c) 2007 Florian Ragwitz <rafl@debian.org>

use strict;
use warnings;
use Test::More tests => 13;
use Test::MockObject;
use Test::Exception;
use Directory::Scratch;
use File::Attributes qw(set_attribute);

use ok 'Angerwhale::ContentItem::Article';

my $tmp = Directory::Scratch->new;
my $c   = Test::MockObject->new;
$c->set_always( 'config', { encoding => 'utf8' } );

my $path =
  $tmp->touch( 'article.txt', "This is an article.", "I hope you like it." );

my $args = {
    location   => $path,
    base       => "$tmp",
    encoding   => 'utf8',
    filesystem => $c,
    userstore  => $c,
    cache      => $c
};
my $item = Angerwhale::ContentItem::Article->new($args);

ok( $item, 'created an item' );
is( $item->location, $path, 'location stuck' );
is( $item->base, "$tmp", 'base stuck' );
ok( !$item->parent, 'no parent' );

is( $item->title, 'article',     'correct title' );
is( $item->name,  'article.txt', 'correct filename' );
is( $item->type,  'txt',         'correct type' );
like( $item->raw_text, qr/is an article/, 'body is ok' );

ok( !$item->signed, 'no signature that I can see...' );

eval { set_attribute( $path, title => 'foo bar baz' ); };
ok( !$@, 'set attribute OK' );
is( $item->title, 'foo bar baz', 'title was read from attribute' );

dies_ok(sub {
		Angerwhale::ContentItem::Article->new({ %{$args}, parent => 1 })
}, 'articles cannot have a parent');
