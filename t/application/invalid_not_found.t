#!/usr/bin/env perl
# errors.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Angerwhale::Test;
use Test::More tests => 10;

my $mech = Angerwhale::Test->new;
$mech->article({title => 'test', body => 'this is a test'});
$mech->get_ok('http://localhost/articles/test', 'get article');
$mech->get_ok('http://localhost/articles/test', 'get article raw');

$mech->get('http://localhost/comments/made/up/name');
is($mech->status, 404, 'comments/made/up/name not found');

$mech->get('http://localhost/articles/foobarbaz');
is($mech->status, 404, 'articles/foobarbaz not found');

$mech->get('http://localhost/articles/foobarbaz/raw');
is($mech->status, 404, 'articles/foobarbaz/raw not found');

$mech->get('http://localhost/articles/foo/bar/baz');
is($mech->status, 404, 'articles/foo/bar/baz not found');

$mech->get('http://localhost/articles/foo/bar/baz/raw');
is($mech->status, 404, 'articles/foo/bar/baz/raw not found');

$mech->get('http://localhost/1234/56/78');
is($mech->status, 404, '1234/56/78 not a valid date');

$mech->get('http://localhost/categories/fake');
is($mech->status, 404, 'no fake category');

$mech->get('http://localhost/categories/foo/bar/baz');
is($mech->status, 404, 'no foo/bar/baz category');

