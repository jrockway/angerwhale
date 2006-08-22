use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Angerwhale' }
BEGIN { use_ok 'Angerwhale::Controller::FetchExternalInfo' }

ok( request('/fetchexternalinfo')->is_success, 'Request should succeed' );


