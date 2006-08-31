#!/usr/bin/perl
# signature.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests=>5;
use strict;
use warnings;
use ok qw(Angerwhale::Signature);
my $JROCK_ID = 'd0197853dd25e42f'; # author's key ID;
my $id = pack 'H*', $JROCK_ID;

# fake cat env.

my $data = do {local $/; <DATA>};

my $sig = Angerwhale::Signature->new($data);
### 

die FIXME;

isa_ok($sig, 'Angerwhale::Signature');

my $text = $sig->get_signed_data;

is($text, "This is a test PGP-signed message.\n", "Got the message text");
is($sig->get_key_id, $id, "Signature is by jrock");
ok($sig->verify, 'Signature verifies');

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
