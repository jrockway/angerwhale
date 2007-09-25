#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 7;

use Apache::Htpasswd;
use Angerwhale::Authentication;
use Directory::Scratch;
use Test::Exception;

my $tmp = Directory::Scratch->new;
my $passwd = $tmp->touch('passwd', qw/foo:8txn5okZ5XqGg/); # foo => bar
my $config = { passwdFile => $passwd };
my $htpasswd = Angerwhale::Authentication->credential('htpasswd', $config);

can_ok $htpasswd, 'verify';

my $res;
lives_ok { $res = $htpasswd->verify({ username => 'foo', password => 'bar'}) }
  'verifying foo => bar lives';
is $res, 'htpasswd:foo', 'verification successful';

lives_ok { 
    $res = $htpasswd->verify({ username => 'NOT FOO', password => 'NOT BAR'})
} 'verifying foo => NOT BAR lives';
is $res, undef, 'verification failed';

# test invalid input

throws_ok { $htpasswd->verify({ username => 'foo' }) }
  qr/need password/, 'need password';
throws_ok { $htpasswd->verify({ password => 'bar' }) }
  qr/need username/, 'need username';
