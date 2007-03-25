#!/usr/bin/env perl
# preview_comment.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 16;
use Test::MockObject;
use Test::Exception;
use Directory::Scratch;
use Angerwhale::User;
use Angerwhale::Model::Articles;
use Angerwhale::Test::Application;

my $tmp = Directory::Scratch->new;
# setup
my $JROCK_ID   = 'd0197853dd25e42f';            # author's key ID;
my $id         = pack 'H*', $JROCK_ID;
my $jrock      = Angerwhale::User->_new($id);


my $c = context({config => {}});

my $user_store = Test::MockObject->new;
$user_store->set_always( 'keyserver', 'stinkfoot.org' );
$user_store->set_always( 'get_user_by_real_id', $jrock );    
$c->set_always( 'model', $user_store ); # hack

my $articles = model('Articles', 
                     {context => $c,
                      args => { storage_class => 'Filesystem',
                                storage_args  => { root => $tmp->base }}});

my $body = do { local $/; <DATA> };
my $comment = $articles->preview(title => 'test', body => $body, type => 'text');
is( $comment->type, 'text', 'type is text' );
ok( $comment->creation_time,     'creation time is set' );
ok( $comment->modification_time, 'mod type is set' );
is( $comment->raw_text, 'This is a test.', 'raw_text is correct' );
is( $comment->raw_text(1), $body, 'body matches' );
is( $comment->title, 'test', 'title is correct' );
#ok( $comment->uri, 'no uri' );
ok( $comment->signed, 'signature exists' );
is( $comment->author->fullname, 'Jonathan T. Rockway', "I'm the author" );
is( $comment->signor, $id, 'uid exists' );
is( $comment->checksum, '25c5d6663226d4f18fa0c73c09758177',
#is( $comment->checksum, '120ea8a25e5d487bf68b5f7096440019', ## old
    'checksum matches' );
ok( $comment->id, 'has an id' );
like( $comment->summary, qr/This is a test./, 'summary contains correct text' );
dies_ok( sub {$comment->add_comment( 'foo', 'bar', 'baz' )}, 'add_comment fails' );
dies_ok( sub {$comment->add_tag('foo')}, 'tagging fails' );
ok( !$comment->tags, 'no tags' );
is( $comment->tag_count, 0, 'tag count = 0' );

__DATA__
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

This is a test.
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.3 (GNU/Linux)

iQCVAwUBRLtW9tAZeFPdJeQvAQLfswQAxB/qXDP8X3fddBheZNNiI2jYG+zxY8kD
Y2oa55cFPQaD5hxtcWb0C7UpXHUB3C5ewQ/3Qrn4Y3AS17/K9aztzr9wlU96TZ3z
HL3h0gOF/MVVJkq4kUX6hOVXnrIqKQg/Dh8zBylPkSkx4n4bF7nHTk2tTOdf94v6
nC1UCn0GzZ4=
=N3Ie
-----END PGP SIGNATURE-----
