#!perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 15;
use Angerwhale::Test;

my $mech = Angerwhale::Test->new;
$mech->article({title => 'This is a test', 
                body => 'Here is lots of content.'});

$mech->get_ok('http://localhost/');
my $initial_response = $mech->response;
is($initial_response->code, 200, 'status was 200 OK');

my $lm = $initial_response->header('Last-Modified');
ok($lm, 'got a last-modified header');

my $et = $initial_response->header('ETag');
ok($et, 'got an entitiy tag');

my $content = $initial_response->content;
like($content, qr/Here is lots of content/, 'content is sane');

sleep 2;
$mech->get_ok('http://localhost/');
my $response = $mech->response;

is($response->code, 200, 'also OK');
is($response->header('ETag'), $et, 'same etag');
is($response->header('Last-Modified'), $lm, 'same mtime');
is($response->content, $content, 'same content');

$mech->add_header('If-None-Match' => $et);
$mech->get_ok('http://localhost/');
is($mech->response->code, 304, '304 Not Modified (with etag)');
$mech->delete_header('If-None-Match');

$mech->add_header('If-Modified-Since' => $lm);
$mech->get_ok('http://localhost/');
is($mech->response->code, 304, '304 Not Modified (with mtime)');
$mech->delete_header('If-Modified-Since');

$mech->add_header('If-None-Match' => $et);
$mech->add_header('If-Modified-Since' => $lm);
is($mech->response->code, 304, '304 Not Modified (with both)');
$mech->delete_header('If-Modified-Since');
$mech->delete_header('If-None-Match');
