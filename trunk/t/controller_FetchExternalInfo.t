use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Blog' }
BEGIN { use_ok 'Blog::Controller::FetchExternalInfo' }

ok( request('/fetchexternalinfo')->is_success, 'Request should succeed' );


