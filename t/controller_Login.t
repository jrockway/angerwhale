use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Blog' }
BEGIN { use_ok 'Blog::Controller::Login' }

ok( request('/login')->is_success, 'Request should succeed' );


