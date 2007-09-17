use strict;
use warnings;
use Test::More tests => 1;

use Directory::Scratch;
use Angerwhale::UserStore;
use Angerwhale::User;

my $tmp = Directory::Scratch->new;

my $us = Angerwhale::UserStore->new(
    directory => "$tmp",
    class     => Angerwhale::User->meta,
);
ok $us;
