#!/usr/bin/perl
# model_NonceStore.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 11;
use ok 'Blog::Model::NonceStore';
use Test::MockObject;
use Directory::Scratch;
use Blog::Challenge;

my $c = Test::MockObject->new;

my $tmp  = Directory::Scratch->new;
my $base = $tmp->mkdir; 
my $config = { base => $base, session_expire => 1, nonce_expire => 1 };
$c->set_always('config', $config);

my $ns = Blog::Model::NonceStore->new($c);
isa_ok($ns, 'Blog::Model::NonceStore');

my $challenge = Blog::Challenge->new({uri => 'test://test'});
my $nonce = $ns->new_nonce($challenge);

ok($ns->verify_nonce($challenge),  'verify works');
ok(!$ns->verify_nonce($challenge),q{verify doesn't work again});
ok(!$ns->verify_nonce($challenge),q{verify doesn't work again});
ok(!$ns->verify_nonce({nonce => '123'}), 'invalid nonce doesnt work');

$challenge = Blog::Challenge->new({uri => 'test://test'});
$nonce = $ns->new_nonce($challenge);
#diag('sleeping 2 seconds');
sleep 2;
$ns->clean_nonces;
ok(!$ns->verify_nonce($challenge), 'verify fails when nonce expires');

my $user = Blog::User::Anonymous->new;
my $sid  = $ns->store_session($user);
ok($sid, 'got a session id');
my $uid  = $ns->unstore_session($sid);
is($uid, 0, 'got anonymous coward back');

eval {
    my $fake = $ns->unstore_session('not a session ID');
};
ok($@, 'unstoring fake session fails');

#diag('sleeping 2 seconds');
sleep 2;

$ns->clean_sessions();

eval {
    $uid  = $ns->unstore_session($sid);
};
ok($@, 'unstoring expired session fails');
