#!perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 27;
use Angerwhale::Test;
use Compress::Zlib;

my $mech = Angerwhale::Test->new;
$mech->add_header( 'Accept-Encoding' => 'identity' );
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

sleep 1;
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
$mech->delete_header('Accept-Encoding');
$mech->add_header( 'Accept-Encoding' => 'gzip' );
$mech->get_ok('http://localhost/');
my $zip = $mech->response->content;
is(Compress::Zlib::memGunzip($zip), $content, 'ungzipped content is correct');

# add an article and check response
$mech->article('foo bar baz yay');

$mech->add_header('Accept-Encoding' => 'gzip' );
$mech->add_header('If-None-Match' => $et);
$mech->add_header('If-Modified-Since' => $lm);
$mech->get_ok('http://localhost/');
my $new_content = Compress::Zlib::memGunzip($mech->response->content);
isnt($new_content, $content, 'got new content');

$mech->delete_header('If-Modified-Since');
$mech->delete_header('If-None-Match');
$mech->delete_header('Accept-Encoding');
$mech->add_header( 'Accept-Encoding' => 'identity' );
$mech->get_ok('http://localhost/');
is($mech->content, $new_content, 'getting ungzipped content works');

# test to see that a HEAD's body doesn't get cached as the real body
$mech->article('away goes the cache, bye!');
my $res = $mech->head('http://localhost/');
is($res->code, 200, '200 ok for HEAD');
is($res->content, '', 'no content');

$mech->get_ok('http://localhost');
$mech->content_like(qr/away goes the cache/, "didn't get `nothing'");
