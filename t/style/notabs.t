#!/usr/bin/env perl
# notabs.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::NoTabs;
use Path::Class;
use FindBin qw($Bin);

my $root = dir($Bin, '..', '..');
my @dirs = (dir($root, 'lib'), dir($root, 't'));

all_perl_files_ok(@dirs);
