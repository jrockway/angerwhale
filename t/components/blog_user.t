#!/usr/bin/env perl
# blog_user.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More;
use Angerwhale::User;
use strict;
use warnings;

#diag q{These tests will fail if you can't contact a keyserver.};
my $keyid = 'd0197853dd25e42f';    # key id of the author
my $key_fingerprint = '95ff88c5277c2282973fb90ad0197853dd25e42f';

my $realid = pack 'H*', $keyid;

my $jrock = eval { Angerwhale::User->_new($realid) };
if($@){
    plan skip_all => 'keyserver went bad';
}
else {
    plan tests => 7; 
}
isa_ok( $jrock, 'Angerwhale::User' );
is( $jrock->id,              $realid,          "keyids match" );
is( $jrock->nice_id,         $keyid,           "nice keyid matches" );
is( $jrock->key_fingerprint, $key_fingerprint, "fingerprint is correct" );
ok( $jrock->fullname =~ 'Rockway', "key is Jonathan T. Rockway's" );
ok( $jrock->email    =~ 'rock',    "key has one of jon's e-mails" );

SKIP: {
    skip "Photo support isn't implemented.", 1;
    ok( $jrock->photo );
}
