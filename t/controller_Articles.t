use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok 'Catalyst::Test', 'Blog' }
BEGIN { use_ok 'Blog::Controller::Articles' }

ok( request('/')->is_success, 'Requesting /');
ok( request('/articles/')->is_success, 'Requesting /articles/');


