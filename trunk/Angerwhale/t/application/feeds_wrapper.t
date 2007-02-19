#!/usr/bin/perl
# feeds_wrapper.t
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 2;
use strict;
use warnings;
use Angerwhale::Test;

my $mech = Angerwhale::Test->new;
my $tmp = $mech->tmp;
$tmp->mkdir('foo');
$tmp->mkdir('bar');
$tmp->mkdir('baz');

$mech->get_ok('http://localhost/feeds/');

my @links =
  grep { $_->url =~ m{localhost/categories/} } $mech->followable_links();

is( scalar @links, 3, '3 categories' );
