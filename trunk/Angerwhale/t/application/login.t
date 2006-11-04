#!/usr/bin/perl
# login.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Catalyst::Test qw(Angerwhale);
use strict;
use warnings;
use Test::More tests => 15;
use YAML::Syck;
use Angerwhale;
use URI::Escape;

my ($nonce, $signed) = get_data();
$nonce = Load($nonce);
isa_ok($nonce, 'Angerwhale::Challenge');

my $ns = Angerwhale->model('NonceStore');
my $noncefile = $ns->sessions. '/pending/'. $nonce->{nonce};
ok(!-e $noncefile);

# unlink the noncefile so that the nonce doesn't contaiminate the
# user's real nonce store (allowing anyone to log in as me!)
END {
    no warnings 'uninitialized';
    unlink $noncefile;
    die "SECURITY ALERT: test nonce remains!" if -e $noncefile;
}

# tests begin
# first store the bundled nonce
ok((open my $nf, '>', $noncefile), 'open a noncefile');
ok(print {$nf} $nonce);
ok(close $nf);

$signed = uri_escape($signed);
ok(get('/login'), 'can get login page');
ok(my $result = get("/login/process?login=$signed"));
unlike($result, qr/scum|forgot/, 'login successful');
ok(!-e $noncefile, 'nonce went away');

# try to fail also!
ok((open my $nf, '>', $noncefile), 'open a noncefile');
$nonce->{date} = 'foo bar baz';
ok(print {$nf} $nonce);
ok(close $nf);
ok(my $result = get("/login/process?login=$signed"));
like($result, qr/scum/, 'login UNsuccessful');
ok(!-e $noncefile, 'nonce went away');




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
