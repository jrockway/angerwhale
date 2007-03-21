#!/usr/bin/perl
# strict.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use Test::Strict;
use Path::Class;
use strict;
use warnings;
use FindBin qw($Bin);

my $root = dir($Bin, '..', '..');
my @dirs = (dir($root, 'lib'), dir($root, 't'));
all_perl_files_ok(@dirs); # Syntax ok and use strict;
