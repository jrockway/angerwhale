#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use Angerwhale::Authentication;

my @credentials = Angerwhale::Authentication->credentials;
is_deeply [sort @credentials], [sort qw/htpasswd/], 'got all credentials';

my $htpasswd;
lives_ok 
  { $htpasswd = Angerwhale::Authentication->credential('htpasswd') }
  'getting htpasswd lives';
isa_ok $htpasswd, 'Angerwhale::Authentication::Credential::Htpasswd', 
  '$htpasswd';

dies_ok 
  { Angerwhale::Authentication->credential('foobarbaz no') }
  q"can't get the 'foobarbaz no' credential";

