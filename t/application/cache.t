#!perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 29;
use Angerwhale::Test;
use Compress::Zlib ();
use Test::LongString;

# XXX: Test::WWW::Mechanize::Catalyst now decodes gzip...
# so tests 19, 11, 22, 24 are somewhat worthelss

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

$mech->get_ok('http://localhost/');
my $response = $mech->response;

is($response->code, 200, 'also OK');
is($response->header('ETag'), $et, 'same etag');
is($response->header('Last-Modified'), $lm, 'same mtime');
is_string($response->content, $content, 'same content');

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
lacks_string($mech->content, $content, "new page doesn't have old content");

# test gzip
$mech->delete_header('Accept-Encoding');
$mech->add_header( 'Accept-Encoding' => 'gzip' );
$mech->get_ok('http://localhost/');
my $zip = $mech->response->content;
is_string(uncompress($zip), $content, 'ungzipped content is correct');

# add an article and check response
$mech->article('foo bar baz yay');

$mech->add_header('Accept-Encoding' => 'gzip' );
$mech->add_header('If-None-Match' => $et);
$mech->add_header('If-Modified-Since' => $lm);
$mech->get_ok('http://localhost/');
my $new_content = uncompress($mech->response->content);
ok(length($new_content) > 0, 'new content is > 0');
lacks_string($new_content, $content, 'got new content');

$mech->delete_header('If-Modified-Since');
$mech->delete_header('If-None-Match');
$mech->delete_header('Accept-Encoding');
#$mech->add_header( 'Accept-Encoding' => 'identity' );
$mech->get_ok('http://localhost/');
is_string($mech->response->content, $new_content, 
          'getting non-gzipped content works');

# test to see that a HEAD's body doesn't get cached as the real body
$mech->article('away goes the cache, bye!');
my $res = $mech->head('http://localhost/');
is($res->code, 200, '200 ok for HEAD');
is($res->content, undef, 'no content');

$mech->get_ok('http://localhost');
$mech->content_like(qr/away goes the cache/, "didn't get `nothing'");
$mech->content_like(qr/foo bar baz/, "got older article too");


sub uncompress {
    return shift; # the uncompression auto-happens upstream now
}
