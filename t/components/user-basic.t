use strict;
use warnings;
use Test::More tests => 5;

use Test::Exception;
use Angerwhale::User;

lives_ok {
    Angerwhale::User->new( type => 'test',
                           id => 2, fullname => 'foo', 
                           email => 'jon@jrock.us' );
} 'basic user creation works';

{ package Some::User::Trait;
  use Moose::Role;
  sub foo { "42" };
}

my $u;
lives_ok {
    $u = Angerwhale::User->new( type => 'test',
                                id => 2, fullname => 'foo', email => 'jon@jrock.us',
                                traits => ['Some::User::Trait'] );
};

can_ok $u, 'foo';
is $u->foo, 42;
is $u->get_id, 'test:2';
