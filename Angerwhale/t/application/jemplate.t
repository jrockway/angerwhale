#!perl

use strict;
use warnings;
use Angerwhale::Test;
use Test::More tests => 5;

my $mech = Angerwhale::Test->new;

$mech->get_ok('http://localhost/jemplate/logged_in_as.tt');
$mech->content_like(qr'Ingy');
$mech->get_ok('http://localhost/jemplate/sidebar_feed.tt');
$mech->content_like(qr'Ingy');
$mech->get('http://localhost/jemplate/this_does_not_exist.tt');
is($mech->status, 404, "can't get template that doesn't exist");
