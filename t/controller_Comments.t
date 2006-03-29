use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Blog' }
BEGIN { use_ok 'Blog::Controller::Comments' }

ok( !request('/comments')->is_success, 'Request should fail (listing comments of nonexistent article)' );


