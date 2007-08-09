#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 3;

use Angerwhale::Content::Item;

my $item = Angerwhale::Content::Item->new({metadata => {}});
$item->_add_tag(fOO => 5);
$item->_add_tag(FOO => 2);

is($item->metadata->{tags}{foo}, 7, '7 foo tags');
is($item->metadata->{tags}{fOO}, undef, '0 fOO tags');
is($item->metadata->{tags}{FOO}, undef, '0 FOO tags');
