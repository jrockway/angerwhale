#!perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::YAML::Valid;

ok(-e 'angerwhale.yml');
yaml_file_ok('angerwhale.yml','angerwhale.yml validates');
