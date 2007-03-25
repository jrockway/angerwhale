#!/usr/bin/env perl
# login.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;

use Angerwhale::Challenge;
use Test::More tests => 6;
use YAML::Syck;
use Angerwhale::Test;
use URI::Escape;

BEGIN {

    sub get_data {
        return <<'NONCE', <<'SIGNED';
--- !!perl/hash:Angerwhale::Challenge
date: 1157434506
nonce: 238616936879130799031760863652778411418
uri: http://localhost:3000/
NONCE
-----BEGIN PGP MESSAGE-----
Version: GnuPG v1.4.5 (GNU/Linux)

owGbwMvMwMR4QbIi+K7qE33G0x1JDC5/efbq6uoqKCoWpBbl6GckFmdYOealpxaV
ZyTmpFpZOQOpnFSgAFdKYkmqlYKhoam5ibGJqYEZV15+XjJQxMjYwszQzNLYzMLc
0tDYwNzS0sDY0NzMwMLM2MzUyNzcwsTQ0MTQgqu0KNNKIaOkpMBKXz8nPzkxJyO/
uMTK2MDAQJ+rk2EqMyvILYfgjmPaPp/5f9U6WTU53j+r2kRqOSPeJAbzvt98/52F
NWvqjCjZObzX7zkv+Tt9098p3WUF7HKqN4VnqHXu976frn8yxs/0kMDchQ6FGV/W
9KgkmZ7n6+HZUifZ2/Rsl665z/THK47sPG8SF697+FFdh5OxguHhWeWXT/HzSP9O
31O3qSLue+mhiezMjeETAQ==
=iMfI
-----END PGP MESSAGE-----
SIGNED
    }
}

my ( $nonce, $signed );

BEGIN {
    ( $nonce, $signed ) = get_data();
    $nonce = Load($nonce);
    isa_ok( $nonce, 'Angerwhale::Challenge' );

    {
        no warnings 'redefine';
        *Angerwhale::Challenge::new = sub { $nonce };
    }
}

my $mech = Angerwhale::Test->new();
$signed = uri_escape($signed);

$mech->get_ok( 'http://localhost/login', 'can get login page' );
$mech->get_ok("/login/process?login=$signed");
$mech->content_unlike( qr/scum|forgot|couldn't read/, 'login successful' );
$mech->get_ok("/login/process?login=$signed");
$mech->content_like( qr/scum/, 'login UNsuccessful' );

