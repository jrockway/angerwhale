#!/usr/bin/env perl
# filesystem_item.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 10;
use Test::MockObject;
use Directory::Scratch;
use File::Attributes qw(set_attribute);

use ok 'Angerwhale::Content::Filesystem::Item';

my $tmp = Directory::Scratch->new;
my $c   = Test::MockObject->new;
$c->set_always( 'config', { encoding => 'utf8' } );

my $path =
  $tmp->touch( 'article.txt', "This is an article.", "I hope you like it." );

my $args = {file => $path,
            root => $tmp->base,
           };

my $item = Angerwhale::Content::Filesystem::Item->new($args);

ok( $item, 'created an item' );
is( $item->file, $path, 'location stuck' );
is( q{}. $item->root, "$tmp", 'base stuck' );
ok( !$item->parent, 'no parent' );

is( $item->metadata->{name},  'article.txt', 'correct filename' );
is( $item->metadata->{type},  'txt',         'correct type' );
like( $item->data, qr/is an article/, 'body is ok' );

eval { set_attribute( $path, title => 'foo bar baz' ); };
ok( !$@, 'set attribute OK' );

undef $item;
$item = Angerwhale::Content::Filesystem::Item->new($args);
is( $item->metadata->{title}, 'foo bar baz', 'title was read from attribute' );
