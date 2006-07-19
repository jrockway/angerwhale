#!/usr/bin/perl
# preview_comment.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 22;
use Test::MockObject;
use ok 'Blog::Model::Filesystem::PreviewComment';
use Blog::User;

my $user_store = Test::MockObject->new;use ok qw(Blog::Signature);
my $JROCK_ID = 'd0197853dd25e42f'; # author's key ID;
my $id = pack 'H*', $JROCK_ID;
my $jrock = Blog::User->new($id);
$user_store->set_always('get_user_by_real_id', $jrock);
my $c = Test::MockObject->new;
$c->set_always('stash', {});
$c->set_always('model', $user_store);
my $body;
{
    local $/;
    $body = <DATA>;
}

my $comment = Blog::Model::Filesystem::PreviewComment
  ->new($c, 'test', $body, 'text');
isa_ok($comment, 'Blog::Model::Filesystem::PreviewComment');
is($comment->type, 'text');
ok($comment->creation_time);
ok($comment->modification_time);
is($comment->raw_text, 'This is a test.');
is($comment->raw_text(1), $body);
is($comment->title, 'test');
ok(!$comment->uri);
ok($comment->signed);
is($comment->author->fullname, 'Jonathan T. Rockway');
is($comment->signor, $id);
is($comment->checksum, undef);
is($comment->id, '??');
ok($comment->summary =~ /This is a test./);
ok(!$comment->post_uri);
ok(!$comment->add_comment('foo', 'bar', 'baz'));
ok(!$comment->set_tag('foo'));
ok(!$comment->tags);
is($comment->tag_count, 0);
is($comment->name, undef);

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
