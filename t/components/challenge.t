#!/usr/bin/env perl
# challenge.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 10;
use ok 'Angerwhale::Challenge';
use YAML::Syck;
use strict;
use warnings;

my $challenge = new Angerwhale::Challenge( { uri => 'test://test' } );
ok( $challenge->{nonce} );
ok( $challenge->{date} );
is( $challenge->{uri}, 'test://test' );

my $copy = {
    nonce => $challenge->{nonce},
    uri   => $challenge->{uri},
    date  => $challenge->{date},
};
bless $copy => 'Angerwhale::Challenge';

is( $copy, $challenge, 'copy and challenge match' );
is( "$copy",      Dump($copy) );
is( "$challenge", Dump($challenge) );
is( "$copy",      "$challenge" );

$copy->{nonce} = "92384239847298374129834723487387";
isnt( $challenge->{nonce}, $copy->{nonce} );
isnt( $challenge, $copy );
