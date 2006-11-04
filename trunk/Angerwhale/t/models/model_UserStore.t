#!/usr/bin/perl
# model_UserStore.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 19;
use ok 'Angerwhale::Model::UserStore';
use Test::MockObject;
use Directory::Scratch;
use File::Slurp qw(read_file write_file);
use YAML::Syck;

my $c = Test::MockObject->new;

my $tmp  = Directory::Scratch->new;
my $base = $tmp->mkdir('users'); 
my $config = { base => $base };
$c->set_always('config', $config);

my $JROCK_ID = 'd0197853dd25e42f'; # author's key ID;
my $id = pack 'H*', $JROCK_ID;

my $users = Angerwhale::Model::UserStore->new($c);
isa_ok($users, 'Angerwhale::Model::UserStore');

my $jrock;
eval {
    $jrock = $users->create_user_by_real_id($id);
};

ok(!$@, 'created jrock without throwing an exception');
isa_ok($jrock, 'Angerwhale::User');
is($jrock->fullname, "Jonathan T. Rockway");

my $jrock_real = $users->get_user_by_real_id($id);
is($jrock->fullname, $jrock_real->fullname, 'created user = returned user');

my $jrock_nice = $users->get_user_by_nice_id($JROCK_ID);
is($jrock->fullname, $jrock_nice->fullname, 'created user = returned (nice) user');

ok(-e "$base/.users/$JROCK_ID/", 'created jrock on disk');
ok(-e "$base/.users/$JROCK_ID/fullname", 'created jrock name');
ok(-e "$base/.users/$JROCK_ID/key", 'created jrock pubkey');
ok(-e "$base/.users/$JROCK_ID/email", 'created jrock email');
ok(-e "$base/.users/$JROCK_ID/fingerprint", 'created jrock fingerprint');
ok(-e "$base/.users/$JROCK_ID/last_updated", 'created last_updated');


ok(write_file("$base/.users/$JROCK_ID/fullname", 'Foo Bar'), 
   'changed fullname');

my $jrock_new  = $users->get_user_by_nice_id($JROCK_ID);
is($jrock_new->fullname, 'Foo Bar', "key has cached data");
is($jrock_new->nice_id, $JROCK_ID, 'cached nice_id is correct');
is($jrock_new->id, $id, 'cached real_id is correct');

# NOTE: this test is NOT y2k38 compliant!
ok(write_file("$base/.users/$JROCK_ID/last_updated", '0'), 'changed mtime');
$jrock_new = undef;
$jrock_new = $users->get_user_by_nice_id($JROCK_ID);
is($jrock_new->fullname, 'Jonathan T. Rockway', "key was refreshed");
