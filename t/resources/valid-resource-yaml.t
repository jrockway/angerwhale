#!perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::YAML::Valid;

ok(-e 'root/resources.yml');
yaml_file_ok('root/resources.yml','root/resources.yml validates');
