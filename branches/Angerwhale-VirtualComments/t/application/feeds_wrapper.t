#!/usr/bin/perl
# feeds_wrapper.t
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 2;
use strict;
use warnings;

BEGIN {
    use Directory::Scratch;
    my $tmp = Directory::Scratch->new;
    my $base = $tmp->base;

    my $blog_title = "Unit Tests Are Fun - $$";
    my $blog_desc  = 'You should not be seeing this.';

    $tmp->mkdir('foo');
    $tmp->mkdir('bar');
    $tmp->mkdir('baz');

    $ENV{'ANGERWHALE_description'} = $blog_desc;
    $ENV{'ANGERWHALE_base'}        = $base;
    $ENV{'ANGERWHALE_title'}       = $blog_title;
    $ENV{'ANGERWHALE_html'}        = 1;
}

use Test::WWW::Mechanize::Catalyst qw(Angerwhale);
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/feeds/');

my @links =
  grep { $_->url =~ m{localhost/categories/} } $mech->followable_links();

is( scalar @links, 3, '3 categories' );
