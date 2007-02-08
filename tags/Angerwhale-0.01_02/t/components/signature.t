#!/usr/bin/perl
# signature.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests=>4;
use strict;
use warnings;
use Test::MockObject::Extends;
use Test::MockObject;

# constants
my $JROCK_ID = 'd0197853dd25e42f'; # author's key ID;

# setup
my $id = pack 'H*', $JROCK_ID;
my $us = Test::MockObject->new; # fake UserStore
$us->set_always('keyserver', 'stinkfoot.org');

my $data = do {local $/; <DATA>};
my $sig = bless {}, 
  'Angerwhale::Model::Filesystem::Item::Components::Signature';
$sig = Test::MockObject::Extends->new($sig);
$sig->mock('raw_text', sub {if($_[1]){$data}else{" "}});

$sig->set_always('userstore', $us);
$sig->set_always('_cache_signature', 1);
$sig->set_always('_cached_signature', 0);
$sig->set_always('_fix_author', 1);

# tests
use ok qq[Angerwhale::Model::Filesystem::Item::Components::Signature];
my $text = $sig->_signed_text($data);
is($text, "This is a test PGP-signed message.\n", "Got the message text");
is($sig->signor, $id, "Signature is by jrock");
ok($sig->signed, 'Signature verifies');

__DATA__
-----BEGIN PGP MESSAGE-----
Version: GnuPG v1.4.3 (GNU/Linux)

owGbwMvMwMR4QbIi+K7qE33G05pJDC47l7qEZGQWKwBRokJJanGJQoB7gG5xZnpe
aopCbmpxcWJ6qh5XJ8NUZlaQYi+4bqb9XMz/lO6FH478eT9ctGaiW9xeHheVSxJx
L17eELE9vfRw3JeUd3xTV6ySl1lp5rA3Vy8n1MMmsvLODBlLlpbIF6p+30L0/oSY
Lv5ydmqj06o/2acTkp4t2mOyVCXpstwyVZv7HBO7VVZNm1Rlbrl2S4XCnk2Bzgm/
+1deOqNg8fea1Ovf2RaCuR77AQ==
=5Ck/
-----END PGP MESSAGE-----
