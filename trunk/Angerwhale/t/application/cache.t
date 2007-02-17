#!perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 19;
use Angerwhale::Test;
use Compress::Zlib;

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

# test 304 not modified
$mech->add_header('If-None-Match' => $et);
$mech->get('http://localhost/');
is($mech->response->code, 304, '304 Not Modified (with etag)');
$mech->delete_header('If-None-Match');

$mech->add_header('If-Modified-Since' => $lm);
$mech->get('http://localhost/');
is($mech->response->code, 304, '304 Not Modified (with mtime)');
$mech->delete_header('If-Modified-Since');

$mech->add_header('If-None-Match' => $et);
$mech->add_header('If-Modified-Since' => $lm);
$mech->get('http://localhost/');
is($mech->response->code, 304, '304 Not Modified (with both)');
$mech->delete_header('If-Modified-Since');
$mech->delete_header('If-None-Match');

$mech->add_header('If-None-Match' => "fake$et");
$mech->add_header('If-Modified-Since' => $lm);
$mech->get('http://localhost/');
is($mech->response->code, 200, '200 with bad etag');
$mech->delete_header('If-Modified-Since');
$mech->delete_header('If-None-Match');

$mech->add_header('If-None-Match' => $et);
$mech->add_header('If-Modified-Since' => "bad $lm");
$mech->get('http://localhost/');
is($mech->response->code, 200, '200 with bad mtime');
$mech->delete_header('If-Modified-Since');
$mech->delete_header('If-None-Match');

# test another page
$mech->get_ok('http://localhost/articles/');
isnt($mech->content, $content, "new page doesn't have old content");

# test gzip
$mech->add_header( 'Accept-Encoding' => 'gzip' );
$mech->get_ok('http://localhost/');
my $zip = $mech->content;
is(Compress::Zlib::memGunzip($zip), $content, 'ungzipped content is correct');
