#!/usr/bin/perl
# model_UserStore.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 11;
use ok 'Blog::Model::UserStore';
use Test::MockObject;
use Directory::Scratch;

my $c = Test::MockObject->new;

my $tmp  = Directory::Scratch->new;
my $base = $tmp->mkdir('users'); 
my $config = { base => $base };
$c->set_always('config', $config);

my $JROCK_ID = 'd0197853dd25e42f'; # author's key ID;
my $id = pack 'H*', $JROCK_ID;

my $users = Blog::Model::UserStore->new($c);
isa_ok($users, 'Blog::Model::UserStore');

my $jrock;
eval {
    $jrock = $users->create_user_by_real_id($id);
};

ok(!$@, 'created jrock without throwing an exception');
isa_ok($jrock, 'Blog::User');
is($jrock->fullname, "Jonathan T. Rockway");

my $jrock_real = $users->get_user_by_real_id($id);
is($jrock->id, $jrock_real->id, 'created user = returned user');

my $jrock_nice = $users->get_user_by_nice_id($JROCK_ID);
is($jrock->id, $jrock_nice->id, 'created user = returned (nice) user');

ok(-e "$base/.users/$JROCK_ID/", 'created jrock on disk');
ok(-e "$base/.users/$JROCK_ID/fullname", 'created jrock name');
ok(-e "$base/.users/$JROCK_ID/key", 'created jrock pubkey');
ok(-e "$base/.users/$JROCK_ID/fingerprint", 'created jrock fingerprint');
